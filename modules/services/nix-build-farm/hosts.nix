{
  home = {
    host = "home.tinc";
    pubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK6N1uTxnbo73tyzD9X7d7OgPeoOpY7JmQaHASjSWFPI nki@kagamiPC";

    builder = {
      publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUhiVTh2NlNBa0kyOTBCc1QzVG1IRVVJQWdXcVFyNm9jRmpjakRRczRoT2ggcm9vdEBrYWdhbWlQQwo=";
      systems = [ "x86_64-linux" "aarch64-linux" ];
      maxJobs = 16;
      speedFactor = 2;
      supportedFeatures = [ "nixos-test" "benchmark" "big-parallel" "kvm" ];
    };
  };

  yoga = {
    host = "yoga.tinc";
    pubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE6ZrO/xIdmwBCUx80cscBSpJBBTp55OHGrXYBGRXKAw nki@nki-yoga-g8";
  };
}
