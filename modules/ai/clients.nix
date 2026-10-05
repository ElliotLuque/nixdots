{ inputs, config, ... }:
{
  flake.modules.homeManager.ai-clients = { pkgs, ... }: {
    imports = with config.flake.modules.homeManager; [
      pi
      hunk-review
      opencode
      agent-skills
    ];
    programs.codex.enable = true;
    home.packages = with pkgs; [
      inputs.herdr.packages.${pkgs.stdenv.hostPlatform.system}.default
      claude-code
    ];
  };
}
