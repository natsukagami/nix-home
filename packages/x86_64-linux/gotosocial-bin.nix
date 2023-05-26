{ stdenv, lib, autoPatchelfHook }:
with lib;
let
in
stdenv.mkDerivation rec {
  pname = "gotosocial-bin";
  version = "0.9.0";

  src = builtins.fetchurl {
    url = "https://github.com/superseriousbusiness/gotosocial/releases/download/v${version}/gotosocial_${version}_linux_amd64.tar.gz";
    sha256 = "sha256:0dv3fp0q6ci9br68d7fzni74fqj07a5p71k4hzqhhib9xdhj104v";
    # sha256 = fakeSha256;
  };

  nativeBuildInputs = [ autoPatchelfHook ];

  sourceRoot = ".";

  installPhase = ''
    install -m755 -D gotosocial $out/bin/gotosocial
    mkdir $out/share
    cp -r web $out/share/web
    cp -r example $out/share/example
  '';

  meta = with lib; {
    homepage = "https://docs.gotosocial.org";
    description = "GoToSocial network";
    platforms = platforms.linux;
  };
}
