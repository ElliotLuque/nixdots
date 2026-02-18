{ ... }:
{
  xdg.configFile."JetBrains/IntelliJIdea2025.3/idea64.vmoptions" = {
    force = true;
    text = ''
      -Dawt.toolkit.name=WLToolkit
    '';
  };
}
