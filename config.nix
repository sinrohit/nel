# config.nix
{ pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    # Development tools
    git
    gh
    gnumake
    python3
    
    # System utilities
    htop
    ripgrep
    fd
    bat
  ];
  
  environment.variables = {
    EDITOR = "vim";
    LANG = "en_US.UTF-8";
    # Add other environment variables
  };
  
  environment.shellAliases = {
    ll = "ls -la";
    gst = "git status";
    gco = "git checkout";
  };
  
  # ZSH Configuration
  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableSyntaxHighlighting = true;
    historySize = 50000;
    
    oh-my-zsh = {
      enable = true;
      theme = "agnoster";
      plugins = [ 
        "git" 
        "docker" 
        "kubectl" 
        "python"
      ];
    };
    
    initExtra = ''
      # Custom ZSH configuration
      setopt AUTO_CD
      setopt CORRECT
      
      # Custom functions
      function mkcd() {
        mkdir -p "$1" && cd "$1"
      }
    '';
  };
  
  # Vim Configuration
  programs.vim = {
    enable = true;
    defaultEditor = true;
    plugins = with pkgs.vimPlugins; [
      vim-sensible
      vim-airline
      nerdtree
    ];
    
    extraConfig = ''
      " Custom Vim settings
      set number
      set relativenumber
      syntax on
      set tabstop=2
      set shiftwidth=2
      set expandtab
      
      " NERDTree mappings
      map <C-n> :NERDTreeToggle<CR>
    '';
  };
  
  # Home files
  home.file = {
    ".gitconfig".text = ''
      [user]
        name = Your Name
        email = your.email@example.com
      [core]
        editor = vim
      [color]
        ui = auto
    '';
    
    # Example of creating a custom script
    ".local/bin/update-system".text = ''
      #!/bin/sh
      echo "Updating system packages..."
      nix flake update
      home-manager switch
    '';
  };
}
