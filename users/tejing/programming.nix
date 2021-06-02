{ pkgs, ... }:

{
  # perhaps this should be left to individual development environments?
  home.packages = with pkgs; [
    coq
    ruby
    ghc
  ];
}
