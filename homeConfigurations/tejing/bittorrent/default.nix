{ config, lib, my, pkgs, ... }:

let
  inherit (lib) mkIf escapeShellArg;
  stateDir = "/mnt/persist/tejing/torrents";
  tmux_socket = "${stateDir}/tmux_socket";
  rpc_socket = "${stateDir}/rpc_socket";
  session_lock = "${stateDir}/session/rtorrent.lock";

  safely = my.lib.mkShellScript "safely" {
    inputs = [ pkgs.coreutils pkgs.diffutils ];
    execer = [ "cannot:${pkgs.diffutils}/bin/diff" ];
  } ./safely;
  construct_torrent = pkgs.writeScript "construct_torrent" "#!${
    (pkgs.python3.withPackages (ps: [ ps.fastbencode ])).interpreter
  }\n${
    builtins.readFile ./construct_torrent
  }";
  rtorrent-load = pkgs.writeScriptBin "rtorrent-load" "#!${
    pkgs.python3.interpreter
  }\n${
    builtins.readFile ./rtorrent-load
  }";
  rtorrent_config = pkgs.writeText "rtorrent_config.rc" ''
    # Configure command paths
    method.insert = cfg.cmd.bash,                 private|const|string,  "${pkgs.bash}/bin/bash"
    method.insert = cfg.cmd.mkdir,                private|const|string,  "${pkgs.coreutils}/bin/mkdir"
    method.insert = cfg.cmd.cp,                   private|const|string,  "${pkgs.coreutils}/bin/cp"
    method.insert = cfg.cmd.rm,                   private|const|string,  "${pkgs.coreutils}/bin/rm"
    method.insert = cfg.cmd.natpmpc,              private|const|string,  "${pkgs.libnatpmp}/bin/natpmpc"
    method.insert = cfg.cmd.dig,                  private|const|string,  "${pkgs.dnsutils}/bin/dig"
    method.insert = cfg.cmd.safely,               private|const|string,  "${safely}"
    method.insert = cfg.cmd.construct_torrent,    private|const|string,  "${construct_torrent}"

    # Configure directory paths
    method.insert = cfg.path.session,             private|const|string,  "${stateDir}/session"
    method.insert = cfg.path.logdir,              private|const|string,  "${stateDir}/log"
    method.insert = cfg.path.active,              private|const|string,  "${stateDir}/download"
    method.insert = cfg.path.completed,           private|const|string,  "${config.home.homeDirectory}/data"
    method.insert = cfg.path.magnetinfo,          private|const|string,  "${stateDir}/magnet"
    method.insert = cfg.path.torrentfiles,        private|const|string,  "${stateDir}/torrentfiles"

    # Configure file paths
    method.insert = cfg.path.rpc_socket,          private|const|string,  "${rpc_socket}"

    # Configure ports
    method.insert = cfg.port.tcp,                 private|const|string,  "62813"
    method.insert = cfg.port.udp,                 private|const|string,  "62813"

    # Configure process umask
    method.insert = cfg.umask,                    private|const|string,  "0022"

    # Nominal upload and download rates for my connection in mbps
    method.insert = cfg.connection.up_mbps,       private|const|string,  "10"
    method.insert = cfg.connection.down_mbps,     private|const|string,  "400"

    # Percentage of nominal rates to use
    method.insert = cfg.connection.up_percent,    private|const|string,  "80"
    method.insert = cfg.connection.down_percent,  private|const|string,  "80"
  '';
  start_rtorrent = my.lib.mkShellScript "start-rtorrent" {
    inputs = [ pkgs.rtorrent ];
    execer = [ "cannot:${pkgs.rtorrent}/bin/rtorrent" ];
  } ''
    exec rtorrent -I -n -o import=${rtorrent_config} -o import=${./rtorrent.rc}
  '';

  clear_stale_lock = my.lib.mkShellScript "clear-stale-rtorrent-lock" {
    inputs = [ pkgs.coreutils pkgs.nettools ];
  } ''
    [[ -f ${escapeShellArg session_lock} ]] || exit 0
    [[ "$(< ${escapeShellArg session_lock})" =~ ([^:]+):\+([0-9]+) ]] || exit 0
    [[ "''${BASH_REMATCH[1]}" == "$(hostname)" ]] || exit 0
    [[ -d "/proc/''${BASH_REMATCH[2]}" ]] && [[ "$(basename "$(readlink "/proc/''${BASH_REMATCH[2]}/exe")")" == rtorrent ]] && exit 0
    rm -f -- ${escapeShellArg session_lock}
  '';

  tmux_config = builtins.toFile "rtorrent_tmux.conf" ''
  '';
  tmux_cmd = "tmux -S ${escapeShellArg tmux_socket} -f ${tmux_config}";

  start_daemon = my.lib.mkShellScript "start-rtorrent-daemon" {
    inputs = [ pkgs.tmux ];
    execer = [ "cannot:${pkgs.tmux}/bin/tmux" ]; # False, but I'm getting around it with explicit absolute paths
  } ''
    ${tmux_cmd} new-session -d -s rtorrent -n rtorrent -x 426 -y 118 ${start_rtorrent}
    ${tmux_cmd} display-message -p '#{pid}' > "$XDG_RUNTIME_DIR/rtorrent_tmux.pid"
  '';
  stop_daemon = my.lib.mkShellScript "stop-rtorrent-daemon" {
    inputs = [ pkgs.coreutils pkgs.tmux ];
    execer = [ "cannot:${pkgs.tmux}/bin/tmux" ]; # False, but doesn't matter here
  } ''
    ${tmux_cmd} send-keys -t rtorrent:rtorrent C-q
    while ${tmux_cmd} -N has-session; do
      sleep 0.5
    done
  '';

  rtorrent-attach = my.lib.mkShellScript "rtorrent-attach" {
    inputs = [ pkgs.tmux pkgs.systemd ];
    execer = [
      "cannot:${pkgs.systemd}/bin/systemctl"
      "cannot:${pkgs.tmux}/bin/tmux" # False, but doesn't matter here
    ];
  } ''
    if [ "$(systemctl --user show --property=ActiveState rtorrent.service)" == "ActiveState=active" ]; then
      exec ${tmux_cmd} attach-session
    else
      echo "rtorrent.service not active" >&2
      exit 1
    fi
  '';
in

{
  home.packages = [ rtorrent-attach.pkg rtorrent-load ];

  xdg.desktopEntries.rtorrent-load = {
    name = "RTorrent rpc torrent loader";
    comment = "Load a torrent into the running rtorrent instance.";
    exec = "${pkgs.writeShellScript "rtorrent-load-desktop-script" ''exec ${rtorrent-load}/bin/rtorrent-load -S ${escapeShellArg rpc_socket} "$@"''} %U";
    noDisplay = true;
    startupNotify = false;
    mimeType = [ "application/x-bittorrent" "x-scheme-handler/magnet" ];
  };

  systemd.user.services.rtorrent = mkIf (!my.isBuildVm) {
    Unit = {
      Description = "RTorrent bittorrent client";
      After = [ "network.target" ];
    };
    Install.WantedBy = [ "default.target" ];
    Service = {
      Type = "forking";
      PIDFile = "rtorrent_tmux.pid";
      ExecStartPre = "-${clear_stale_lock}";
      ExecStart = "${start_daemon}";
      ExecStop = "${stop_daemon}";
    };
  };

  xsession.windowManager.i3.config.assigns."10" = [{class = "^URxvt$";instance = "^rtorrent$";}];
  xsession.windowManager.i3.config.startup = [{ command = "${my.launch.term} app rtorrent ${pkgs.writeShellScript "rtorrent-cycle" (if my.isBuildVm then "echo In a virtual machine, not running rtorrent;while true;do sleep 3600;done" else "while true; do rtorrent-attach; sleep 1;done")}"; always = false; notification = false; }];
}
