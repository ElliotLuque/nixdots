{ inputs, ... }:
{
  # Any Home Manager user can import this feature, without the workstation role.
  flake.modules.homeManager.agent-skills = {
    imports = [ inputs.agent-skills.homeManagerModules.default ];
    programs.agent-skills = {
      enable = true;
      sources = {
        taste = {
          path = inputs.taste-skill;
          subdir = "skills";
        };
        impeccable = {
          path = inputs.impeccable;
          subdir = ".agents/skills";
        };
        matt = {
          path = inputs.matt-skills;
          subdir = "skills/engineering";
        };
        video = {
          path = inputs.video-agent-skills;
          subdir = "skills";
        };
      };
      skills = {
        enable = [
          "impeccable"
          "codebase-design"
          "domain-modeling"
          "code-review"
          "editing"
          "studio-setup"
          "studio-script"
          "insta-audit"
          "outliers"
          "short-editing"
          "steal"
          "broll"
          "clips"
          "short-translate"
          "vox"
          "codex-images"
          "publish"
        ];
        explicit.gpt-taste = {
          from = "taste";
          path = "gpt-tasteskill";
        };
      };
      targets.agents.enable = true;
    };
  };
}
