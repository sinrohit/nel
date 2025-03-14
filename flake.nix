{
  description = "Portable environment manager with NixOS-like module system";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ self, ... }:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];

      imports = [
        ./modules
      ];

      perSystem = { config, self', inputs', pkgs, system, lib, ... }: {
        imports = [
          ./config.nix
        ];

        # Define a package that includes all specified packages
        packages.default = pkgs.buildEnv {
          name = "env-packages";
          paths = config.environment.systemPackages;
        };

        # Apps output for `nix run`
        apps.default = {
          type = "app";
          program =
            let
              environmentPackages = config.environment.systemPackages;
              allScripts = builtins.attrValues config.system.activationScripts
                ++ builtins.attrValues config.home.activationScripts;

              envScript = pkgs.writeShellScriptBin "load-env" ''
                TMP_DIR=$(mktemp -d -t nix-env-loader-XXXXXXX)
                trap 'rm -rf "$TMP_DIR"' EXIT

                ${lib.concatMapStrings (script: ''
                  echo "Running activation script: ${script.name}"
                  ${script.text}
                '') allScripts}

                export PATH=${lib.makeBinPath environmentPackages}:$PATH
                ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value:
                  if builtins.isList value
                  then "export ${name}=${lib.concatStringsSep ":" value}"
                  else "export ${name}=${value}"
                ) config.environment.variables)}

                export XDG_CONFIG_HOME="$TMP_DIR/.config"

                ${lib.optionalString config.programs.zsh.enable ''
                  ZDOTDIR="$TMP_DIR" exec ${pkgs.zsh}/bin/zsh "$@" || exec ${pkgs.bash}/bin/bash "$@"
                ''}

                ${lib.concatStringsSep "\n" (lib.mapAttrsToList (name: value:
                  "alias ${name}='${value}'"
                ) config.environment.shellAliases)}

                exec ${pkgs.bash}/bin/bash "$@"
              '';
            in
            "${envScript}/bin/load-env";
        };

        devShells.default = pkgs.mkShell {
          buildInputs = [ pkgs.nixpkgs-fmt ];
        };
      };
    };
}
