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

    functions = {
      compress = ''
        if test (count $argv) -lt 2
          echo "Uso: compress <archivo.tar.gz|archivo.zip> <fichero/directorio...>"
          return 1
        end

        set -l archive $argv[1]
        set -l inputs $argv[2..-1]

        switch $archive
          case '*.tar.gz' '*.tgz'
            tar -czf "$archive" $inputs
          case '*.tar.bz2' '*.tbz2'
            tar -cjf "$archive" $inputs
          case '*.tar.xz' '*.txz'
            tar -cJf "$archive" $inputs
          case '*.zip'
            zip -r "$archive" $inputs
          case '*'
            echo "Formato no soportado: $archive"
            echo "Soportados: .tar.gz .tgz .tar.bz2 .tbz2 .tar.xz .txz .zip"
            return 1
        end
      '';

      extract = ''
        if test (count $argv) -ne 1
          echo "Uso: extract <archivo>"
          return 1
        end

        set -l archive $argv[1]
        if not test -f "$archive"
          echo "No existe el fichero: $archive"
          return 1
        end

        switch $archive
          case '*.tar.gz' '*.tgz'
            tar -xzf "$archive"
          case '*.tar.bz2' '*.tbz2'
            tar -xjf "$archive"
          case '*.tar.xz' '*.txz'
            tar -xJf "$archive"
          case '*.tar'
            tar -xf "$archive"
          case '*.zip'
            unzip "$archive"
          case '*.gz'
            gunzip "$archive"
          case '*.bz2'
            bunzip2 "$archive"
          case '*.xz'
            unxz "$archive"
          case '*'
            echo "Formato no soportado: $archive"
            return 1
        end
      '';

      bak = ''
        if test (count $argv) -ne 1
          echo "Uso: bak <fichero/directorio>"
          return 1
        end

        set -l target $argv[1]
        if not test -e "$target"
          echo "No existe: $target"
          return 1
        end

        set -l timestamp (date +"%Y%m%d-%H%M%S")
        set -l backup "$target.$timestamp.bak"
        set -l n 1

        while test -e "$backup"
          set backup "$target.$timestamp.$n.bak"
          set n (math $n + 1)
        end

        cp -a "$target" "$backup"
        and echo "Backup creado: $backup"
      '';

      copy = ''
        if test (count $argv) -ne 1
          echo "Uso: copy <fichero>"
          return 1
        end

        set -l file $argv[1]
        if not test -f "$file"
          echo "No existe el fichero: $file"
          return 1
        end

        if command -q wl-copy
          cat "$file" | wl-copy
        else if command -q xclip
          cat "$file" | xclip -selection clipboard
        else if command -q pbcopy
          cat "$file" | pbcopy
        else
          echo "No se encontro un comando de portapapeles (wl-copy, xclip, pbcopy)"
          return 1
        end

        and echo "Contenido copiado al portapapeles: $file"
      '';
    };

    shellInit = ''
      set fish_greeting
    '';

    interactiveShellInit = ''
      set -gx HISTSIZE 10000000
      set -gx SAVEHIST 10000000
      eval (ssh-agent -c) > /dev/null
      nitch
    '';
  };
}
