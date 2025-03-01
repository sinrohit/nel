{ self, lib, flake-parts-lib, ... }:

let
  inherit (flake-parts-lib)
    mkPerSystemOption;
  inherit (lib)
    mkOption
    types;
in
{
  options.perSystem = mkPerSystemOption ({ config, self', pkgs, ... }: {

    imports = [
      ./activation.nix
      ./programs/zsh.nix
      ./programs/vim.nix
    ];
    options = {

      environment = {
        systemPackages = mkOption {
          type = types.listOf types.package;
          default = [ ];
          description = "The set of packages that appear in the user environment.";
        };

        variables = mkOption {
          type = types.attrsOf (types.oneOf [ types.str (types.listOf types.str) ]);
          default = { };
          description = "Environment variables to set.";
        };

        shellAliases = mkOption {
          type = types.attrsOf types.str;
          default = { };
          description = "An attribute set that maps aliases to their values.";
        };
      };

      # programs = mkOption {
      #   type = types.submoduleWith {
      #     modules = [
      #       ({ config, ... }: {
      #         _module.args.pkgs = pkgs;
      #       })
      #       ./programs/zsh.nix
      #       ./programs/vim.nix
      #     ];
      #   };
      #   default = { };
      #   description = "Program configuration options";
      # };

      # You can add more option categories here
      home = {
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
    };
  });
}
