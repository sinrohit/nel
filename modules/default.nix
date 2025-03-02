{ self, lib, flake-parts-lib, ... }:
let
  inherit (flake-parts-lib) mkPerSystemOption;
in
{
  options.perSystem = mkPerSystemOption ({ config, pkgs, ... }: {
    imports = [
      ./core/activation.nix
      ./core/environment.nix
      ./core/home.nix
      ./programs/zsh.nix
      ./programs/zoxide.nix
      ./programs/starship.nix
      ./programs/vim.nix
    ];
  });
}
