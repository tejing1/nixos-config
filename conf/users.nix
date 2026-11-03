{
  perHost.nixos.cfg = { pkgs, ... }: {
    # Strictly definitional users, passwords, and groups
    users.mutableUsers = false;
  };
}
