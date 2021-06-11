{ pkgs, ... }:

{
  home.packages = with pkgs; [
    github-cli
    coq
    # perhaps this should be left to individual development environments?
    ruby
    ghc
  ];
  programs.git.enable = true;
  programs.git.userName = "Jeff Huffman";
  programs.git.userEmail = "tejing@tejing.com";
  programs.git.ignores = [ "*~" ".#*" "\\#*#" ];
  programs.git.signing.key = "963D3AFB8AA4D693153C150046E96F6FF44F3D74";
  programs.git.signing.signByDefault = true;
  programs.git.extraConfig.tag.gpgSign = true;
}
