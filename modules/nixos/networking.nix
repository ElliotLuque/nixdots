{ host, ... }:
{
  networking = {
    hostName = "${host}";
    firewall = {
      allowedTCPPorts = [ 53317 ];
      allowedUDPPorts = [ 53317 ];
    };
    networkmanager = {
      enable = true;
      ensureProfiles.profiles = {
        "UPVNET" = {
          connection = {
            id = "UPVNET";
            type = "wifi";
          };

          wifi = {
            ssid = "UPVNET";
            mode = "infrastructure";
          };

          wifi-security = {
            key-mgmt = "wpa-eap";
          };

          "802-1x" = {
            eap = "peap"; # normalmente es peap
            identity = "tu_usuario";
            password = "tu_password";
            ca-cert = "/etc/ssl/wifi/radius2026.crt";
            phase2-auth = "mschapv2"; # lo más habitual
          };

          ipv4.method = "auto";
          ipv6.method = "auto";
        };
      };
    };
  };
}
