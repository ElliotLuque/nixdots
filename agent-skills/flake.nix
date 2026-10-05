{
  description = "nixdots agent skills";

  inputs = {
    agent-skills.url = "github:Kyure-A/agent-skills-nix";

    taste-skill = {
      url = "github:Leonxlnx/taste-skill";
      flake = false;
    };

    impeccable = {
      url = "github:pbakaus/impeccable";
      flake = false;
    };

    matt-skills = {
      url = "github:mattpocock/skills";
      flake = false;
    };
  };

  outputs =
    inputs@{
      agent-skills,
      ...
    }:
    {
      homeManagerModules.default = {
        imports = [
          agent-skills.homeManagerModules.default

          (import ./home-manager.nix {
            inherit inputs;
          })
        ];
      };
    };
}
