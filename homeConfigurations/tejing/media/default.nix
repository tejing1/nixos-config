{ pkgs, my, ... }:

{
  home.packages = builtins.attrValues {
    inherit (pkgs)
      fbreader
      feh
      youtube-dl
      mkvtoolnix
      ffmpeg
    ;
    yt-dlp = my.lib.templateScriptBin pkgs "yt-dlp" ./yt-dlp.sh;
  };
  programs.mpv.enable = true;
  programs.mpv.config = {
    osc = false;
    hwdec = "auto-safe";
  };
}
