{ pkgs, my, ... }:

{
  home.packages = builtins.attrValues {
    inherit (pkgs)
      zathura
      feh
      youtube-dl
      mkvtoolnix
      ffmpeg
    ;
    yt-dlp = (my.lib.mkShellScript "yt-dlp" {
      inputs = builtins.attrValues {
        inherit (pkgs) coreutils curl sfeed jq nix;
      };
      execer = [ "cannot:${pkgs.nix}/bin/nix" ];
    } (builtins.readFile ./yt-dlp)).pkg;
  };
  programs.mpv.enable = true;
  programs.mpv.config = {
    osc = false;
    hwdec = "auto-safe";
  };
}
