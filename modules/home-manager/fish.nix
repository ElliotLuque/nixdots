{ host, pkgs, ... }:
let
  fasterWhisperPython =
    (pkgs.python3.override {
      packageOverrides = final: prev: {
        ctranslate2 = prev.ctranslate2.override {
          ctranslate2-cpp = pkgs.ctranslate2.override {
            withCUDA = true;
            withCuDNN = true;
          };
        };
      };
    }).withPackages
      (
        ps: with ps; [
          faster-whisper
          ctranslate2
        ]
      );
in
{
  xdg.configFile."fish/completions/oc.fish" = {
    force = true;
    text = ''
      complete -c oc -w opencode
    '';
  };

  programs.fish = {
    enable = true;
    generateCompletions = true;

    shellAliases = {
      gg = "lazygit";
      oc = "opencode";
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

      clase_grabar = ''
        set -l modo system
        set -l args
        for arg in $argv
          switch $arg
            case --mic
              set modo mic
            case --system
              set modo system
            case '*'
              set -a args $arg
          end
        end

        set -l asignatura ""
        if test (count $args) -gt 0
          set asignatura (string join " " $args)
        else
          read -P "Asignatura: " asignatura
        end

        if test -z "$asignatura"
          echo "La asignatura no puede estar vacia"
          return 1
        end

        set -l slug (string upper -- (string replace -ra '[^[:alnum:]]+' '_' -- $asignatura))
        set slug (string trim -c '_' -- $slug)

        if test -z "$slug"
          echo "No se pudo generar un nombre valido"
          return 1
        end

        set -l fecha (date +"%d-%m-%y")
        set -l outdir "$HOME/Universidad/Clases/$slug"
        mkdir -p "$outdir"

        set -l audio "$outdir/$fecha.m4a"
        set -l n 1
        while test -e "$audio"
          set audio "$outdir/$fecha"_"$n.m4a"
          set n (math $n + 1)
        end

        set -l source default
        if command -q pactl
          if test "$modo" = system
            set -l sink (pactl get-default-sink 2>/dev/null)
            if test -n "$sink"
              set source "$sink.monitor"
            end
          else
            set -l mic (pactl get-default-source 2>/dev/null)
            if test -n "$mic"
              set source "$mic"
            end
          end
        end

        echo "Grabando clase en: $audio"
        echo "Fuente: $source ($modo)"
        echo "Pulsa Ctrl+C para terminar la grabacion"
        ffmpeg -hide_banner -loglevel warning -f pulse -i "$source" -ac 1 -ar 48000 -af "volume=0.8" -c:a aac -b:a 128k "$audio"
        set -l rc $status

        if test $rc -eq 130 -o $rc -eq 255
          if test -s "$audio"
            echo "Grabacion finalizada por usuario"
          else
            echo "Se interrumpio la grabacion y el archivo quedo vacio"
            return 1
          end
        else if test $rc -ne 0
          echo "Fallo la grabacion"
          return 1
        end

        echo "Audio guardado: $audio"
        echo "Transcribe con: clase_transcribir \"$audio\""
      '';

      clase_transcribir = ''
                if test (count $argv) -ne 1
                  echo "Uso: clase_transcribir <audio.m4a|audio.wav|...>"
                  return 1
                end

                set -l audio $argv[1]
                if not test -f "$audio"
                  echo "No existe el audio: $audio"
                  return 1
                end

                set -l stem (string replace -r '\\.[^.]+$' "" -- $audio)
                set -l txt "$stem.txt"
                set -l fw_model large-v3
                set -l fw_lang es
                set -l fw_compute float16
                set -l fw_device cuda
                set -l fw_python "${fasterWhisperPython}/bin/python3"
                set -l fw_log "$stem.faster-whisper.log"
                set -l fw_tmp_log "$fw_log.tmp"

                if set -q FASTER_WHISPER_MODEL
                  set fw_model "$FASTER_WHISPER_MODEL"
                end

                if set -q FASTER_WHISPER_LANG
                  set fw_lang "$FASTER_WHISPER_LANG"
                end

                if set -q FASTER_WHISPER_COMPUTE
                  set fw_compute "$FASTER_WHISPER_COMPUTE"
                end

                if set -q FASTER_WHISPER_DEVICE
                  set fw_device "$FASTER_WHISPER_DEVICE"
                end

                if not test -x "$fw_python"
                  echo "No se encontró Python declarativo para faster-whisper"
                  return 1
                end

                echo "Transcribiendo con faster-whisper ($fw_model, $fw_device, $fw_compute)..."
                rm -f "$fw_tmp_log"

                "$fw_python" -c '
        import os
        import sys
        import traceback

        audio = sys.argv[1]
        txt = sys.argv[2]
        model_name = sys.argv[3]
        language = sys.argv[4]
        compute_type = sys.argv[5]
        device = sys.argv[6]

        try:
            from faster_whisper import WhisperModel
        except Exception:
            traceback.print_exc()
            sys.exit(2)

        if not os.path.isfile(audio):
            print(f"No existe el audio: {audio}", file=sys.stderr)
            sys.exit(3)

        try:
            model = WhisperModel(model_name, device=device, compute_type=compute_type)
            segments, _ = model.transcribe(audio, language=language, vad_filter=True, beam_size=5, temperature=0.0)
        except Exception:
            traceback.print_exc()
            sys.exit(3)

        with open(txt, "w", encoding="utf-8") as out:
            for segment in segments:
                line = segment.text.strip()
                if line:
                    out.write(line + "\\n")
        ' "$audio" "$txt" "$fw_model" "$fw_lang" "$fw_compute" "$fw_device" 2> "$fw_tmp_log"

                set -l rc $status

                if test $rc -eq 2
                  mv "$fw_tmp_log" "$fw_log"
                  echo "Revisa log: $fw_log"
                  return 1
                else if test $rc -ne 0
                  mv "$fw_tmp_log" "$fw_log"
                  echo "Falló la transcripción (device=$fw_device, compute=$fw_compute)"
                  echo "Prueba temporal: set -gx FASTER_WHISPER_DEVICE cpu"
                  echo "Revisa log: $fw_log"
                  return 1
                end

                rm -f "$fw_tmp_log"

                if not test -s "$txt"
                  echo "La transcripción quedó vacía"
                  return 1
                end

                echo "Transcripción guardada en: $txt"
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
}
