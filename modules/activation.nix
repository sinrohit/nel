# modules/activation.nix
{ config, lib, pkgs, ... }:

with lib;

let
  # Helper function for creating activation scripts
  mkActivationScript = name: text: {
    inherit name text;
    deps = [];
  };
  
  # All activation scripts from various modules
  activationScripts = 
    config.system.activationScripts
    // config.home.activationScripts;
    
  # Sort scripts topologically based on dependencies
  sortedScripts = let
    toposort = import ./toposort.nix { inherit lib; };
  in toposort.toposort (script: map (dep: activationScripts.${dep}) script.deps) 
     (attrValues activationScripts);
in
{
  options = {
    system = {
      activationScripts = mkOption {
        default = {};
        type = types.attrsOf (types.submodule {
          options = {
            text = mkOption {
              type = types.lines;
              description = "Script to execute during activation.";
            };
            deps = mkOption {
              type = types.listOf types.str;
              default = [];
              description = "Scripts that must be executed before this one.";
            };
            name = mkOption {
              type = types.str;
              description = "Name of this activation script.";
            };
          };
        });
        description = "System activation scripts.";
      };
    };
    
    home = {
      activationScripts = mkOption {
        default = {};
        type = types.attrsOf (types.submodule {
          options = {
            text = mkOption {
              type = types.lines;
              description = "Script to execute during home activation.";
            };
            deps = mkOption {
              type = types.listOf types.str;
              default = [];
              description = "Scripts that must be executed before this one.";
            };
            name = mkOption {
              type = types.str;
              description = "Name of this activation script.";
            };
          };
        });
        description = "Home activation scripts.";
      };
    };
  };

  # Ensure default scripts exist
  config = {
    system.activationScripts = {
      setup = mkActivationScript "setup" ''
        echo "Setting up system environment..."
      '';
    };
    
    home.activationScripts = {
      setup = mkActivationScript "setup" ''
        echo "Setting up home environment..."
        mkdir -p "$TMP_DIR/.config"
      '';
      
      # General script to create home files
      homeFiles = {
        name = "homeFiles";
        text = concatStringsSep "\n" (mapAttrsToList (name: value: ''
          echo "Creating file $TMP_DIR/${name}..."
          mkdir -p "$(dirname "$TMP_DIR/${name}")"
          ${if value.source != null then ''
            cp -r "${value.source}" "$TMP_DIR/${name}"
          '' else ''
            cat > "$TMP_DIR/${name}" << 'EOL'
${value.text}
EOL
          ''}
          # Make files executable if they start with a shebang
          if [[ -f "$TMP_DIR/${name}" && $(head -c 2 "$TMP_DIR/${name}") = "#!" ]]; then
            chmod +x "$TMP_DIR/${name}"
          fi
        '') config.home.file);
        deps = [ "setup" ];
      };
    };
  };
}
