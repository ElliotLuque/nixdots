{ inputs, pkgs, ... }:
{
  home.packages = [
    inputs.pi.packages.${pkgs.system}.default
  ];

  home.file.".pi/agent/models.json".text = builtins.toJSON {
    providers.ollama = {
      name = "Ollama";
      baseUrl = "http://127.0.0.1:11434/v1";
      api = "openai-completions";
      apiKey = "ollama";

      models = [
        {
          id = "qwen3.8:27b-q4_k_m";
          name = "Qwen 3.8 27B Q4_K_M";
        }
      ];
    };
  };
}
