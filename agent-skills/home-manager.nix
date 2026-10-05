{ inputs, ... }:

{
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
    };

    skills = {
      enable = [
        # ui / frontend
        "impeccable"

        # engineering
        "codebase-design"
        "domain-modeling"
        "code-review"
      ];

      explicit = {
        gpt-taste = {
          from = "taste";
          path = "gpt-tasteskill";
        };
      };
    };

    targets.agents.enable = true;
  };
}
