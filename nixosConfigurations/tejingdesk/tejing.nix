{ inputs, ... }:

{
  my.users.tejing = true;

  home-manager.users.tejing.imports = [ inputs.self.homeConfigurations.tejing.configurationModule ];

  # unlock gpg keys with my login password
  security.pam.services.login.gnupg.enable = true;
  security.pam.services.login.gnupg.noAutostart = true;
  security.pam.services.login.gnupg.storeOnly = true;
  security.pam.services.lightdm-greeter.gnupg.enable = true;
  security.pam.services.lightdm-greeter.gnupg.noAutostart = true;
  security.pam.services.lightdm-greeter.gnupg.storeOnly = true;
  security.pam.services.i3lock.gnupg.enable = true;
  security.pam.services.i3lock.gnupg.noAutostart = true;

  # Enable touchpad support.
  # I actually just need this for the mouse acceleration settings that I'm used to.
  services.xserver.libinput.enable = true;
  services.xserver.libinput.mouse.accelSpeed = "0.6";

  programs.dconf.enable = true;

  systemd.tmpfiles.rules = [ "d /mnt/persist/tejing 0755 tejing users - -" ];

  # Start urxvtd with user sessions
  services.urxvtd.enable = true;

  # rtorrent peer & dht ports
  networking.firewall.allowedTCPPorts = [ 62813 ];
  networking.firewall.allowedUDPPorts = [ 62813 ];
}
