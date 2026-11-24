# VPN UPV en NixOS

Adaptación de la [guía oficial para Ubuntu 26.04 y Debian 13](https://wiki.upv.es/confluence/spaces/MANUALES/pages/1176470611/Linux+-+VPN+con+Ubuntu+26.04+y+Debian+13).

## Qué se configura

`modules/networking/campus-vpn.nix` registra la función `campus-vpn`, seleccionada **solo en `hosts/nixos-pc/default.nix`**. El portátil, la Wi-Fi UPVNET y Proton VPN no se modifican.

- strongSwan mediante `services.strongswan-swanctl`, con IKEv2, EAP-MSCHAPv2, autenticación del servidor mediante PSK, `vpn.upv.es`, AES-256/SHA-256/MODP-2048 y encapsulación UDP, igual que la guía.
- Cuatro perfiles precargados, sin conexión automática ni solicitudes de doble factor al arrancar o reconstruir el sistema.
- `systemd-resolved` integrado con NetworkManager. El hook configura los DNS UPV `158.42.1.118` y `158.42.1.128` en la interfaz de salida. En modo normal configura el dominio de enrutamiento `~upv.es`; en biblioteca, `~.`, para resolver también los dominios externos con los DNS UPV. Al desconectar se restaura la configuración DNS de NetworkManager, también si el demonio termina inesperadamente. Como en la guía, mientras está conectado se sustituye la configuración DNS de esa interfaz; no es un segundo perfil VPN de NetworkManager.
- Contraseña, PSK e identidad en `/etc/nixdots/upv-vpn.conf`, propiedad de root y modo `0600`. Solo se referencia su **ruta como cadena** desde Nix: el contenido nunca se lee durante la evaluación ni se copia al Nix store.
- El comando `upv-vpn` para configurar y gestionar el túnel desde el terminal.
- Sin abrir puertos de entrada ni desactivar el firewall: es un cliente que inicia la conexión y fuerza NAT-T.

La red `10.10.0.0/8` escrita en la guía se expresa como `10.0.0.0/8`, su forma canónica (la propia salida de ejemplo de la guía muestra esa red).

## Primera configuración

Necesitas conexión a Internet **fuera de la Wi-Fi UPVNET/eduroam del campus**, el doble factor UPV ya configurado y la clave precompartida que aparece en el [portal de autogestión de la intranet](https://intranet.upv.es/pls/soalu/sic_piolin.LanzarForm?p_id_form=722D4AF14F7C7D0B0F5952E389FB82B5).

1. Aplica la configuración desde este repositorio:

   ```bash
   sudo nixos-rebuild switch --flake .#nixos-pc
   ```

   También puedes usar `system-rebuild` desde Fish. No hace falta reiniciar. Este paso cambia el resolvedor DNS del equipo a systemd-resolved, pero no conecta la VPN.

2. Introduce las credenciales **en tu terminal, no en el chat ni en archivos del repositorio**:

   ```bash
   sudo upv-vpn setup
   ```

   Pide el usuario completo (`usuario@alumno.upv.es` o `usuario@upvnet.upv.es`), la contraseña UPV y la PSK de la intranet. Las dos contraseñas se introducen sin mostrarlas y no se pasan como argumentos de procesos ni se guardan en el historial. Para cambiar credenciales, desconecta y vuelve a ejecutar `setup`.

   Los secretos se escriben usando la codificación hexadecimal admitida por strongSwan, para conservar caracteres especiales sin problemas de escape. **No es cifrado**: protege el archivo y no lo compartas.

## Conectar

Elige según tu colectivo y el acceso que necesitas; tu cuenta normalmente solo tendrá permiso para dos de los cuatro perfiles:

| Perfil | Cuenta | Tráfico por la VPN |
| --- | --- | --- |
| `ALUMNO` | `@alumno.upv.es` | Redes UPV; recomendado |
| `ALUMNO-BIB` | `@alumno.upv.es` | Todo IPv4, para revistas y bases de datos de biblioteca |
| `UPVNET` | `@upvnet.upv.es` | Redes UPV; recomendado |
| `UPVNET-BIB` | `@upvnet.upv.es` | Todo IPv4, para biblioteca |

Por ejemplo, si eres alumno:

```bash
sudo upv-vpn connect ALUMNO
# Aprueba la solicitud de doble factor cuando llegue.
sudo upv-vpn status
sudo upv-vpn disconnect
```

Para biblioteca:

```bash
sudo upv-vpn connect ALUMNO-BIB
```

`connect` reinicia strongSwan para cerrar el perfil anterior y cargar las credenciales actuales antes de iniciar el nuevo. No intentes mantener varios de estos perfiles conectados a la vez: sus rutas se solapan. Cerrar el terminal no desconecta la VPN; usa `disconnect`. Evita iniciar perfiles directamente con swanctl mientras usas este comando.

**Desconecta antes Proton VPN y su kill switch**, si están activos. La aplicación puede seguir instalada; dos VPN simultáneas pueden interferir con rutas, DNS y acceso al servidor UPV.

### Límites y solapamientos

- La guía solo configura IPv4. Incluso los perfiles `-BIB` no tunelizan IPv6 ni incluyen un kill switch: son para acceso universitario, no una garantía de anonimato o de que todo el tráfico del equipo pase por la UPV.
- Los perfiles normales incluyen `158.42.0.0/16`, `10.0.0.0/8`, `172.16.0.0/12` y `192.168.0.0/16`. Estas redes pueden solaparse con tu LAN y con Docker. Si pierdes acceso a un recurso local, desconecta; no elimines rangos sin comprobar qué recursos UPV necesitas.
- No edites `/etc/swanctl/swanctl.conf`: lo genera NixOS. Las credenciales solo están en el include privado.

## Diagnóstico

```bash
sudo upv-vpn status
sudo swanctl --list-conns
sudo swanctl --list-sas
journalctl -b -u strongswan-swanctl --no-pager
resolvectl status
resolvectl query www.upv.es
ip route show table 220
sudo ip xfrm policy
```

Una conexión correcta aparece como `ESTABLISHED` con un CHILD_SA `INSTALLED`. Un servicio activo sin asociaciones no significa que estés conectado. Si falla la autenticación, comprueba identidad/dominio, contraseña, PSK, permisos del perfil y aprobación del doble factor; no publiques credenciales ni registros sin revisar.

La evaluación y los checks de Nix validan la composición, los perfiles, el aislamiento de secretos y los scripts. La autenticación real, las rutas y la restauración DNS deben comprobarse en el equipo después de reconstruir y proporcionar las credenciales.
