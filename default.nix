{ lib
, stdenv
, texlive
, pandoc
, qrencode
, bash
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

  phases = [ "unpackPhase" "patchPhase" "buildPhase" ];

  buildInputs = [ texlive-combined pandoc qrencode bash ];

  FONTCONFIG_FILE = "${fonts}";

  patchPhase = ''
    patchShebangs scripts/
  '';

  buildPhase = ''
    mkdir -p $out

    # Make build script executable and run it
    chmod +x scripts/build-presentation
    scripts/build-presentation --output-dir $out
  '';
}
