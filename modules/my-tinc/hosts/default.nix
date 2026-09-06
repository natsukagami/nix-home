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

  yoga = {
    subnetAddr = "11.0.0.5";
    ed25519PublicKey = "n+gIZjuuTPxi0OBqw2oOcmXd3loOHG+GQHBMXNlgyqI";
  };

  framework = {
    subnetAddr = "11.0.0.6";
    ed25519PublicKey = "14sM4PG4vXbFr5gLWxnkjUnO7SjL1GvoJ+VolCoaQsM";
  };
}
