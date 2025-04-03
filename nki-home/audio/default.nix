{
  config,
  pkgs,
  lib,
  ...
}:
{
  environment.etc = {
    "wireplumber/wireplumber.conf.d/51-sdac.conf".source = ./sdac.conf.json;
  };
}
