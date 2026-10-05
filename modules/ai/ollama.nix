{ ... }:
{
  # Runtime choice only; each host selects the models it can actually run.
  flake.modules.nixos.ollama-cuda = { pkgs, ... }: {
    services.ollama = {
      enable = true;
      package = pkgs.ollama-cuda;
    };
  };

  # Opt-in user configuration for a host with local Ollama. Use its existing
  # NixOS options as the source of truth instead of duplicating model settings.
  flake.modules.homeManager.local-llm =
    { osConfig, lib, ... }:
    let
      ollama = osConfig.services.ollama;
      models = ollama.loadModels;
      baseUrl = "http://127.0.0.1:${toString ollama.port}/v1";
    in
    {
      assertions = [
        {
          assertion = ollama.enable && models != [ ];
          message = "The local-llm feature requires local Ollama with at least one services.ollama.loadModels entry.";
        }
      ];

      # Register local models without replacing the user's preferred provider.
      home.file.".pi/agent/models.json".text = lib.mkDefault (
        builtins.toJSON {
          providers.ollama = {
            name = "Local Ollama";
            inherit baseUrl;
            api = "openai-completions";
            apiKey = "ollama"; # Dummy key; the local server does not require auth.
            models = map (id: { inherit id; }) models;
          };
        }
      );

      # Select explicitly with `codex --profile local`. Use a distinct provider
      # ID: Codex's built-in "ollama" provider ignores endpoint overrides.
      programs.codex.profiles.local = {
        model = lib.mkDefault (if models == [ ] then "" else builtins.head models);
        model_provider = "local-ollama";
        model_providers.local-ollama = {
          name = "Local Ollama";
          base_url = baseUrl;
          wire_api = "responses";
          requires_openai_auth = false;
        };
      };

      programs.opencode.settings.provider.ollama = {
        name = "Local Ollama";
        npm = "@ai-sdk/openai-compatible";
        options = {
          baseURL = baseUrl;
          apiKey = "ollama";
        };
        models = lib.genAttrs models (id: {
          name = id;
        });
      };
    };
}
