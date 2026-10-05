{ pkgs, ... }:

{
  services.ollama = {
    enable = true;

    package = pkgs.ollama-cuda;

    loadModels = [
      "qwen3.8:27b-q4_k_m"
    ];
  };
}
