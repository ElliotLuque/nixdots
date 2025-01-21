{ ... }:
{
  programs.git = {
    enable = true;
    userName = "ElliotLuque";
    userEmail = "elliotluque@gmail.com";

    delta = {
      enable = true;
      options = {
        line-numbers = true;
	side-by-side = true;
	diff-so-fancy = true;
	navigate = true;
      };
    };

    extraConfig = {
      init.defaultBranch = "main";
      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";
    };
  };
}
