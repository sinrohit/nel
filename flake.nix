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
            ./modules/base.nix  # Contains the module structure definition
            ./modules/programs/zsh.nix  # ZSH-specific module
            ./modules/programs/vim.nix  # Vim-specific module
            # Add more program-specific modules here
            userConfig          # User's configuration
          ];
          # Provide access to nixpkgs to the modules
          specialArgs = { inherit pkgs lib; };
        };

        # Extract the evaluated config
        evaluatedConfig = config.config;
        
        # Extract the environment packages from the evaluated config
        environmentPackages = evaluatedConfig.environment.systemPackages;
        
        # Create home files directly in the build script instead of during derivation build
        homeFiles = evaluatedConfig.home.file;

        # Create a shell script that sets up the environment
        envScript = pkgs.writeShellScriptBin "load-env" ''
          # Create runtime directory structure
          TMP_DIR=$(mktemp -d -t nix-env-loader-XXXXXXX)
          trap 'rm -rf "$TMP_DIR"' EXIT
          
          # Create home files in the temp directory
          ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value: ''
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
          '') homeFiles)}
          
          # Set up environment variables
          export PATH=${lib.makeBinPath environmentPackages}:$PATH
          ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value: 
            if builtins.isList value 
            then "export ${name}=${lib.concatStringsSep ":" value}"
            else "export ${name}=${value}"
          ) evaluatedConfig.environment.variables)}
          
          # Set HOME to point to the temp directory just for configuration files
          # This allows using the config files without modifying the real home directory
          export XDG_CONFIG_HOME="$TMP_DIR/.config"
          
          # Print available packages
          echo "Environment loaded with these packages:"
          echo "${lib.concatMapStringsSep "\n" (pkg: "- ${pkg.name}") environmentPackages}"
          
          # If ZSH is enabled, use it as the shell
          ${lib.optionalString evaluatedConfig.programs.zsh.enable ''
            # For zsh, we need to set ZDOTDIR to our temp directory so it reads our .zshrc
            # rather than using --rcfile which is a bash option
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
