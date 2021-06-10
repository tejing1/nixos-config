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
  programs.git.signing.key = "963D 3AFB 8AA4 D693 153C  1500 46E9 6F6F F44F 3D74";
  programs.git.signing.signByDefault = true;
  programs.git.extraConfig.tag.gpgSign = true;
  programs.git.extraConfig.push.gpgSign = "if-asked";
}
