{ config, pkgs, my, ... }:

{
  home.packages = with pkgs; [
    mpc_cli
    ncmpc
    pavucontrol
  ];
  xsession.windowManager.i3.config.keybindings = let
    mod = config.xsession.windowManager.i3.config.modifier;
  in {
    "${mod}+F1" = "exec --no-startup-id ${pkgs.mpc_cli}/bin/mpc prev";
    "${mod}+F2" = "exec --no-startup-id ${pkgs.mpc_cli}/bin/mpc toggle";
    "${mod}+F3" = "exec --no-startup-id ${pkgs.mpc_cli}/bin/mpc stop";
    "${mod}+F4" = "exec --no-startup-id ${pkgs.mpc_cli}/bin/mpc next";
    "${mod}+F5" = "exec --no-startup-id ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -5%";
    "${mod}+F6" = "exec --no-startup-id ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +5%";
    "${mod}+F7" = "exec --no-startup-id ${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle";
  };
  xsession.windowManager.i3.config.assigns."9" = [{class = "^URxvt$";instance = "^ncmpc$";}];
  xsession.windowManager.i3.config.startup = [{ command = "${my.scripts.mylaunchterm} app ncmpc ${pkgs.ncmpc}/bin/ncmpc"; always = false; notification = false; }];

  services.mpd.enable = true;
  services.mpd.network.startWhenNeeded = true;
  services.mpd.dataDir = "/mnt/persist/tejing/mpd";
  services.mpd.musicDirectory = pkgs.runCommand "music-lib" {} ''
      mkdir $out
      ln -s /mnt/persist/share/unique/music $out
      ln -s /mnt/persist/share/replaceable/ocremix $out
      ln -s /mnt/persist/share/unique/unsorted_music $out
      ln -s /mnt/persist/share/data/tejing/work/youtube_favorite_music $out
    '';
  services.mpd.extraConfig = ''
                audio_output {
                       type     "pulse"
                       name     "pulseaudio"
                }'';
  home.file.".config/ncmpc/config".text = ''
    host = 127.0.0.1
    port = 6600
    enable-colors = yes
    color background             = none
    color title                  = none,dim/none
    color title-bold             = cyan/none
    color line                   = blue/none
    color line-flags             = green/none
    color list                   = none,dim/none
    color list-bold              = cyan/none
    color browser-directory      = cyan,dim/none
    color browser-playlist       = magenta,dim/none
    color progressbar            = cyan/none
    color progressbar-background = blue,dim/none
    color status-state           = green/none
    color status-song            = none,dim/none
    color status-time            = green/none
    color alert                  = magenta/none
  '';
}
