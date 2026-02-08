{ pkgs, inputs, ... }:
{
  programs.spicetify =
    let
      spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
    in
    {
      enable = true;

      enabledExtensions = with spicePkgs.extensions; [
        loopyLoop
        hidePodcasts
      ];

      enabledCustomApps = with spicePkgs.apps; [
        reddit
        lyricsPlus
      ];

      enabledSnippets = with spicePkgs.snippets; [
        # rotatingCoverart
      ];

      theme = spicePkgs.themes.text;
      colorScheme = "CatppuccinMocha";
    };
}
