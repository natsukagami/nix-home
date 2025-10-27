{
  gotosocial,
  fetchurl,
  fetchzip,
  ...
}:
gotosocial.overrideAttrs (
  finalAttrs: prevAttrs: {
    pname = "gotosocial-dtth";
    version = "0.20.1";
    ldflags = [
      "-s"
      "-w"
      "-X main.Version=${finalAttrs.version}"
    ];
    doCheck = false;
    web-assets = fetchurl {
      url = "https://codeberg.org/superseriousbusiness/gotosocial/releases/download/v${finalAttrs.version}/gotosocial_${finalAttrs.version}_web-assets.tar.gz";
      hash = "sha256-0WvaPUVTMYd1tz7Rtmlp37vx/co4efhDdSWBc4gUzAU=";
    };
    src = fetchzip {
      url = "https://codeberg.org/superseriousbusiness/gotosocial/releases/download/v${finalAttrs.version}/gotosocial-${finalAttrs.version}-source-code.tar.gz";
      hash = "sha256-8z2tBiEVcof0/G41gpc0S8Dye5nynwHSJpTzo/ZseFs=";
      stripRoot = false;
    };
    postInstall = ''
      tar xf ${finalAttrs.web-assets}
      mkdir -p $out/share/gotosocial
      mv web $out/share/gotosocial/
    '';
  }
)
