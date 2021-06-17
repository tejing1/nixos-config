{ pkgs, ... }:

let m = 60; h = 60*m; d = 24*h; in
{
  home.packages = with pkgs; [
    git-remote-gcrypt
  ];
  programs.gpg.enable = true;
  programs.gpg.settings = {
    default-key = "963D 3AFB 8AA4 D693 153C  1500 46E9 6F6F F44F 3D74";
    default-recipient-self = true;
    auto-key-locate = "local,wkd,keyserver";
    keyserver = "hkps://keys.openpgp.org";
    auto-key-retrieve = true;
    auto-key-import = true;
    keyserver-options = "honor-keyserver-url";
  };
  services.gpg-agent =
      {
        enable = true;
        enableSshSupport = true;
        defaultCacheTtl = 6*h;
        defaultCacheTtlSsh = 6*h;
        maxCacheTtl = 1*d;
        maxCacheTtlSsh = 1*d;
        sshKeys = [ "0B9AF8FB49262BBE699A9ED715A7177702D9E640" ];
      };
  programs.password-store.enable = true;
  programs.password-store.package = pkgs.pass.withExtensions (e: [ e.pass-otp e.pass-import ]);
  programs.password-store.settings = {
    PASSWORD_STORE_SIGNING_KEY = "963D3AFB8AA4D693153C150046E96F6FF44F3D74";
    PASSWORD_STORE_X_SELECTION = "primary";
  };
}
