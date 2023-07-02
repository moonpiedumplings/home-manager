{
  pkgs ? import <nixpkgs> {},
  config,
  lib,
  ... 
}:
let
  nixgl = import <nixgl> {};
in
with import ./quarto.nix {inherit pkgs config lib;};
with import ./nixglwrapper.nix {inherit pkgs config lib nixgl;};
{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = "moonpie";
  home.homeDirectory = "/home/moonpie";
  targets.genericLinux.enable = true;

  nixpkgs.config.allowUnfree = true;
  nix = {
    settings = {
    experimental-features = ["nix-command" "flakes"];
    };
  };

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  nix.package = pkgs.nix;
  home.stateVersion = "23.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
  #fonts.fontconfig.enable = true;
  xdg.mime.enable = true;
  home.packages = [
    #nixgl
    nixgl.nixGLIntel
    nixgl.nixVulkanIntel

    #nixgl wrapped stuff
    (nixGLWrap pkgs.vscode)
    (nixGLWrap pkgs.microsoft-edge)
    (nixGLWrap pkgs.firefox-bin)


    #general tools and utilities
    pkgs.micro
    pkgs.calibre
    pkgs.languagetool
    pkgs.htop

    #git tools
    pkgs.git
    pkgs.bfg-repo-cleaner
    pkgs.git-filter-repo

    #share sound with android devices.
    pkgs.soundwireserver

    # development enviroment stuff
    quarto # see the imports above.
    (pkgs.python311.withPackages(ps: with ps; [ jupyter]))
    pkgs.poetry

    # general cli tools
    pkgs.yt-dlp

    #hacking
    pkgs.macchanger
    pkgs.nmap
    pkgs.wireshark
    pkgs.metasploit
    pkgs.aircrack-ng

    #creativity
    pkgs.manuskript

    # storage and encryption
    pkgs.rclone
    pkgs.gocryptfs
    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
  ];

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {};
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs = {
  	home-manager.enable = true;
  	bash.enable = true;
  	gh.enable = true;
  };
}
