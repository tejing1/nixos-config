{ config, pkgs, ... }:

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
	  "${mod}+F5" = "exec --no-startup-id ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ -5% && ${pkgs.killall}/bin/killall -SIGUSR1 i3status";
	  "${mod}+F6" = "exec --no-startup-id ${pkgs.pulseaudio}/bin/pactl set-sink-volume @DEFAULT_SINK@ +5% && ${pkgs.killall}/bin/killall -SIGUSR1 i3status";
	  "${mod}+F7" = "exec --no-startup-id ${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle && ${pkgs.killall}/bin/killall -SIGUSR1 i3status";
  };
  xsession.windowManager.i3.config.assigns."9" = [{class = "^URxvt$";instance = "^ncmpc$";}];
  xsession.windowManager.i3.config.startup = [{ command = "${pkgs.rxvt-unicode}/bin/urxvtc -name ncmpc -e ncmpc"; always = false; notification = false; }];

  services.mpd.enable = true;
  services.mpd.network.startWhenNeeded = true;
  services.mpd.dataDir = "/mnt/persist/tejing/mpd";
  services.mpd.musicDirectory = "/mnt/persist/share/replaceable/music_database";
  services.mpd.extraConfig = ''
                audio_output {
                       type     "pulse"
                       name     "pulseaudio"
                }'';
}
