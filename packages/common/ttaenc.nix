{ stdenv, lib }:
stdenv.mkDerivation rec {
  name = "ttaenc";
  version = "3.4.1";

  src = builtins.fetchTarball {
    url = "http://downloads.sourceforge.net/tta/${name}-${version}-src.tgz";
    sha256 = "sha256:09yg0564wah1r6h9c5948sr7pw89aszwvl1rq6pdkm54yn05myqv";
  };

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    make install INSDIR="$out/bin"
    # Copy docs
    install -dm755 "$out/share/doc/${name}"
    install -m644 "ChangeLog-${version}" README "$out/share/doc/${name}"

    runHook postInstall
  '';
}
