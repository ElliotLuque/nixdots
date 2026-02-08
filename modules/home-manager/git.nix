{
  programs.git = {
    enable = true;

    settings = {
      user = {
        name = "ElliotLuque";
        email = "git@elliotluque.com";
      };
      init.defaultBranch = "main";
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
