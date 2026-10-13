{ inputs, config, ... }:
let
  modules = config.flake.modules;
  lc = config.flake.lib.livingCode.colors;
in
{
  perSystem =
    { pkgs, system, ... }:
    let
      # Evaluation-only fixtures, not deployable hosts or a speculative VPS role.
      headless = inputs.nixpkgs.lib.nixosSystem {
        modules = [
          modules.nixos.base
          {
            nixpkgs.hostPlatform = system;
            boot.isContainer = true;
            system.stateVersion = "24.11";
          }
        ];
      };
      skillsHome = inputs.home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        modules = [
          modules.homeManager.agent-skills
          {
            home.username = "skills-test";
            home.homeDirectory = "/home/skills-test";
            home.stateVersion = "24.11";
          }
        ];
      };
      aiFixture = {
        nixpkgs.hostPlatform = system;
        boot.isContainer = true;
        system.stateVersion = "24.11";
        users.users.ai-test.isNormalUser = true;
        home-manager.users.ai-test = {
          imports = [ modules.homeManager.ai-clients ];
          home = {
            username = "ai-test";
            homeDirectory = "/home/ai-test";
            stateVersion = "24.11";
          };
        };
      };
      headlessAi = inputs.nixpkgs.lib.nixosSystem {
        modules = [
          modules.nixos.base
          modules.nixos.home-manager
          aiFixture
        ];
      };
      localAi = inputs.nixpkgs.lib.nixosSystem {
        modules = [
          modules.nixos.base
          modules.nixos.home-manager
          aiFixture
          {
            services.ollama = {
              enable = true;
              port = 11500;
              loadModels = [
                "test-primary"
                "test-secondary"
              ];
            };
            home-manager.users.ai-test.imports = [ modules.homeManager.local-llm ];
          }
        ];
      };
      desktop = inputs.nixpkgs.lib.nixosSystem {
        modules = [
          modules.nixos.workstation
          {
            nixpkgs.hostPlatform = system;
            boot.isContainer = true;
            system.stateVersion = "24.11";
            users.users.desktop-test.isNormalUser = true;
            home-manager.users.desktop-test.home.stateVersion = "24.11";
          }
        ];
      };
      base = headless.config;
      ai = headlessAi.config;
      localHome = localAi.config.home-manager.users.ai-test;
      piModels = (builtins.fromJSON localHome.home.file.".pi/agent/models.json".text).providers.ollama;
      desktopHome = desktop.config.home-manager.users.desktop-test;
      desktopScripts = inputs.nixpkgs.lib.filter (
        package:
        builtins.elem (inputs.nixpkgs.lib.getName package) [
          "screenshot-area"
          "color-picker"
          "brightness-step"
        ]
      ) desktopHome.home.packages;
      laptopHome = config.flake.nixosConfigurations.nixos-laptop.config.home-manager.users.elliot;
      # Only Lua text is under test; do not build GPU plugins to stub their calls.
      hyprlandLua = pkgs.writeText "hyprland.lua" (
        builtins.unsafeDiscardStringContext laptopHome.xdg.configFile."hypr/hyprland.lua".text
      );
      hostLua = pkgs.writeText "host.lua" laptopHome.xdg.configFile."hypr/host.lua".text;
    in
    {
      checks.architecture =
        assert !base.programs.hyprland.enable;
        assert !base.services.xserver.enable;
        assert !base.services.greetd.enable;
        assert !base.hardware.graphics.enable;
        assert !base.services.ollama.enable;
        assert !base.virtualisation.docker.enable;
        assert !base.services.openssh.enable;
        assert !base.networking.networkmanager.enable;
        assert base.networking.firewall.allowedTCPPorts == [ ];
        assert base.networking.firewall.allowedUDPPorts == [ ];
        assert !(base ? home-manager);
        assert builtins.isString base.system.build.toplevel.drvPath;
        assert skillsHome.config.programs.agent-skills.enable;
        assert skillsHome.config.programs.agent-skills.targets.agents.enable;
        assert builtins.isString skillsHome.activationPackage.drvPath;
        assert ai.home-manager.users.ai-test.programs.agent-skills.enable;
        assert !ai.programs.hyprland.enable;
        assert !ai.services.xserver.enable;
        assert !ai.services.greetd.enable;
        assert !ai.hardware.graphics.enable;
        assert !ai.services.ollama.enable;
        assert !ai.virtualisation.docker.enable;
        assert ai.networking.firewall.allowedTCPPorts == [ ];
        assert !(ai.home-manager.users.ai-test.home.file ? ".pi/agent/models.json");
        assert
          ai.home-manager.users.ai-test.home.file.".pi/agent/extensions/pi-anthropic-auth".source
          == inputs.pi-anthropic-auth;
        assert !(ai.home-manager.users.ai-test.home.file ? ".pi/agent/auth.json");
        assert !(ai.home-manager.users.ai-test.home.file ? ".pi/agent/settings.json");
        assert
          toString ai.home-manager.users.ai-test.home.file.".pi/agent/extensions/terminal-statusline".source
          == "${inputs.pi-terminal-statusline}/extensions/statusline";
        assert builtins.pathExists "${inputs.pi-terminal-statusline}/extensions/statusline/index.ts";
        assert ai.home-manager.users.ai-test.programs.codex.profiles == { };
        assert ai.home-manager.users.ai-test.programs.opencode.settings == { };
        assert builtins.all
          (
            home:
            !(home.home.file ? ".agents/skills/terminal-browser")
            && builtins.all (
              package:
              !(builtins.elem (inputs.nixpkgs.lib.getName package) [
                "herdr-agent-usage-profile"
                "herdr-radar-profile"
              ])
            ) home.home.packages
            &&
              builtins.all
                (plugin: !(inputs.nixpkgs.lib.hasInfix plugin home.xdg.configFile."herdr/config.toml".text))
                [
                  "herdr-agent-quota"
                  "hhdebb.herdr-radar"
                  "worktrunk"
                ]
          )
          [
            ai.home-manager.users.ai-test
            desktopHome
            laptopHome
          ];
        assert builtins.isString ai.system.build.toplevel.drvPath;
        assert builtins.elem "vim" (map inputs.nixpkgs.lib.getName base.environment.systemPackages);
        assert builtins.elem "neovim" (map inputs.nixpkgs.lib.getName base.environment.systemPackages);
        assert map (model: model.id) piModels.models == localAi.config.services.ollama.loadModels;
        assert piModels.baseUrl == "http://127.0.0.1:11500/v1";
        assert localHome.programs.codex.profiles.local.model == "test-primary";
        assert
          localHome.programs.codex.profiles.local.model_providers.local-ollama.base_url == piModels.baseUrl;
        assert
          builtins.attrNames localHome.programs.opencode.settings.provider.ollama.models
          == localAi.config.services.ollama.loadModels;
        assert localHome.programs.opencode.settings.provider.ollama.options.baseURL == piModels.baseUrl;
        assert builtins.isString localAi.config.system.build.toplevel.drvPath;
        assert
          (builtins.head desktopHome.programs.hyprlock.settings.background).path
          == toString desktopHome.stylix.image;
        assert
          desktopHome.programs.caelestia.settings.paths.wallpaperDir
          == "${desktopHome.xdg.dataHome}/wallpapers";
        assert builtins.pathExists (desktopHome.xdg.dataFile.wallpapers.source + "/cottages-river.png");
        assert builtins.any (
          p: inputs.nixpkgs.lib.getName p == "wl-clipboard"
        ) desktop.config.environment.systemPackages;
        assert !desktop.config.programs.localsend.enable;
        assert desktop.config.networking.firewall.allowedTCPPorts == [ ];
        assert desktop.config.networking.firewall.allowedUDPPorts == [ ];
        assert desktop.config.networking.networkmanager.ensureProfiles.profiles == { };
        assert !(desktopHome.systemd.user.services ? proton-vpn);
        assert builtins.all
          (name: builtins.elem name (map inputs.nixpkgs.lib.getName desktopHome.home.packages))
          [
            "kooha"
            "wf-recorder"
            "slurp"
          ];
        assert desktopHome.programs.swayimg.enable;
        assert desktopHome.xdg.configFile."swayimg/init.lua".text != "";
        assert builtins.elem "swayimg" (map inputs.nixpkgs.lib.getName desktopHome.home.packages);
        assert !(builtins.elem "feh" (map inputs.nixpkgs.lib.getName desktopHome.home.packages));
        assert builtins.all
          (mime: desktopHome.xdg.mimeApps.defaultApplications.${mime} == [ "swayimg.desktop" ])
          [
            "image/jpeg"
            "image/png"
            "image/gif"
            "image/webp"
            "image/svg+xml"
            "image/bmp"
            "image/tiff"
          ];
        assert builtins.isString desktop.config.system.build.toplevel.drvPath;
        pkgs.runCommand "architecture-check" { } ''
          touch "$out"
        '';

      checks.herdr-theme =
        pkgs.runCommand "herdr-theme-check" { nativeBuildInputs = [ pkgs.python3 ]; }
          ''
            python3 - '${desktopHome.xdg.configFile."herdr/config.toml".source}' <<'PY'
            import pathlib, sys, tomllib
            config = tomllib.loads(pathlib.Path(sys.argv[1]).read_text())
            theme = config['theme']['custom']
            assert all(theme[key] == 'reset' for key in (
                'panel_bg', 'sidebar_bg'
            ))
            assert theme['active_row_bg'] == '${lc.surface1}'
            assert theme['selection_bg'] == '${lc.surface2}'
            assert theme['selection_bg'] != theme['active_row_bg']
            assert theme['accent'] == '${lc.teal}'
            assert theme['green'] == '${lc.comment}'  # Idle is muted, not successful.
            assert theme['yellow'] == '${lc.amber}'  # Working.
            assert theme['red'] == '${lc.flare}'  # Blocked.
            assert theme['teal'] == '${lc.moss}'  # Done.
            assert config['ui']['status_indicators'] == 'symbols'
            assert config['ui']['pane_borders'] == 'auto'
            assert config['ui']['pane_outer_borders']
            assert 'accent' not in config['ui']  # The theme accent is the living-code teal.
            assert config['ui']['agent_panel_sort'] == 'priority'
            assert 'spaces' not in config['ui']['sidebar']  # Keep built-in space rows.
            agents = config['ui']['sidebar']['agents']
            assert agents['row_gap'] == 0
            assert agents['rows'] == [
                ['state_icon', {'token': 'terminal_title_stripped', 'dim': False}],
                [{'token': 'workspace', 'dim': True, 'bold': False}],
            ]
            keys = config['keys']
            assert keys['prefix'] == 'ctrl+a'
            assert keys['workspace_picker'] == 'prefix+w'
            assert keys['switch_tab'] == 'prefix+1..9'
            assert 'switch_tab' not in config['ui']['toast']
            for direction, vim_key in (('left', 'h'), ('down', 'j'), ('up', 'k'), ('right', 'l')):
                assert keys[f'focus_pane_{direction}'] == [f'prefix+{vim_key}', f'prefix+{direction}']
            assert keys['indexed'] == {'workspaces': 'ctrl', 'agents': 'ctrl+shift'}
            commands = {command['key']: command for command in keys['command']}
            assert len(commands) == len(keys['command'])  # No duplicate command bindings.
            assert 'ctrl+g' not in commands  # Lazygit requires the prefix.
            git = commands['prefix+ctrl+g']
            assert git['type'] == 'popup'
            assert git['command'].endswith('/bin/lazygit; exit')
            assert (git['width'], git['height']) == ('95%', '90%')
            terminal = commands['prefix+shift+c']
            assert terminal['type'] == 'popup'
            assert terminal['command'] == 'exec ${pkgs.fish}/bin/fish -i'
            assert (terminal['width'], terminal['height']) == ('80%', '80%')
            assert commands['prefix+d']['type'] == 'popup'  # Hunk still composes.
            PY
            touch "$out"
          '';

      checks.desktop-scripts =
        assert builtins.length desktopScripts == 3;
        pkgs.symlinkJoin {
          name = "desktop-scripts-check";
          paths = desktopScripts;
        };

      checks.hyprland-overrides =
        pkgs.runCommand "hyprland-overrides-check"
          {
            nativeBuildInputs = [ pkgs.lua5_4 ];
          }
          ''
            export XDG_CONFIG_HOME="$PWD/config"
            mkdir -p "$XDG_CONFIG_HOME/hypr"
            cp ${hostLua} "$XDG_CONFIG_HOME/hypr/host.lua"
            lua ${./desktop/_tests/hyprland.lua} ${hyprlandLua}
            touch "$out"
          '';
    };
}
