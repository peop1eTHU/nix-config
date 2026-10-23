{
  programs.starship = {
    enable = true;

    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;

    # https://starship.rs/config/
    settings = {
      # Get editor completions based on the config schema
      "$schema" = "https://starship.rs/config-schema.json";

      add_newline = false;
      format = "$directory$character";
      right_format = "$all";

      character = {
        success_symbol = "[➜](bold green)";
        vicmd_symbol = "[N](bold green)";
        error_symbol = "[➜](bold red)";
      };
      # I never rely on the defaults, so this module is useless to me—disabled.
      # I prefer adding --project, --region to very gcloud/aws command.
      aws.disabled = true;
      gcloud.disabled = true;

      kubernetes = {
        symbol = "⛵";
        disabled = false;
      };
      os.disabled = true;
    };
  };
}
