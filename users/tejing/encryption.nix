{ ... }:

{
  programs.gpg.enable = true;
  programs.gpg.settings.default-key = "963D 3AFB 8AA4 D693 153C  1500 46E9 6F6F F44F 3D74";
  programs.gpg.settings.default-recipient-self = true;
  services.gpg-agent =
    let
      mins = 60;
      hours = 60*mins;
      days = 24*hours;
    in
      {
        enable = true;
        enableSshSupport = true;
        defaultCacheTtl = 6*hours;
        defaultCacheTtlSsh = 6*hours;
        maxCacheTtl = 1*days;
        maxCacheTtlSsh = 1*days;
        sshKeys = [ "0B9AF8FB49262BBE699A9ED715A7177702D9E640" ];
      };
}
