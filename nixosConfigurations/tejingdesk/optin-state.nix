{ config, lib, my, pkgs, ... }:

lib.mkIf (! my.isBuildVm) {
  # Don't bother with the lecture or the need to keep state about who's been lectured
  security.sudo.extraConfig = "Defaults lecture=\"never\"";

  # point nixos-rebuild at my flake
  environment.etc."nixos/flake.nix".source = "/mnt/persist/tejing/flake/flake.nix";

  # switch-to-configuration refuses to operate without this tag
  environment.etc.NIXOS.text = "";

  # set machine id
  environment.etc.machine-id = lib.mkIf (! my.lib.isRepoLocked) {
    source = ./machine-id.secret;
    mode = "0644";
  };

  # keep hardware clock adjustment data
  environment.etc.adjtime.source = "/mnt/cache/tejingdesk/adjtime";

  # prevent tmpfiles.d warning about /var/log not being a symlink
  environment.etc."tmpfiles.d/var.conf".source = pkgs.runCommand "var.conf" { inputs = [ pkgs.gnused ]; } ''
    sed -e 's:^[^ ]\+ /var/log .\+$:L /var/log - - - - /mnt/cache/tejingdesk/logs:' ${config.systemd.package}/example/tmpfiles.d/var.conf > $out
  '';

  # just before mounting, create empty subvolume where nixos' mounting code expects it
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    # wait for device to show up
    waitDevice ${config.fileSystems."/".device}

    # temporarily mount subvolume '/' of lvm/cache
    mkdir -p /mnt
    mount -o subvol=/ ${config.fileSystems."/".device} /mnt

    # do something sensible with leftover root subvolume, if present
    if [ -e /mnt/tejingdesk/root/new ]; then
        mv /mnt/tejingdesk/root/new /mnt/tejingdesk/root/root-$(($(ls /mnt/tejingdesk/root/ | grep -Eo '[0-9]+$' | sort -n | tail -n 1 ) + 1))
    fi

    # create new root subvolume
    btrfs subvolume create /mnt/tejingdesk/root/new

    # unmount temporary mount of subvolume '/'
    umount /mnt
    rmdir /mnt
  '';

  # just after mounting, move the mounted subvolume to a unique name and setup any early redirects
  boot.initrd.postMountCommands = lib.mkBefore ''
    # move new subvolume to unique name
    mv $targetRoot/mnt/cache/tejingdesk/root/new $targetRoot/mnt/cache/tejingdesk/root/root-$(($(ls $targetRoot/mnt/cache/tejingdesk/root/ | grep -Eo '[0-9]+$' | sort -n | tail -n 1 ) + 1))

    # create needed directories
    mkdir -p $targetRoot/var/lib/systemd/timesync

    # link state that's needed before tmpfiles.d is up and running
    ln -snfT /mnt/cache/tejingdesk/logs $targetRoot/var/log
    ln -snfT /mnt/persist/tejingdesk/nixos_id_maps $targetRoot/var/lib/nixos
    ln -snfT /mnt/cache/tejingdesk/systemd/random-seed $targetRoot/var/lib/systemd/random-seed
    ln -snfT /mnt/cache/tejingdesk/systemd/timers $targetRoot/var/lib/systemd/timers

    # needs to be a bind mount because the activation script reacts to symlinks
    mount -o bind $targetRoot/mnt/cache/tejingdesk/systemd/timesync $targetRoot/var/lib/systemd/timesync
  '';

  # clean up old root subvolumes periodically
  # leaves a minimum of 'keepAtLeast' copies
  # keeps anything whose successor is newer than 'cutoffDate'
  systemd.services.root-subvol-cleanup = let
    keepAtLeast = 5;
    cutoffDate = "30 days ago";
  in
    {
      description = "old root subvolume cleaner";
      startAt = "daily";
      script = ''
        set -euo pipefail
        cutoff="$(date -d ${lib.escapeShellArg cutoffDate} '+%s')"
        prev=$(date '+%s')
        count=${toString keepAtLeast}
        for f in $(ls -1Adt --time=birth /mnt/cache/tejingdesk/root/root-*);do
          cur="$(stat -c '%W' "$f")"
          if [ "$prev" -lt "$cutoff" ] && [ "$count" -lt 1 ]; then
            echo Removing subvolume "$f" recursively
            ${pkgs.btrfs-progs}/bin/btrfs subvolume list --sort=-path /mnt/cache/ | ${pkgs.gnused}/bin/sed -nE 's|^ID [0-9]+ gen [0-9]+ top level [0-9]+ path (.+)$|/mnt/cache/\1|;t ok;z;s/^$/Unrecognized line in output of "btrfs subvolume list". Failing./;w /dev/stderr'$'\n'''Q 1;:ok;\|^'"$f"'|p' | ${pkgs.findutils}/bin/xargs -d $'\n' ${pkgs.btrfs-progs}/bin/btrfs subvolume delete
          fi
          prev="$cur"
          count=$(($count - 1))
        done
      '';
    };
}
