usage() {
  echo 'Uso: sudo upv-vpn setup | connect PERFIL | disconnect | status'
  echo 'Perfiles: ALUMNO, ALUMNO-BIB, UPVNET, UPVNET-BIB'
}

command=${1:-help}
case "$command" in
  help|-h|--help) usage; exit 0 ;;
  setup|disconnect|status)
    [[ $# == 1 ]] || { usage >&2; exit 2; }
    ;;
  connect)
    [[ $# == 2 ]] || { usage >&2; exit 2; }
    case "$2" in
      ALUMNO|ALUMNO-BIB|UPVNET|UPVNET-BIB) ;;
      *) usage >&2; exit 2 ;;
    esac
    ;;
  *) usage >&2; exit 2 ;;
esac

if [[ $EUID != 0 ]]; then
  echo 'Ejecuta este comando con sudo.' >&2
  exit 1
fi

credentials=/etc/nixdots/upv-vpn.conf
case "$command" in
  setup)
    if systemctl is-active --quiet strongswan-swanctl; then
      echo 'Primero ejecuta: sudo upv-vpn disconnect' >&2
      exit 1
    fi
    read -r -p 'Usuario completo (usuario@alumno.upv.es o usuario@upvnet.upv.es): ' identity
    if [[ ! "$identity" =~ ^[a-zA-Z0-9._-]+@(alumno|upvnet)\.upv\.es$ ]]; then
      echo 'El usuario debe terminar en @alumno.upv.es o @upvnet.upv.es.' >&2
      exit 1
    fi
    read -r -s -p 'Contraseña UPV: ' password
    printf '\n'
    read -r -s -p 'Clave precompartida (PSK) de la intranet UPV: ' psk
    printf '\n'
    if [[ -z "$password" || -z "$psk" ]]; then
      echo 'La contraseña y la PSK no pueden estar vacías.' >&2
      exit 1
    fi

    # Hex is strongSwan's lossless secret encoding, NOT encryption. It avoids
    # configuration injection and handles quotes, backslashes and UTF-8 bytes.
    password_hex=$(printf '%s' "$password" | od -An -v -tx1 | tr -d ' \n')
    psk_hex=$(printf '%s' "$psk" | od -An -v -tx1 | tr -d ' \n')
    unset password psk
    umask 077
    install -d -m 0755 /etc/nixdots
    temporary=$(mktemp "${credentials}.XXXXXX")
    trap 'rm -f -- "$temporary"' EXIT
    {
      printf 'connections {\n'
      for profile in ALUMNO ALUMNO-BIB UPVNET UPVNET-BIB; do
        printf '  %s {\n    local-user {\n      eap_id = %s\n    }\n  }\n' "$profile" "$identity"
      done
      printf '}\nsecrets {\n'
      printf '  ike-upv {\n    secret = 0x%s\n' "$psk_hex"
      printf '    id-1 = ALUMNO\n    id-2 = ALUMNO-BIB\n    id-3 = UPVNET\n    id-4 = UPVNET-BIB\n  }\n'
      printf '  eap-upv {\n    id = %s\n    secret = 0x%s\n  }\n}\n' "$identity" "$password_hex"
    } > "$temporary"
    chmod 0600 "$temporary"
    mv -fT -- "$temporary" "$credentials"
    echo "Credenciales guardadas en $credentials (root, 0600)."
    if [[ "$identity" == *@alumno.upv.es ]]; then
      echo 'Conecta con: sudo upv-vpn connect ALUMNO (o ALUMNO-BIB para biblioteca).'
    else
      echo 'Conecta con: sudo upv-vpn connect UPVNET (o UPVNET-BIB para biblioteca).'
    fi
    ;;
  connect)
    if [[ ! -s "$credentials" ]]; then
      echo 'Primero ejecuta: sudo upv-vpn setup' >&2
      exit 1
    fi
    echo 'Aprueba la solicitud de doble factor en tu dispositivo cuando llegue.'
    # Restart to close any previous profile, restore DNS and reload credentials.
    # Only one tunnel should be active, as their traffic selectors overlap.
    systemctl restart strongswan-swanctl
    swanctl --initiate --ike "$2" --child "$2-net"
    ;;
  disconnect)
    systemctl stop strongswan-swanctl
    ;;
  status)
    if systemctl is-active --quiet strongswan-swanctl; then
      swanctl --list-sas
    else
      echo 'VPN UPV desconectada.'
    fi
    ;;
esac
