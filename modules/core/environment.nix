{ config, lib, pkgs, ... }:
with lib;
{
  options.environment = {
    systemPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Packages available in the environment.";
    };
    variables = mkOption {
      type = types.attrsOf (types.oneOf [ types.str (types.listOf types.str) ]);
      default = { };
      description = "Environment variables.";
    };
    shellAliases = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Shell aliases.";
    };
  };
}
