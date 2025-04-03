{
  cloud = {
    host = "cloud.tinc";
    pubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE87ddj0fTH0NuvJz0dT5ln7v7zbafXqDVdM2A4ddOb0 root@nki-personal-do";
  };

  home = {
    host = "home.tinc";
    pubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIK6N1uTxnbo73tyzD9X7d7OgPeoOpY7JmQaHASjSWFPI nki@kagamiPC";

    builder = {
      publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUhiVTh2NlNBa0kyOTBCc1QzVG1IRVVJQWdXcVFyNm9jRmpjakRRczRoT2ggcm9vdEBrYWdhbWlQQwo=";
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      maxJobs = 16;
      speedFactor = 2;
      supportedFeatures = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
      ];
    };
  };

  yoga = {
    host = "yoga.tinc";
    pubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIE6ZrO/xIdmwBCUx80cscBSpJBBTp55OHGrXYBGRXKAw nki@nki-yoga-g8";
  };

  framework = {
    host = "framework.tinc";
    pubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIH/g472MaT7YySUhBjxClfmMjpn98qYnKXDKlzWHYwuO nki@nki-framework";

    builder = {
      publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUdOUlBCVFRkNTVVMXY1U1Jac0FjYVdhS3JGZTY0ZjIxOVViODVTQ2NWd28gcm9vdEBua2ktZnJhbWV3b3JrCg==";
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      maxJobs = 16;
      speedFactor = 3;
      supportedFeatures = [
        "nixos-test"
        "benchmark"
        "big-parallel"
        "kvm"
      ];
    };
  };
}
