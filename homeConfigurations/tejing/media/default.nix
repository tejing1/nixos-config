{ pkgs, my, ... }:

{
  home.packages = builtins.attrValues {
    inherit (pkgs)
      zathura
      feh
      mkvtoolnix
      ffmpeg
    ;
    yt-dlp = (my.lib.mkShellScript "yt-dlp" {
      inputs = builtins.attrValues {
        inherit (pkgs) coreutils curl nix-prefetch-github jq nix;
      };
      execer = [
        "cannot:${pkgs.nix}/bin/nix"
        "cannot:${pkgs.nix-prefetch-github}/bin/nix-prefetch-github"
      ];
    } (builtins.readFile ./yt-dlp)).pkg;
  };
  programs.mpv.enable = true;
  programs.mpv.config = {
    osc = false;
    hwdec = "auto-safe";
    script-opts = "ytdl_hook-ytdl_path=/etc/profiles/per-user/tejing/bin/yt-dlp";
    demuxer-max-bytes = "500MiB";
    demuxer-max-back-bytes = "250MiB";
    ytdl-format = "bv[height<=1440]+ba/best[height<=1440]/bestvideo+bestaudio/best";
    subs-fallback = "default";
    audio-display = false;
  };
}
