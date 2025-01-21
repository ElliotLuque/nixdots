{ ... }:
{
  programs.fish = {
    enable = true;
    generateCompletions = true;

    shellAliases = {
      gg = "lazygit";
      ls = "eza -lh --icons";
      lsa = "eza -lah --icons";
      tree = "eza --tree --icons";
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      vim = "nvim";
      cat = "bat";
      top = "btop";
      mkdir = "mkdir -p";
      home-rebuild = "home-manager switch --flake /etc/nixos#elliot";
      system-rebuild = "sudo nixos-rebuild switch --flake /etc/nixos#nixos-pc";
    };

    plugins = [
      # { name = "sponge"; src = pkgs.fishPlugins.sponge.src; }
    ];

    shellInitLast = ''
      set fish_greeting
      pfetch
    '';
  };
}
