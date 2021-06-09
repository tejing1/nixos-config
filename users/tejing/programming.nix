{ pkgs, ... }:

{
  # perhaps this should be left to individual development environments?
  home.packages = with pkgs; [
    git
    github-cli
    coq
    ruby
    ghc
  ];
}
