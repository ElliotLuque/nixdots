{ pkgs, anyrun, ... }:
{
  programs.anyrun = {
    enable = true;
    config = {
      x = {
        fraction = 0.5;
      };
      y = {
        fraction = 0.3;
      };
      width = {
        fraction = 0.3;
      };
      hideIcons = false;
      ignoreExclusiveZones = false;
      layer = "overlay";
      hidePluginInfo = true;
      closeOnClick = false;
      showResultsImmediately = false;
      maxEntries = null;

      plugins = [
        anyrun.packages.${pkgs.system}.applications
        anyrun.packages.${pkgs.system}.rink
        anyrun.packages.${pkgs.system}.translate
        anyrun.packages.${pkgs.system}.shell
        # An array of all the plugins you want, which either can be paths to the .so files, or their packages
        # inputs.anyrun.packages.${pkgs.system}.applications
        # ./some_plugin.so
        # "${inputs.anyrun.packages.${pkgs.system}.anyrun-with-all-plugins}/lib/kidex"
      ];
    };

    # Inline comments are supported for language injection into
    # multi-line strings with Treesitter! (Depends on your editor)

    extraCss = # css
      ''
              .some_class {
                background: red;
              }
        			window {
        				background: transparent;
        			}
      '';

    # extraConfigFiles."some-plugin.ron".text = ''
    #   Config(
    #     // for any other plugin
    #     // this file will be put in ~/.config/anyrun/some-plugin.ron
    #     // refer to docs of xdg.configFile for available options
    #   )
    # '';
  };
}
