{ lib
, stdenv
, texlive
, pandoc
, makeFontsConf
, fira
, fira-mono
, iosevka
, nix-gitignore
}:

let
  texlive-combined = texlive.combine {
    inherit (texlive)
      scheme-small fontspec pgfopts beamer beamertheme-metropolis;
  };

  fonts = makeFontsConf {
    fontDirectories = [ fira fira-mono iosevka ];
  };

in
stdenv.mkDerivation {
  name = "presentation";
  src = nix-gitignore.gitignoreSourcePure [ ./.gitignore ] ./.;

  phases = [ "unpackPhase" "buildPhase" ];

  buildInputs = [ texlive-combined pandoc ];

  FONTCONFIG_FILE = "${fonts}";

  buildPhase = ''
    mkdir -p $out

    # Make build script executable and run it
    chmod +x scripts/build-presentation
    scripts/build-presentation --output-dir $out
  '';
}
