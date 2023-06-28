{ pkgs, config, lib, ... } :

let 
    pandoc = null;
    extraRPackages = [];
    extraPythonPackages = ps: with ps; [];
in
 {
    quarto = (pkgs.quarto.overrideAttrs (oldAttrs: rec {
        version = "1.3.361";
        src = pkgs.fetchurl {
            url = "https://github.com/quarto-dev/quarto-cli/releases/download/v${version}/quarto-${version}-linux-amd64.tar.gz";
            sha256 = "sha256-vvnrIUhjsBXkJJ6VFsotRxkuccYOGQstIlSNWIY5nuE=";
        };
        buildInputs = with pkgs; [ ];
        preFixup = ''
            wrapProgram $out/bin/quarto \
            --prefix PATH : ${pkgs.lib.makeBinPath [ pkgs.deno ]} \
            --prefix QUARTO_PANDOC : $out/bin/tools/pandoc \
            --prefix QUARTO_ESBUILD : ${pkgs.esbuild}/bin/esbuild \
            --prefix QUARTO_DART_SASS : $out/bin/tools/dart-sass/sass \
            --prefix QUARTO_R : ${pkgs.rWrapper.override { packages = [ pkgs.rPackages.rmarkdown ] ++ extraRPackages; }}/bin/R \
            --prefix QUARTO_PYTHON : ${pkgs.python3}/bin/python3
        '';
        installPhase = ''
            runHook preInstall

            mkdir -p $out/bin $out/share

            mv bin/* $out/bin
            mv share/* $out/share
            '';
    })).override {inherit pandoc extraPythonPackages extraRPackages;};
}
