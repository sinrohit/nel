# modules/base.nix
{ lib, ... }:

with lib;

{
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

    programs = {
      # zsh = {
      #   enable = mkEnableOption "zsh shell";
      #   
      #   enableAutosuggestions = mkEnableOption "zsh autosuggestions";
      #   
      #   enableSyntaxHighlighting = mkEnableOption "zsh syntax highlighting";
      #   
      #   historySize = mkOption {
      #     type = types.int;
      #     default = 10000;
      #     description = "Number of history lines to keep in memory.";
      #   };
      #   
      #   histFile = mkOption {
      #     type = types.str;
      #     default = "$HOME/.zsh_history";
      #     description = "Location of the zsh history file.";
      #   };
      #   
      #   oh-my-zsh = {
      #     enable = mkEnableOption "oh-my-zsh";
      #     
      #     theme = mkOption {
      #       type = types.str;
      #       default = "robbyrussell";
      #       description = "The oh-my-zsh theme to use.";
      #     };
      #     
      #     plugins = mkOption {
      #       type = types.listOf types.str;
      #       default = [];
      #       description = "List of oh-my-zsh plugins to enable.";
      #     };
      #   };
      #   
      #   initExtra = mkOption {
      #     type = types.lines;
      #     default = "";
      #     description = "Extra commands that should be added to .zshrc.";
      #   };
      # };

      # You can add more programs here similar to NixOS modules
      # Example:
      # vim = {
      #   enable = mkEnableOption "vim editor";
      #   
      #   defaultEditor = mkOption {
      #     type = types.bool;
      #     default = false;
      #     description = "Whether to set vim as the default editor.";
      #   };
      #   
      #   plugins = mkOption {
      #     type = types.listOf types.package;
      #     default = [];
      #     description = "List of vim plugins to install.";
      #   };
      #   
      #   extraConfig = mkOption {
      #     type = types.lines;
      #     default = "";
      #     description = "Extra configuration to add to .vimrc.";
      #   };
      # };
    };

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
}
