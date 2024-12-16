{ my, pkgs, ... }:

{
  home.packages = builtins.attrValues {
    inherit (pkgs)
      github-cli
      git-absorb
      nixpkgs-review
      coq
      # perhaps this should be left to individual development environments?
      ruby
      ghc
      kalker
    ;
  };

  programs.git = {
    enable = true;
    userName = "Jeff Huffman";
    userEmail = "tejing@tejing.com";
    ignores = [ "*~" ".#*" "\\#*#" ];
    signing.key = "963D3AFB8AA4D693153C150046E96F6FF44F3D74";
    signing.signByDefault = true;
    extraConfig = {
      tag.gpgSign = true;
      gcrypt.publish-participants = true;
      gcrypt.participants = "963D3AFB8AA4D693153C150046E96F6FF44F3D74";
      gcrypt.gpg-args = "--quiet";
      init.defaultBranch = "master";
      push.default = "current";
      push.autosetupremote = true;
      branch.autosetupmerge = "simple";
      advice.detachedHead = false;
      checkout.guess = false;
    };
  };

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  # Retain build deps for building my moonlander firmware
  xdg.configFile.".moonlander-firmware-buildTools".source = my.pkgs.moonlander-firmware.buildTools;
}
