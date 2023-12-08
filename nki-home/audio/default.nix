{ config, pkgs, lib, ... }: {
  environment.etc = {
    "wireplumber/main.lua.d/51-sdac.lua".source = ./sdac.lua;
  };
}
