{
  writeShellApplication,
  openconnect,
  rbw,
  ...
}:
writeShellApplication {
  name = "openconnect-epfl";
  runtimeInputs = [
    openconnect
    rbw
  ];
  text = ''
    RBW_ENTRY="EPFL Microsoft Auth"
    GASPAR_USER=$(rbw search --fields user "$RBW_ENTRY")
    GASPAR_PASSWORD=$(rbw get "$RBW_ENTRY")
    GASPAR_TOKEN=$(rbw code "$RBW_ENTRY")
    printf "%s\n" "$GASPAR_PASSWORD" "$GASPAR_TOKEN" | command sudo openconnect \
        --passwd-on-stdin \
        -u "$GASPAR_USER" \
        --useragent='AnyConnect' \
        "https://vpn.epfl.ch"
  '';
}
