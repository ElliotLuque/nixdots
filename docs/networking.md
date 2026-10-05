# Scoped networking and access

Networking capabilities live in `modules/networking/`. Registering a feature does not enable it. Select features in the host or in a managed user's imports, rather than checking hostnames inside their implementation.

## Available features

| Feature | Scope | What it enables |
| --- | --- | --- |
| `network-manager` | NixOS | NetworkManager only; no private profiles or application firewall exceptions |
| `localsend` | NixOS | LocalSend package and its native TCP/UDP port 53317 policy |
| `campus-wifi` | NixOS | UPVNET Wi-Fi, NetworkManager, and runtime credential substitution |
| `mosh` | NixOS | Mosh client and server binaries, with UDP ports 60000–61000 open |
| `ssh-server` | NixOS | OpenSSH listener; authentication policy is a separate host decision |
| `ssh-client` | NixOS | SSH agent, without enabling an SSH listener |
| `ssh-client` | Home Manager | Generic SSH client settings; no personal destinations or keys |
| `proton-vpn` | Home Manager | Proton VPN GUI and graphical-session user unit |

The workstation role selects NetworkManager and the SSH client, not LocalSend, private networks, or an SSH server. Both current hosts explicitly select `localsend`, `ssh-server`, and `mosh`. Elliot explicitly selects the Proton VPN GUI on both current hosts. It is no longer launched from shared Hyprland Lua or installed by the generic desktop-apps bundle.

A VPS importing `base` and `ssh-server` does not receive campus access, Proton VPN, LocalSend, or NetworkManager. A new workstation importing only `workstation` does not receive them either, except for NetworkManager.

## Select features per host

Inside a host's NixOS module:

```nix
imports = with modules.nixos; [
  ./_hardware-configuration.nix
  workstation
  localsend
  ssh-server
  mosh
  # campus-wifi # only after provisioning its runtime configuration
];

home-manager.users.elliot.imports = [
  modules.homeManager.proton-vpn
];
```

Selecting the same feature on two hosts means adding the same import to their two host definitions. There is deliberately no host-group registry or application-to-host matrix to maintain.

LocalSend uses NixOS's existing module instead of duplicating its package and firewall implementation. For outbound-only use:

```nix
programs.localsend.openFirewall = false;
```

The package remains installed, but the feature no longer opens its receiving ports. NetworkManager by itself never opens them.

## Mosh

The `mosh` feature uses `programs.mosh.enable` to install both `mosh` and `mosh-server` and open UDP ports 60000–61000. Mosh starts a per-session server through SSH rather than running a persistent daemon; receiving hosts must also select `ssh-server` (as both current hosts do).

After rebuilding, connect with `mosh user@hostname`. The destination needs Mosh installed and its UDP ports reachable. For client-only use, keep the package but disable the firewall exception:

```nix
programs.mosh.openFirewall = false;
```

## Campus Wi-Fi

The existing UPVNET configuration is **Wi-Fi, not a VPN**. It previously contained placeholder credentials and a certificate reference that this repository did not provision.

`campus-wifi` is intentionally unselected on the current hosts until real runtime configuration is supplied. To use it:

1. Provision `/etc/nixdots/campus-wifi.env`, owned by root and readable only by root (mode `0600`). Keep it outside the repository.
2. Set these environment variables in that file:
   - `CAMPUS_WIFI_IDENTITY`: your campus identity.
   - `CAMPUS_WIFI_PASSWORD`: your password.
   - `CAMPUS_WIFI_CA_CERT`: absolute path to the campus-provided CA certificate.
   - `CAMPUS_WIFI_RADIUS_DOMAIN`: the expected authentication-server domain suffix, obtained from authoritative campus instructions.
3. Provision the CA certificate and verify the server-domain information. Do not disable certificate validation just to make authentication work.
4. Add `modules.nixos.campus-wifi` only to the intended hosts, then rebuild.

NetworkManager's native `ensureProfiles.environmentFiles` substitutes these values at runtime into private files under `/run/NetworkManager/system-connections`. Nix-generated configuration contains variable names, not resolved passwords. Do not replace the variable references with actual passwords in Nix code.

Automatic connection is off by default. Connect through the NetworkManager UI or `nmcli connection up UPVNET`. A selected host can enable automatic connection through the existing option:

```nix
networking.networkmanager.ensureProfiles.profiles.UPVNET.connection.autoconnect = true;
```

NetworkManager can retain removed runtime profiles until reboot, and profiles edited through its UI can become persistent. Removing an import stops declarative provisioning; inspect existing connections when retiring access from a previously configured machine.

## Personal SSH destinations

Put reusable client destinations in a named Home Manager feature, then import that feature only for users on hosts that should have them. For example, a future `modules/networking/ssh-personal.nix` could contain:

```nix
{ config, ... }:
{
  flake.modules.homeManager.ssh-personal = {
    imports = [ config.flake.modules.homeManager.ssh-client ];
    programs.ssh.settings.vps = {
      HostName = "YOUR_VPS_IP_OR_DNS";
      User = "admin";
      IdentityFile = "~/.ssh/id_ed25519";
      IdentitiesOnly = true;
    };
  };
}
```

A desktop and laptop could each select:

```nix
home-manager.users.elliot.imports = [ modules.homeManager.ssh-personal ];
```

The VPS itself does not need that client feature. Private keys remain runtime files; declaring an `IdentityFile` path does not put the key in the Nix store.

Importing `ssh-server` enables the listener, not hardened internet administration. For a VPS, configure authorized keys and administrative recovery first, then choose settings such as:

```nix
services.openssh.settings = {
  PasswordAuthentication = false;
  KbdInteractiveAuthentication = false;
  PermitRootLogin = "no";
};
```

Do not disable the only working login before testing the intended administrator account.

## Adding a VPN

Use the same composition pattern: create a provider-specific feature such as `campus-vpn`, implement it with the actual protocol's native NixOS options (`networking.wg-quick.interfaces`, `services.openvpn.servers`, or an appropriate NetworkManager VPN profile), and select it only in the intended hosts.

Campus VPN configuration is not fabricated here: it needs the provider's protocol, endpoint, routes, certificate requirements, and authentication method. A shared filename is useful; a generic VPN factory or hostname-switching implementation is not. Keep private keys/passwords in protected runtime files.

## Nix daemon access

The user module no longer changes daemon-wide access policy. NixOS's standard defaults apply:

- `allowed-users = [ "*" ]`: local users may use the daemon and build packages.
- `trusted-users = [ "root" ]`: additional daemon privileges remain restricted to root.

Allowed access is not trusted access. Do not make an agent account a trusted user just to let it run ordinary Nix builds.

A host that needs narrower access can use the native setting directly, for example:

```nix
nix.settings.allowed-users = [ "root" "@wheel" "agent-runner" ];
```

Adding an identity or SSH destination must not silently change this policy.

## Checks

`nix flake check` includes `networking-and-access`, which evaluates isolated feature combinations. It verifies that receiving ports belong to LocalSend, outbound-only LocalSend opens none, campus profiles do not appear in ordinary networking, SSH client/server selection stays separate, and Elliot's identity does not restrict other users' daemon access. It does not connect to a real campus network or VPN.
