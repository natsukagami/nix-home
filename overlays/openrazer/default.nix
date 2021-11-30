final: prev:
let
  src = final.fetchFromGitHub {
    owner = "natsukagami";
    repo = "openrazer";
    rev = "28cd304e0389d26ded2a274b0f9ecd2debf057a0";
    sha256 = "sha256-8vCR8/eZq0z0+K1vajjt9wDcV/2QwX9JJh9usWAEvBg=";
  };
in rec
{
  openrazer-daemon = prev.openrazer-daemon.overrideAttrs (old: {
    inherit src;
  });

  python3 = prev.python3.override {
    packageOverrides = self: super: {
      openrazer-daemon = super.openrazer-daemon.overrideAttrs (old: {
        inherit src;
      });
    };
  };
  python3Packages = python3.pkgs;

  linuxPackages = prev.linuxPackages.extend (self: super: {
    openrazer = super.openrazer.overrideAttrs (old: {
      inherit src;
    });
  });
}
