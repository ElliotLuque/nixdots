{ host, ... }:
{
  networking = {
    hostName = "${host}";
    networkManager.enable = true;
  };
}
