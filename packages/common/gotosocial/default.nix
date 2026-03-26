{
  gotosocial,
  buildGoModule,
  fetchurl,
  fetchzip,
  ...
}:
(gotosocial.override { buildGo124Module = buildGoModule; }).overrideAttrs (
  finalAttrs: prevAttrs: {
    pname = "gotosocial-dtth";
    version = "0.21.2";
    ldflags = [
      "-s"
      "-w"
      "-X main.Version=${finalAttrs.version}"
    ];
    doCheck = false;
    web-assets = fetchurl {
      url = "https://codeberg.org/superseriousbusiness/gotosocial/releases/download/v${finalAttrs.version}/gotosocial_${finalAttrs.version}_web-assets.tar.gz";
      hash = "sha256-mCRyhNZ+3ZxdxPCxKxHUaA7/ml/UeUP88FlR+jKSyXM=";
    };
    src = fetchzip {
      url = "https://codeberg.org/superseriousbusiness/gotosocial/releases/download/v${finalAttrs.version}/gotosocial-${finalAttrs.version}-source-code.tar.gz";
      hash = "sha256-Z3j5/pXnNTHgBmPEfFgjOJuL03LsPtvAwbuoL9wb5bk=";
      stripRoot = false;
    };
    postInstall = ''
      tar xf ${finalAttrs.web-assets}
      mkdir -p $out/share/gotosocial
      mv web $out/share/gotosocial/
    '';
  }
)
