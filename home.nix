{ config, pkgs, pkgs-kbctl, hermes, llm-agents, inputs, system, ... }:

let 
  hermes = inputs.hermes.packages.${system};

  # borked or not needed hermes packages
  broken-hermes = [ 
    # Not needed, configkeys broken
    "configKeys" "fix-lockfiles"

    # Duplicates that break things
    "hermes-full" "default" "messaging"
   ];

  working-hermes =  builtins.attrValues
    (builtins.removeAttrs hermes broken-hermes);

  gpu-wrapped-hermes = builtins.map config.lib.nixGL.wrappers.mesa working-hermes;


  llm-agents = inputs.llm-agents.packages.${system};
  # Not all agents are working so I filter out broken ones

  # list of broken agents for filtering
  broken-agents = [
    #"aionui"   
    "showboat"
    # "backlog-md"
    # "mistral-vibe"
    # "codex"

    # Not an agent
    "flake-inputs"

    # This stuff seems to be failing due to npm network issues. 
    # It's probably my home internet rather than broken packages
    # Or it could be me being rate limited
    #"reasonix"
    #"paseo-desktop"
    "codegraph"
    #"gitbutler"
    "but"
    #"openclaw"
    
    # conflicts with code-oss. Annoying.
    "code"

    # Not broken but I am getting it from the hermes flake
    "hermes-desktop" "hermes-agent" "hermes-hud"
  ];

  working-agents =  builtins.attrValues
      (builtins.removeAttrs llm-agents broken-agents);

  gpu-wrapped-agents = (builtins.map config.lib.nixGL.wrappers.mesa working-agents);

  gpu-wrapped-agents-attrset = builtins.listToAttrs gpu-wrapped-agents;

  #llamacpp = inputs.llamacpp.packages.${system};

  llama-cpp = pkgs.llama-cpp.override {
      vulkanSupport = true;
      cudaSupport = false;
      rocmSupport = true;
      rocmGpuTargets = ["gfx1152"];
    };

  llamacpp = llama-cpp.overrideAttrs (oldAttrs: rec {

    version = "9684";
    src = pkgs.fetchFromGitHub {
    owner = "ggml-org";
    repo = "llama.cpp";
    tag = "b${version}";
    hash = "sha256-BQrdTEXUarGZcXU/g1w0BTx6FFDbuy738mcGINmwnGE=";
    leaveDotGit = true;
    postFetch = ''
      git -C "$out" rev-parse --short HEAD > $out/COMMIT
      find "$out" -name .git -print0 | xargs -0 rm -rf
    '';
    };
    npmDepsHash = "sha256-0dctM/apI3ysMIEVBaBXO9hZMWskpJpNpOws1gwiOYc=";
  }); 


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
   vulkan.enable = true;
  };

  home.packages = (with pkgs; [
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
        kubectl-cnpg
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
    (config.lib.nixGL.wrappers.mesa pkgs.dbeaver-bin)

    # logging
    pkgs.lnav

    # github cli client + copilot
    pkgs.gh

    # llama.cpp
    #llamacpp.rocm
    #(config.lib.nixGL.wrappers.mesa llamacpp.vulkan)
    (config.lib.nixGL.wrappers.mesa llamacpp)

    # llm agents
    (config.lib.nixGL.wrappers.mesa llm-agents.nanocoder) 
    (config.lib.nixGL.wrappers.mesa llm-agents.kilocode-cli)
    (config.lib.nixGL.wrappers.mesa llm-agents.goose-cli)
    (config.lib.nixGL.wrappers.mesa llm-agents.forgecode)
    
    # sandboxing features
    pkgs.fence

    # UI stuff for AI
    pkgs.open-webui


    # nix dev stuff
    pkgs.nixd
    pkgs.nil

  ])
  #++ gpu-wrapped-agents
  ++ gpu-wrapped-hermes
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
    # Debug variable available in the repl (after :lf .) at homeConfigurations.moonpie.config.home.sessionVariables.TYPE_OF
    # Because nix is such a nightmare to debug that I have to do this to view the type of something declared inside the let block
    #TYPE_OF = "${builtins.typeOf gpu-wrapped-agents}";  
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
