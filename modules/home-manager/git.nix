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
}
