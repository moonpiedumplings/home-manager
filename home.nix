{ config, pkgs, pkgs-kbctl, hermes, llm-agents, inputs, system, ... }:

let 
  hermes = inputs.hermes.packages.${system};
  llm-agents = inputs.llm-agents.packages.${system};
  every-agent = builtins.attrValues llm-agents;
  # Not all agents are working so I filter out broken ones
  #working-agents = builtins.filter
  #(agent: !builtins.elem agent.name [ "aionui-2.1.11" ])
  #every-agent;

  # list of broken agents for filtering
  broken-agents = [
    "aionui"
    "hermes-desktop"
    "showboat"
    "backlog-md"
    "mistral-vibe"
    #"openclaw"
    # Not an agent
    "flake-inputs"
  ];

  working-agents =  builtins.attrValues
    #(builtins.removeAttrs llm-agents [ "aionui" "hermes-desktop" "showboat" ]);
    (builtins.removeAttrs llm-agents broken-agents);

  gpu-wrapped-agents = builtins.map config.lib.nixGL.wrappers.mesa working-agents;
in

{
  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";

  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "25.11"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.

  targets.genericLinux.nixGL = {
   packages = pkgs.nixgl;
   defaultWrapper = "mesa";
   # might cause issues
   #  vulkan.enable = true;
  };

  home.packages = [
    pkgs-kbctl.kubectl
    pkgs.fluxcd
    pkgs.kubernetes-helm
    pkgs.yaml-language-server
    pkgs.nixgl.nixGLIntel pkgs.nixgl.nixVulkanIntel
    (config.lib.nixGL.wrappers.mesa pkgs.gzdoom)
    (config.lib.nixGL.wrappers.mesa pkgs.ares)
    pkgs.age
    pkgs.sops
    
    # kubectl plugins and tools
    pkgs.kubectl-cnpg
    pkgs.k9s
    pkgs.kubectl-tree
    pkgs.kubectl-doctor
    pkgs.kubectl-example
    pkgs.kubectl-view-secret
    pkgs.kubectl-graph
    pkgs.kubectl-images
    pkgs.kubectl-explore
    pkgs.kubectl-validate
    pkgs.krelay
    pkgs.kubectl-df-pv
    pkgs.kubectl-node-shell
    pkgs.kubespy
    pkgs.kubeshark
    pkgs.cilium-cli

    # various utilities
    pkgs.streamlink
    pkgs.zellij

    # logging
    pkgs.lnav

    # github cli client + copilot
    pkgs.gh

    # llm agents
    #(config.lib.nixGL.wrappers.mesa llm-agents.hermes-desktop)
    #(config.lib.nixGL.wrappers.mesa hermes.full)
    #(config.lib.nixGL.wrappers.mesa hermes.hermes-desktop)
    #llm-agents.nanocoder
    #llm-agents.omp
    #llm-agents.opencode
    #llm-agents.forgecode

    # sandboxing features
    #pkgs.fence


    # nix dev stuff
    pkgs.nixd
    pkgs.nil

  ] 
  ++ gpu-wrapped-agents
  
  ;

  programs.man = {
    enable = true;
    generateCaches = true;
  };

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  # Home Manager can also manage your environment variables through
  # 'home.sessionVariables'. These will be explicitly sourced when using a
  # shell provided by Home Manager. If you don't want to manage your shell
  # through Home Manager then you have to manually source 'hm-session-vars.sh'
  # located at either
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  ~/.local/state/nix/profiles/profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/moonpie/etc/profile.d/hm-session-vars.sh
  #
  home.sessionVariables = {
    # EDITOR = "emacs";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
