{
  # TODO: Edit the list of hosts here.
  cloud = {
    subnetAddr = "11.0.0.1";
    address = "nki.personal";
    rsaPublicKey = builtins.readFile ./nki-cloud.pub;
  };

  macbook = {
    subnetAddr = "11.0.0.3";
    rsaPublicKey = builtins.readFile ./nki-macbook.pub;
    ed25519PublicKey = "lkNkBTl5GmcQFrtA7F1nN2gq5gFK7KuGqHUN8fiJU7H";
  };
}
