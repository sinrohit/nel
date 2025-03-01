{
  description = "Custom environment loader with NixOS-like module system";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = { self, nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit self; } {
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];


      # Import modules within perSystem scope
      imports = [
        ./modules/default.nix
      ];

      perSystem = { config, self', inputs', pkgs, system, lib, ... }: {

        imports = [
          ./config.nix

        ];

        # Define the outputs
        apps =
          let
            environmentPackages = config.environment.systemPackages;

            activationScripts =
              let
                toposort = import ./modules/toposort.nix { inherit lib; };
                allScripts =
                  builtins.attrValues config.system.activationScripts
                  ++ builtins.attrValues config.home.activationScripts;
                getDeps = script:
                  map
                    (dep:
                      if config.system.activationScripts ? ${dep} then
                        config.system.activationScripts.${dep}
                      else if config.home.activationScripts ? ${dep} then
                        config.home.activationScripts.${dep}
                      else
                        throw "Activation script '${dep}' not found"
                    )
                    script.deps;
              in
              toposort.toposort getDeps allScripts;

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
              ) config.environment.variables)}
            
              # Set XDG_CONFIG_HOME to point to the temp directory
              export XDG_CONFIG_HOME="$TMP_DIR/.config"
            
              # Print available packages
              echo "Environment loaded with these packages:"
              echo "${lib.concatMapStringsSep "\n" (pkg: "- ${pkg.name}") environmentPackages}"
            
              # If ZSH is enabled, use it as the shell
              ${lib.optionalString config.programs.zsh.enable ''
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
              ) config.environment.shellAliases)}
            
              if [ $# -gt 0 ]; then
                exec "$@"
              else
                exec ${pkgs.bash}/bin/bash
              fi
            '';
          in
          {
            default = {
              type = "app";
              program = "${envScript}/bin/load-env";
            };
          };

        devShells.default = pkgs.mkShell {
          buildInputs = [
            pkgs.nixpkgs-fmt
          ];
        };
      };
    };
}
