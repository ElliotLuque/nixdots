{
  description = "Personal AI and workstation infrastructure";

  inputs = {
    # composition
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    import-tree.url = "github:vic/import-tree";

    # core
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # desktop
    hyprland.url = "github:hyprwm/Hyprland/34eb03bd8da01024596c367fba66485a8c9b8ca7";

    hypr-dynamic-cursors = {
      # Keep the plugin API aligned with the pinned Hyprland revision.
      url = "github:VirtCode/hypr-dynamic-cursors/b9739b1db4a48616d66af29239ab0fe2756d28f6";
      inputs.hyprland.follows = "hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprsplit = {
      url = "github:shezdy/hyprsplit";
      inputs.hyprland.follows = "hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    veyl = {
      # Switch to github:ElliotLuque/veyl once the local Nix improvements are pushed.
      url = "path:/home/elliot/dev/veyl";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix.url = "github:danth/stylix";

    living-code = {
      url = "github:living-code-theme/palette";
      flake = false;
    };
    living-code-base16 = {
      url = "github:living-code-theme/base16";
      flake = false;
    };
    living-code-kitty = {
      url = "github:living-code-theme/kitty";
      flake = false;
    };
    living-code-bat = {
      url = "github:living-code-theme/bat";
      flake = false;
    };
    living-code-btop = {
      url = "github:living-code-theme/btop";
      flake = false;
    };
    living-code-fzf = {
      url = "github:living-code-theme/fzf";
      flake = false;
    };
    living-code-delta = {
      url = "github:living-code-theme/delta";
      flake = false;
    };
    living-code-hunk = {
      url = "github:living-code-theme/hunk";
      flake = false;
    };

    # applications
    spicetify-nix = {
      url = "github:Gerg-L/spicetify-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:ElliotLuque/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    herdr = {
      url = "github:herdrdev/herdr/v0.9.3";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.rust-overlay.follows = "rust-overlay";
    };

    # Herdr's older overlay uses deprecated stdenv platform attributes.
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    herdr-projects = {
      url = "github:eliasstravik/herdr-projects/v0.2.34";
      flake = false;
    };

    pi = {
      url = "github:earendil-works/pi/stable";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pi-anthropic-auth = {
      url = "github:gotgenes/pi-anthropic-auth/v3.4.2";
      flake = false;
    };

    pi-statusbar = {
      url = "github:elliotluque/pi-statusbar";
      flake = false;
    };

    # shared skill sources (configured by modules/ai/skills.nix)
    agent-skills.url = "github:Kyure-A/agent-skills-nix";
    taste-skill = {
      url = "github:Leonxlnx/taste-skill/v2.1.5";
      flake = false;
    };
    impeccable = {
      url = "github:pbakaus/impeccable";
      flake = false;
    };
    emil-skills = {
      url = "github:emilkowalski/skills";
      flake = false;
    };
    matt-skills = {
      url = "github:mattpocock/skills";
      flake = false;
    };
    remotion-skills = {
      url = "github:remotion-dev/skills";
      flake = false;
    };
    video-agent-skills = {
      url = "github:Melvynx/video-agent-skills";
      flake = false;
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.flake-parts.flakeModules.modules
        (inputs.import-tree [
          ./modules
          ./hosts
        ])
      ];
    };
}
