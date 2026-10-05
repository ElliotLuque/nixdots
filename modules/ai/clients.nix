{ config, ... }:
{
  flake.modules.homeManager.ai-clients = { pkgs, ... }: {
    imports = with config.flake.modules.homeManager; [
      pi
      herdr
      opencode
      agent-skills
    ];
    programs.codex.enable = true;
    home.packages = [ pkgs.claude-code ];
  };
}
