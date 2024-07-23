{
  # TODO: Edit the list of hosts here.
  cloud = {
    subnetAddr = "11.0.0.1";
    address = "nki.personal";
    rsaPublicKey = builtins.readFile ./nki-cloud.pub;
    ed25519PublicKey = "fZi75omD1Z2vZYH7FleZ+ygKLqGj2emlLMvw3XcmZPM";
  };

  home = {
    subnetAddr = "11.0.0.2";
    rsaPublicKey = builtins.readFile ./nki-home.pub;
    ed25519PublicKey = "Ts5OdPtBNLIRfosoYRcb6Z2iwWyOz/VKTKB9J0p5LlH";
  };
}
