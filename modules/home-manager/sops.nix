{ lib, config, ... }:
{
  sops = {
    age.keyFile = "/home/elliot/.config/sops/age/keys.txt";
    defaultSopsFile = ../../secrets/secrets.yaml;
  };
}
