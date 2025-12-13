{
  gotosocial,
  fetchurl,
  fetchzip,
  ...
}:
gotosocial.overrideAttrs (
  finalAttrs: prevAttrs: {
    pname = "gotosocial-dtth";
    version = "0.20.2";
    ldflags = [
      "-s"
      "-w"
      "-X main.Version=${finalAttrs.version}"
    ];
    doCheck = false;
    web-assets = fetchurl {
      url = "https://codeberg.org/superseriousbusiness/gotosocial/releases/download/v${finalAttrs.version}/gotosocial_${finalAttrs.version}_web-assets.tar.gz";
      hash = "sha256-85tFn3LsuMbLoiH6FFtBK60GhclfTsSiI7K/iNLadjY=";
    };
    src = fetchzip {
      url = "https://codeberg.org/superseriousbusiness/gotosocial/releases/download/v${finalAttrs.version}/gotosocial-${finalAttrs.version}-source-code.tar.gz";
      hash = "sha256-H5+1BZ1jIISU6EPszIuOhqowoMe9WF36BGwV7TpAqj8=";
      stripRoot = false;
    };
    postInstall = ''
      tar xf ${finalAttrs.web-assets}
      mkdir -p $out/share/gotosocial
      mv web $out/share/gotosocial/
    '';
  }
)
