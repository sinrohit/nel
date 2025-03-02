{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.programs.zoxide;
in
{
  options.programs.zoxide = {
    enable = mkEnableOption "Zoxide directory jumper";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.zoxide ];
    # Integrate with zsh if enabled
    programs.zsh.initExtra = mkIf config.programs.zsh.enable ''
      eval "$(zoxide init zsh)"
    '';
  };
}
