{ nodejs, importNpmLock }:
importNpmLock.buildNodeModules {
  inherit nodejs;
  npmRoot = ./.;
}
