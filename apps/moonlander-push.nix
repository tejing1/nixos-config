{
  perSystem = { pkgs, self', ... }: let
    inherit (pkgs) wally-cli writeShellScript;
  in {
    apps.moonlander-push = {
      type = "app";
      meta.description = "Build and flash my custom moonlander firmware to the actual hardware.";
      program = "${writeShellScript "moonlander-push" ''
        sudo ${wally-cli}/bin/wally-cli ${self'.packages.moonlander-firmware}
      ''}";
    };
  };
}
