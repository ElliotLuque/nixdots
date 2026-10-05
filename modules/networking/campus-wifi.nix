{ config, ... }:
{
  # UPVNET is Wi-Fi, not a campus VPN. Select only on hosts that need it,
  # after provisioning the root-owned environment file and CA certificate.
  flake.modules.nixos.campus-wifi = { lib, ... }: {
    imports = [ config.flake.modules.nixos.network-manager ];
    networking.networkmanager.ensureProfiles = {
      environmentFiles = [ "/etc/nixdots/campus-wifi.env" ];
      profiles.UPVNET = {
        connection = {
          id = "UPVNET";
          type = "wifi";
          autoconnect = lib.mkDefault false;
        };
        wifi = {
          ssid = "UPVNET";
          mode = "infrastructure";
        };
        wifi-security.key-mgmt = "wpa-eap";
        "802-1x" = {
          eap = "peap";
          identity = "$CAMPUS_WIFI_IDENTITY";
          password = "$CAMPUS_WIFI_PASSWORD";
          ca-cert = "$CAMPUS_WIFI_CA_CERT";
          domain-suffix-match = "$CAMPUS_WIFI_RADIUS_DOMAIN";
          phase2-auth = "mschapv2";
        };
        ipv4.method = "auto";
        ipv6.method = "auto";
      };
    };
  };
}
