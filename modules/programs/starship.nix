{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.programs.starship;
in
{
  options.programs.starship = {
    enable = mkEnableOption "Starship prompt";
    settings = mkOption {
      type = types.attrs;
      default = { };
      description = "Starship configuration.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.starship ];
    home.activationScripts.starshipSetup = {
      name = "starshipSetup";
      text = ''
        mkdir -p "$TMP_DIR/.config"
        cat > "$TMP_DIR/.config/starship.toml" << 'EOF'
        ${builtins.toJSON cfg.settings}
        EOF
      '';
      deps = [ "setup" ];
    };
    environment.variables.STARSHIP_CONFIG = "$TMP_DIR/.config/starship.toml";
  };
}
