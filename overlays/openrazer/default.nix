final: prev:
let
  version = "3.3.0";
  src = final.fetchFromGitHub {
    owner = "openrazer";
    repo = "openrazer";
    rev = "v${version}";
    sha256 = "sha256-lElE1nIiJ5fk2DupHu43tmxRjRsS5xeL1Yz/LuRlgtM=";
  };
in
rec
{
  openrazer-daemon = prev.openrazer-daemon.overrideAttrs (old: {
    inherit src version;
  });

  python3 = prev.python3.override {
    packageOverrides = self: super: {
      openrazer-daemon = super.openrazer-daemon.overrideAttrs (old: {
        inherit src version;
      });
    };
  };
  python3Packages = python3.pkgs;

  linuxPackages_latest = prev.linuxPackages_latest.extend (self: super: {
    openrazer = super.openrazer.overrideAttrs (old: {
      inherit src version;
    });
  });
}
