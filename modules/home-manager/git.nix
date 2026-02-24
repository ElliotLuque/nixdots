{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "ElliotLuque";
        email = "git@elliotluque.com";
      };
      init.defaultBranch = "main";
      pull.rebase = false;
      url = {
        "https://github.com/" = {
          insteadOf = [
            "gh:"
            "github:"
          ];
        };
      };
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      dark = true;
      navigate = true;
      line-numbers = true;
      side-by-side = false;
      syntax-theme = "Catppuccin Mocha";
      hyperlinks = true;
      file-style = "omit";
      hunk-header-style = "file line-number";
      hunk-header-decoration-style = "black box";
      hunk-header-file-style = "blue";
      hunk-header-line-number-style = "magenta";
    };
  };
}
