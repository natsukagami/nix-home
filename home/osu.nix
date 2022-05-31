{ pkgs, config, lib, ... }:

let
  # pkgsUnstableOsu = import "/home/nki/nixpkgs/osu-lazer" {};
  # osu = pkgs.osu-lazer.overrideAttrs (oldAttrs : rec {
  #     version = "2021.1006.1";
  #     src = pkgs.fetchFromGitHub {
  #         owner = "ppy";
  #         repo = "osu";
  #         rev = version;
  #         sha256 = "11qwrsp9kfxgz7dvh56mbgkry252ic3l5mgx3hwchrwzll71f0yd";
  #     };
  # });
in
{
  home.packages = [ pkgs.unstable.osu-lazer ];
}
