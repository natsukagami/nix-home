{ stdenv, lib, fetchurl, autoPatchelfHook }:
with lib;
let
in
stdenv.mkDerivation rec {
  pname = "gotosocial-bin";
  version = "0.12.1";

  src = fetchurl {
    url = "https://github.com/superseriousbusiness/gotosocial/releases/download/v${version}/gotosocial_${version}_linux_amd64.tar.gz";
    hash = "sha256:1i9397iqabm539h0f0j91cl8pl1chglpkzzjb7g14w9bvl086i6y";
    # hash = fakeSha256;
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
