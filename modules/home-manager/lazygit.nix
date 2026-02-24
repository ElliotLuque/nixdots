{ ... }:
{
  programs.lazygit = {
    enable = true;
    enableFishIntegration = true;

    settings = {
      git = {
        pagers = [
          {
            colorArg = "always";
            pager = "delta --dark --paging=never";
          }
        ];
      };
    };
  };
}
