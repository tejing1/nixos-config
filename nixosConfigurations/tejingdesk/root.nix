{ config, lib, my, ... }:
let
  inherit (lib) mkIf;
  inherit (my.lib) readSecret;
in

{
  users.users.root = {
    password = mkIf (config.users.users.root.hashedPassword == null) "password"; # Fallback for locked build
    hashedPassword = readSecret null ./pwhash.secret;
  };
}
