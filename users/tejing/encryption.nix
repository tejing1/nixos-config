{ ... }:

{
  programs.gpg.enable = true;
  programs.gpg.settings.default-key = "44A9 1F6C 152D ADE9 53BD  F9CE DE98 7C7E 445F 1961";
  services.gpg-agent.enable = true;
}
