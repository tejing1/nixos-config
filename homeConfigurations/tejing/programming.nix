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
    ;
  };
  programs.git.enable = true;
  programs.git.userName = "Jeff Huffman";
  programs.git.userEmail = "tejing@tejing.com";
  programs.git.ignores = [ "*~" ".#*" "\\#*#" ];
  programs.git.signing.key = "963D3AFB8AA4D693153C150046E96F6FF44F3D74";
  programs.git.signing.signByDefault = true;
  programs.git.extraConfig.tag.gpgSign = true;
  programs.git.extraConfig.gcrypt.publish-participants = true;
  programs.git.extraConfig.gcrypt.participants = "963D3AFB8AA4D693153C150046E96F6FF44F3D74";
  programs.git.extraConfig.gcrypt.gpg-args = "--quiet";

  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  # Retain build deps for building my moonlander firmware
  xdg.configFile.".moonlander-firmware-buildTools".source = my.pkgs.moonlander-firmware.buildTools;
}
