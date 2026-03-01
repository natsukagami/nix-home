{
  gotosocial,
  fetchurl,
  fetchzip,
  ...
}:
gotosocial.overrideAttrs (
  finalAttrs: prevAttrs: {
    pname = "gotosocial-dtth";
    version = "0.21.0";
    ldflags = [
      "-s"
      "-w"
      "-X main.Version=${finalAttrs.version}"
    ];
    doCheck = false;
    web-assets = fetchurl {
      url = "https://codeberg.org/superseriousbusiness/gotosocial/releases/download/v${finalAttrs.version}/gotosocial_${finalAttrs.version}_web-assets.tar.gz";
      hash = "sha256-eExVquNTXkvxg0SAR60kXi5mnROp+tHNO3os1K+rWzU=";
    };
    src = fetchzip {
      url = "https://codeberg.org/superseriousbusiness/gotosocial/releases/download/v${finalAttrs.version}/gotosocial-${finalAttrs.version}-source-code.tar.gz";
      hash = "sha256-ifSm3tV8P435v7WUS2BYXfVS3FHu9Axz3IQWGdTw3Bg=";
      stripRoot = false;
    };
    postInstall = ''
      tar xf ${finalAttrs.web-assets}
      mkdir -p $out/share/gotosocial
      mv web $out/share/gotosocial/
    '';
  }
)
