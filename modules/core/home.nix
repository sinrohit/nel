{ config, lib, pkgs, ... }:
with lib;
{
  options.home = {
    file = mkOption {
      type = types.attrsOf (types.submodule {
        options = {
          text = mkOption {
            type = types.nullOr types.lines;
            default = null;
            description = "Text of the file.";
          };
          source = mkOption {
            type = types.nullOr types.path;
            default = null;
            description = "Path of the source file.";
          };
        };
      });
      default = { };
      description = "Files to place directly in $HOME.";
    };
  };
}
