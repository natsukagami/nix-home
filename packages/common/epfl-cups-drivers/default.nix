{ pkgs, runCommand, ... }:
runCommand "epfl-cups-drivers" { } ''
  mkdir -p $out/share/cups/model
  cp ${./PPD-C5860-bw-EN.PPD} $out/share/cups/model
  cp ${./PPD-C5860-color-EN.PPD} $out/share/cups/model
''
