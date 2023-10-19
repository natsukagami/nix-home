{ stdenv, lib, autoPatchelfHook }:
with lib;
let
in
stdenv.mkDerivation rec {
  pname = "gotosocial-bin";
  version = "0.12.0-rc2";

  src = builtins.fetchurl {
    url = "https://github.com/superseriousbusiness/gotosocial/releases/download/v${version}/gotosocial_${version}_linux_amd64.tar.gz";
    sha256 = "sha256:14klm5alsxg68zm0w4lzsyg6r6s5a63kizb44rg1ibsg692z1vj0";
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
