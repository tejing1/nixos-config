{ ... }:

{
  services.openssh.enable = true;
  services.openssh.permitRootLogin = "no";
  services.openssh.passwordAuthentication = false;
  services.openssh.hostKeys = [
    { type = "rsa"; bits = 4096; path = "/mnt/persist/tejingdesk/ssh_host_keys/ssh_host_rsa_key"; }
    { type = "ed25519";          path = "/mnt/persist/tejingdesk/ssh_host_keys/ssh_host_ed25519_key"; }
  ];
}
