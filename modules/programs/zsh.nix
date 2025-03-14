{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.programs.zsh;
in
{
  options.programs.zsh = {
    enable = mkEnableOption "Zsh shell";
    enableAutosuggestions = mkEnableOption "Zsh autosuggestions";
    enableSyntaxHighlighting = mkEnableOption "Zsh syntax highlighting";
    historySize = mkOption { type = types.int; default = 10000; };
    histFile = mkOption { type = types.str; default = "$HOME/.zsh_history"; };
    oh-my-zsh = {
      enable = mkEnableOption "Oh My Zsh";
      theme = mkOption { type = types.str; default = "robbyrussell"; };
      plugins = mkOption { type = types.listOf types.str; default = [ ]; };
    };
    initExtra = mkOption { type = types.lines; default = ""; };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.zsh ]
      ++ optional cfg.enableAutosuggestions pkgs.zsh-autosuggestions
      ++ optional cfg.enableSyntaxHighlighting pkgs.zsh-syntax-highlighting
      ++ optional cfg.oh-my-zsh.enable pkgs.oh-my-zsh;

    home.activationScripts.zshSetup = {
      name = "zshSetup";
      text = ''
        cat > "$TMP_DIR/.zshrc" << 'EOF'
        HISTSIZE=${toString cfg.historySize}
        HISTFILE=${cfg.histFile}
        SAVEHIST=${toString cfg.historySize}

        ${optionalString cfg.oh-my-zsh.enable ''
          export ZSH=${pkgs.oh-my-zsh}/share/oh-my-zsh
          ZSH_THEME="${cfg.oh-my-zsh.theme}"
          plugins=(${concatStringsSep " " cfg.oh-my-zsh.plugins})
          source $ZSH/oh-my-zsh.sh
        ''}

        ${optionalString cfg.enableAutosuggestions ''
          source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
        ''}

        ${optionalString cfg.enableSyntaxHighlighting ''
          source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
        ''}
            
        ${optionalString config.programs.zoxide.enable ''
          eval "$(zoxide init zsh)"
        ''}

        ${optionalString config.programs.starship.enable ''
          eval "$(starship init zsh)"
        ''}

        ${cfg.initExtra}
        EOF
      '';
      deps = [ "homeFiles" ];
    };
  };
}
