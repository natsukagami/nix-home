{
  # TODO: Edit the list of hosts here.
  cloud = {
    subnetAddr = "11.0.0.1";
    address = "nki.personal";
    rsaPublicKey = builtins.readFile ./nki-cloud.pub;
  };

  home = {
    subnetAddr = "11.0.0.2";
    rsaPublicKey = builtins.readFile ./nki-home.pub;
    ed25519PublicKey = "Ts5OdPtBNLIRfosoYRcb6Z2iwWyOz/VKTKB9J0p5LlH";
  };

  macbook = {
    subnetAddr = "11.0.0.3";
    rsaPublicKey = builtins.readFile ./nki-macbook.pub;
    ed25519PublicKey = "lkNkBTl5GmcQFrtA7F1nN2gq5gFK7KuGqHUN8fiJU7H";
  };
  macbook-nixos = {
    subnetAddr = "11.0.0.4";
    ed25519PublicKey = "6MN5LVE4juavv8qJW2dTN4t/haKCADWquAQj/ADF7iN";
  };
}
