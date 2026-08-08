{
  config,
  pkgs,
  pkgs-kbctl,
  inputs,
  system,
  ...
}:

let
  llm-agents = inputs.llm-agents.packages.${system};
  maki = inputs.maki.packages.${system}.default;

  #llamacpp = inputs.llamacpp.packages.${system};
  pkgsRocm = import <nixpkgs> {
    config = {
      allowUnfree = true;
      rocmSupport = true;
      permittedInsecurePackages = [
        "python3.13-vllm-0.16.0"
      ];
    };
  };

  vllm = pkgsRocm.vllm;

  llama-cpp = pkgs.llama-cpp.override {
    vulkanSupport = false;
    cudaSupport = false;
    rocmSupport = true;
    rocmGpuTargets = [ "gfx1151" ];
  };

  llamacpp = llama-cpp.overrideAttrs (oldAttrs: rec {

    version = "9992";
    src = pkgs.fetchFromGitHub {
      owner = "ggml-org";
      repo = "llama.cpp";
      tag = "b${version}";
      hash = "sha256-yWyNIVx7jVuskKywG9HQ4WpPfplMtQAWjLAFbJxPEbA=";
      leaveDotGit = true;
      postFetch = ''
        git -C "$out" rev-parse --short HEAD > $out/COMMIT
        find "$out" -name .git -print0 | xargs -0 rm -rf
      '';
    };
    npmDepsHash = "sha256-6s9skw1wzEfm9QKktTqea3J+oudQAsS6O2VnZEMXAdw=";

    # preFixup = ''
    #   wrapProgram $out/bin/llama \
    #     --set-default HSA_OVERRIDE_GFX_VERSION 11.5.1
    # '';

    # nativeBuildInputs = (with pkgs; [
    #     cmake
    #     installShellFiles
    #     ninja
    #     nodejs
    #     npmHooks.npmConfigHook
    #     pkg-config
    #     spirv-headers
    #     makeWrapper
    #   ]);
  });

in

{

  # Home Manager needs a bit of information about you and the paths it should
  # manage.
  home.username = builtins.getEnv "USER";
  home.homeDirectory = builtins.getEnv "HOME";



  # You're not supposed to update this value because it changes config options and is not guaranteed to be compatible
  # But because I use home manager exclusively for packages, and not at all for config, I can safely update this to the latest version pretty much always
  home.stateVersion = "25.11";
  # Prevent generation of home-configuration.nix manpage (not all packages)
  # Prevents a warning about something being unreliable
  manual.manpages.enable = false;

  # Enables GPU acceleration for all Nix pacakges, not just home manager one's.
  targets.genericLinux = {
    enable = true;
    gpu.enable = true;
  };

  # targets.genericLinux.nixGL = {
  #   packages = null;
  #   #packages = pkgs.nixgl;
  #   defaultWrapper = "mesa";
  #   # might cause issues
  #   vulkan.enable = true;
  # };

  home.packages =
    (with pkgs; [
      # nix cli helper
      nh

      pkgs-kbctl.kubectl
      pkgs.fluxcd
      pkgs.kubernetes-helm
      pkgs.yaml-language-server
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
      pkgs.dbeaver-bin

      # logging
      pkgs.lnav

      # github cli client + copilot
      pkgs.gh

      # llama.cpp
      #llamacpp.rocm
      #(config.lib.nixGL.wrappers.mesa llamacpp.vulkan)
      #(config.lib.nixGL.wrappers.mesa llamacpp)
      #llamacpp
      #vllm

      # llm agents
      llm-agents.nanocoder
      llm-agents.kilocode-cli
      llm-agents.goose-cli
      llm-agents.forgecode
      llm-agents.hermes-agent
      llm-agents.hermes-desktop
      llm-agents.hermes-hud
      llm-agents.pi
      maki

      # sandboxing features
      pkgs.fence

      # UI stuff for AI
      pkgs.open-webui

      # nix dev stuff
      pkgs.nixd
      pkgs.nil

      # games and fun
      pkgs.gzdoom pkgs.ares

    ])
    #++ gpu-wrapped-agents
    #++ gpu-wrapped-hermes
    ;

  programs.man = {
    enable = true;
    generateCaches = true;
  };

  nix = {
    # nix shell nixpkgs#test will use home manager's nixpkgs and dependencies
    # This prevents auto updattes and then massive duplication of dependencies of nix flake stuff.
    registry.nixpkgs.flake = inputs.nixpkgs;

    package = pkgs.nix;
    settings = {
      flake-registry = "${config.xdg.configHome}/nix/project-registry.json";
      extra-experimental-features = [ "nix-command" "flakes" ];
      extra-trusted-substituters = [
            "https://nix-community.cachix.org"
            "https://cache.numtide.com"
          ];

          extra-trusted-public-keys = [
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g="
          ];
    };
  };


  home.file = {
    # Adjusting nix.channels, nix.path and similar requires home manager to be managing the shell and env variables
    # Since home manager isn't, I just directly symlink the empty channels directory to home managers nixpkgs flake.
    # This fixes channels not working, since they disappeared on me
    ".nix-defexpr/channels" = {
        source = (pkgs.linkFarm "home-manager-channels" [
           {
             name = "nixpkgs";
             path = inputs.nixpkgs;
           }
         ]);
        recursive = false;
      };
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
    # see https://github.com/karolswdev/framework-rocm
    # I could probably wrap llama.cpp itself but whatever
    #wHSA_OVERRIDE_GFX_VERSION = "11.5.1";
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;
}
