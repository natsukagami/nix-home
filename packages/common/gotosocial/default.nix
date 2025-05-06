{
  gotosocial,
  fetchurl,
  fetchgit,
  ...
}:
gotosocial.overrideAttrs (
  finalAttrs: prevAttrs: {
    pname = "gotosocial-dtth";
    version = "0.19.1";
    ldflags = [
      "-s"
      "-w"
      "-X main.Version=${finalAttrs.version}"
    ];
    doCheck = false;
    web-assets = fetchurl {
      url = "https://codeberg.org/superseriousbusiness/gotosocial/releases/download/v${finalAttrs.version}/gotosocial_${finalAttrs.version}_web-assets.tar.gz";
      hash = "sha256-UtxFm8ZSpIGXruBdanSF1lkA7Gs1FJNhoqzDTqSNYUM=";
    };
    src = fetchgit {
      url = "https://codeberg.org/superseriousbusiness/gotosocial.git";
      rev = "v${finalAttrs.version}";
      hash = "sha256-RhJRdRxTdbZwIAGD3gH0mjDfCvdS7xkRxcUd1ArsNoo=";
    };
  }
)
