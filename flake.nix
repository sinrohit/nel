# flake.nix
{
  description = "Custom environment loader with NixOS-like module system";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        lib = nixpkgs.lib;

        # Load the user's configuration
        userConfig = import ./config.nix;
        
        # Process the configuration in a NixOS-like way
        config = lib.evalModules {
          modules = [
            ./modules/base.nix       # Contains the module structure definition
            ./modules/activation.nix  # NixOS-like activation system
            ./modules/programs/zsh.nix    # ZSH-specific module
            ./modules/programs/vim.nix    # Vim-specific module
            # Add more program-specific modules here
            userConfig               # User's configuration
          ];
          # Provide access to nixpkgs to the modules
          specialArgs = { inherit pkgs lib; };
        };

        # Extract the evaluated config
        evaluatedConfig = config.config;
        
        # Extract the environment packages from the evaluated config
        environmentPackages = evaluatedConfig.environment.systemPackages;
        
        # Get sorted activation scripts
        activationScripts = let
          toposort = import ./modules/toposort.nix { inherit lib; };
          allScripts = 
            builtins.attrValues evaluatedConfig.system.activationScripts
            ++ builtins.attrValues evaluatedConfig.home.activationScripts;
          getDeps = script: 
            map (dep: 
              if evaluatedConfig.system.activationScripts ? ${dep} then
                evaluatedConfig.system.activationScripts.${dep}
              else if evaluatedConfig.home.activationScripts ? ${dep} then
                evaluatedConfig.home.activationScripts.${dep}
              else
                throw "Activation script '${dep}' not found"
            ) script.deps;
        in toposort.toposort getDeps allScripts;

        # Create a shell script that sets up the environment
        envScript = pkgs.writeShellScriptBin "load-env" ''
          # Create runtime directory structure
          TMP_DIR=$(mktemp -d -t nix-env-loader-XXXXXXX)
          trap 'rm -rf "$TMP_DIR"' EXIT
          
          # Run all activation scripts in dependency order
          ${lib.concatMapStrings (script: ''
            echo "Running activation script: ${script.name}"
            ${script.text}
          '') activationScripts}
          
          # Set up environment variables
          export PATH=${lib.makeBinPath environmentPackages}:$PATH
          ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value: 
            if builtins.isList value 
            then "export ${name}=${lib.concatStringsSep ":" value}"
            else "export ${name}=${value}"
          ) evaluatedConfig.environment.variables)}
          
          # Set XDG_CONFIG_HOME to point to the temp directory
          export XDG_CONFIG_HOME="$TMP_DIR/.config"
          
          # Print available packages
          echo "Environment loaded with these packages:"
          echo "${lib.concatMapStringsSep "\n" (pkg: "- ${pkg.name}") environmentPackages}"
          
          # If ZSH is enabled, use it as the shell
          ${lib.optionalString evaluatedConfig.programs.zsh.enable ''
            # For zsh, we need to set ZDOTDIR to our temp directory
            if [ $# -gt 0 ]; then
              ZDOTDIR="$TMP_DIR" exec ${pkgs.zsh}/bin/zsh -c "exec \"\$@\""
            else
              ZDOTDIR="$TMP_DIR" exec ${pkgs.zsh}/bin/zsh
            fi
          ''}
          
          # Otherwise use bash with aliases
          ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value: 
            "alias ${name}='${value}'"
          ) evaluatedConfig.environment.shellAliases)}
          
          if [ $# -gt 0 ]; then
            exec "$@"
          else
            exec ${pkgs.bash}/bin/bash
          fi
        '';
      in
      {
        # The app that can be run with `nix run`
        apps.default = {
          type = "app";
          program = "${envScript}/bin/load-env";
        };

        # For development
        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.nixpkgs-fmt
          ];
        };
      }
    );
}
