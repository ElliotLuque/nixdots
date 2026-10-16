{ ... }:
{
  flake.modules.homeManager.fish = {
    xdg.configFile."fish/completions/oc.fish" = {
      force = true;
      text = ''
        complete -c oc -w opencode
      '';
    };
    xdg.configFile."fish/completions/system-rebuild.fish" = {
      force = true;
      text = ''
        complete -c system-rebuild -w "nh os switch"
      '';
    };
    xdg.configFile."fish/completions/system-test.fish" = {
      force = true;
      text = ''
        complete -c system-test -w "nh os test"
      '';
    };
    programs.fish = {
      enable = true;
      generateCompletions = true;
      shellAliases = {
        gg = "lazygit";
        oc = "opencode";
        pn = "pnpm";
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
        fm = "yazi";
        loc = "tokei";
      };
      functions = {
        # Switch from the main checkout (programs.nh.flake); extra args go to nh,
        # e.g. `system-rebuild --ask` or `system-rebuild -H nixos-laptop`.
        system-rebuild = ''
          nh os switch $argv
          or return
          set -q WAYLAND_DISPLAY; and notify-send "NixOS Rebuild" "System rebuilt!"; or true
        '';
        # Activate the current checkout/worktree without touching the boot default.
        system-test = ''
          set -l root (git rev-parse --show-toplevel 2>/dev/null)
          or begin
            echo "system-test: run inside a nixdots checkout/worktree"
            return 1
          end
          set -l branch (git -C $root branch --show-current)
          test -n "$branch"; or set branch (git -C $root rev-parse --short HEAD)
          set_color --bold; echo "system-test: $root ($branch)"; set_color normal
          # Git flakes ignore untracked files, so the build would silently miss them.
          set -l untracked (git -C $root ls-files --others --exclude-standard)
          if test (count $untracked) -gt 0
            set_color yellow
            echo "warning: "(count $untracked)" untracked file(s) are NOT part of this build (git add them):"
            printf '  %s\n' $untracked[1..10]
            test (count $untracked) -gt 10; and echo "  ..."
            set_color normal
          end
          nh os test $root $argv
          or return
          set_color green
          echo "Active (not boot default): $branch. Revert with `system-rebuild` or a reboot."
          set_color normal
          set -q WAYLAND_DISPLAY; and notify-send "NixOS Test" "Activated $branch (revert: system-rebuild/reboot)"; or true
        '';
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
        nitch
      '';
    };
  };
}
