{ stdenv, lib, autoPatchelfHook }:
with lib;
let
in
stdenv.mkDerivation rec {
  pname = "gotosocial-bin";
  version = "0.10.0-rc3";

  src = builtins.fetchurl {
    url = "https://github.com/superseriousbusiness/gotosocial/releases/download/v${version}/gotosocial_${version}_linux_amd64.tar.gz";
    sha256 = "sha256:0xnaqn38bafqpvk2sdl5m5ddkbs92ykxav3lzsfphydj9n5a80hb";
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
