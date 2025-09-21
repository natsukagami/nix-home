{
  gotosocial,
  fetchurl,
  fetchzip,
  ...
}:
gotosocial.overrideAttrs (
  finalAttrs: prevAttrs: {
    pname = "gotosocial-dtth";
    version = "0.20.0-rc1";
    ldflags = [
      "-s"
      "-w"
      "-X main.Version=${finalAttrs.version}"
    ];
    doCheck = false;
    web-assets = fetchurl {
      url = "https://codeberg.org/superseriousbusiness/gotosocial/releases/download/v${finalAttrs.version}/gotosocial_${finalAttrs.version}_web-assets.tar.gz";
      hash = "sha256-yl4sGB4o+hdfYcbl1LViBDJ8Sn/BKFe43c41JfhXylg=";
    };
    src = fetchzip {
      url = "https://codeberg.org/superseriousbusiness/gotosocial/releases/download/v${finalAttrs.version}/gotosocial-${finalAttrs.version}-source-code.tar.gz";
      hash = "sha256-adB+zHXhfUJwMg606GYTkDMPxHExJSk6N6h/uB13KQ0=";
      stripRoot = false;
    };
    postInstall = ''
      tar xf ${finalAttrs.web-assets}
      mkdir -p $out/share/gotosocial
      mv web $out/share/gotosocial/
    '';
  }
)
