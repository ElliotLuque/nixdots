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
        emil = {
          path = inputs.emil-skills;
          subdir = "skills";
        };
        matt = {
          path = inputs.matt-skills;
          subdir = "skills/engineering";
          # Avoid collisions with Emil's prototype skill, even when unselected.
          filter.nameRegex = "codebase-design|domain-modeling|code-review";
        };
        remotion = {
          path = inputs.remotion-skills;
          subdir = "skills";
        };
        video = {
          path = inputs.video-agent-skills;
          subdir = "skills";
        };
      };
      skills = {
        enable = [
          "impeccable"
          "emil-design-eng"
          "animate"
          "review-animations"
          "improve-animations"
          "find-animation-opportunities"
          "remove-animations"
          "animation-performance"
          "animation-vocabulary"
          "apple-design"
          "pick-ui-library"
          "prototype"
          "mobile-native"
          "break-ui"
          "codebase-design"
          "domain-modeling"
          "code-review"
          # "editing"
          # "studio-setup"
          # "studio-script"
          # "insta-audit"
          # "outliers"
          # "short-editing"
          # "steal"
          # "broll"
          # "clips"
          # "short-translate"
          # "vox"
          "codex-images"
          # "publish"
          # "remotion-best-practices"
          # "remotion-captions"
          # "remotion-create"
          # "remotion-docs"
          # "remotion-interactivity"
          # "remotion-maps"
          # "remotion-markup"
          # "remotion-multimedia"
          # "remotion-render"
          # "remotion-saas"
          # "remotion-studio"
          # "remotion-upgrade"
        ];
        explicit.design-taste-frontend = {
          from = "taste";
          path = "taste-skill";
        };
      };
      targets.agents.enable = true;
    };
  };
}
