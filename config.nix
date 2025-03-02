{ pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    git
    gh
    gnumake
    python3
    htop
    ripgrep
    fd
    bat
  ];

  environment.variables = {
    EDITOR = "vim";
    LANG = "en_US.UTF-8";
  };

  environment.shellAliases = {
    ll = "ls -la";
    gst = "git status";
  };

  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableSyntaxHighlighting = true;
    oh-my-zsh = {
      enable = true;
      theme = "agnoster";
      plugins = [ "git" "docker" "kubectl" "python" ];
    };
    initExtra = ''
    '';
  };

  programs.vim = {
    enable = true;
    defaultEditor = true;
    plugins = with pkgs.vimPlugins; [ vim-sensible vim-airline nerdtree ];
    extraConfig = ''
      set number relativenumber
      syntax on
      set tabstop=2 shiftwidth=2 expandtab
      map <C-n> :NERDTreeToggle<CR>
    '';
  };

  programs.starship = {
    enable = false;
    settings = {
      add_newline = false;
      prompt_order = [ "username" "directory" "git_branch" "git_status" "cmd_duration" ];
    };
  };

  programs.zoxide.enable = true;

  home.file = {
    ".gitconfig".text = ''
      [user]
        name = Your Name
        email = your.email@example.com
      [core]
        editor = vim
    '';
  };
}
