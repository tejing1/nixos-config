{ ... }:

{
  programs.gpg.enable = true;
  programs.gpg.settings.default-key = "963D 3AFB 8AA4 D693 153C  1500 46E9 6F6F F44F 3D74";
  programs.gpg.settings.default-recipient-self = true;
  services.gpg-agent.enable = true;
}
