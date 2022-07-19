{ pkgs, ... }:

{
  services.deluge.enable = true;
  services.deluge.package = pkgs.deluge-2_x;
  services.deluge.declarative = true;
  services.deluge.openFirewall = true;
  services.deluge.dataDir = "/mnt/persist/torrents";
  services.deluge.config = {
    add_paused = true;
    download_location = "/mnt/persist/torrents/download";
    move_completed = true;
    move_completed_path = "/mnt/persist/torrents/complete";
    copy_torrent_file = true;
    torrentfiles_location = "/mnt/persist/torrents/torrentfiles";
    stop_seed_at_ratio = true;
    stop_seed_ratio = 2.0;
    max_download_speed = 21817.625;
    max_upload_speed = 723.875;
  };

  # No remote connections, and it's not a high-security service... good enough.
  services.deluge.authFile = builtins.toFile "deluge-auth" "tejing:password:10";
}
