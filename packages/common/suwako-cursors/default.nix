{ runCommandLocal, unzip }:
runCommandLocal "suwako-cursors" { } ''
  mkdir -p $out/share/icons
  ${unzip}/bin/unzip ${./Suwako.zip} -d $out/share/icons
''

