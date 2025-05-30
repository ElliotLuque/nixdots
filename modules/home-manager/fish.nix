{ host, ... }:
{
  programs.fish = {
    enable = true;
    generateCompletions = true;

    shellAliases = {
      gg = "lazygit";
      ls = "eza -lh --icons --group-directories-first";
      lsa = "eza -lah --icons --group-directories-first";
      tree = "eza --tree --icons --group-directories-first";
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      "....." = "cd ../../../..";
      vim = "nvim";
      cat = "bat -p";
      top = "btop";
      mkdir = "mkdir -p";
      system-rebuild = "sudo nixos-rebuild switch --flake ~/dotfiles/nixdots#${host} && notify-send \"NixOS Rebuild\" \"System rebuilt!\"";
      fm = "yazi";
    };

    plugins = [
      # { name = "sponge"; src = pkgs.fishPlugins.sponge.src; }
    ];

    shellInit = ''
      set fish_greeting
    '';

    interactiveShellInit = ''
      eval (ssh-agent -c) > /dev/null
      nitch
    '';
  };
}
