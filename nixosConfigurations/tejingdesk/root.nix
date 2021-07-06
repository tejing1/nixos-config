{ ... }:

{
  users.users.root.hashedPassword = builtins.readFile ./pwhash.secret;
}
