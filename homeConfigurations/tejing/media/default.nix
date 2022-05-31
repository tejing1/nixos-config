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
    yt-dlp = pkgs.resholve.writeScriptBin "yt-dlp" {
      interpreter = "${pkgs.bash}/bin/bash";
      inputs = builtins.attrValues {
        inherit (pkgs) coreutils curl sfeed jq nix;
      };
      execer = [ "cannot:${pkgs.nix}/bin/nix" ];
    } (builtins.readFile ./yt-dlp);
  };
  programs.mpv.enable = true;
  programs.mpv.config = {
    osc = false;
    hwdec = "auto-safe";
  };
}
