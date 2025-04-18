{ sops, ... }:
{
  sops = {
    age.keyFile = "/home/elliot/.config/sops/age/keys.txt";
    defaultSopsFile = ../../secrets/secrets.yaml;
    secrets."hyprpanel/weather_key" = {
      path = "%r/weather_key.txt";
    };
  };
}
