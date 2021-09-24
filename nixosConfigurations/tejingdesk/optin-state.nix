{ config, lib, pkgs, ... }:

{
  # Don't bother with the lecture or the need to keep state about who's been lectured
  security.sudo.extraConfig = "Defaults lecture=\"never\"";

  # point nixos-rebuild at my flake
  environment.etc."nixos/flake.nix".source = "/mnt/persist/tejing/flake/flake.nix";

  # switch-to-configuration refuses to operate without this tag
  environment.etc.NIXOS.text = "";

  # set machine id for log continuity
  environment.etc.machine-id.source = ./machine-id;

  # keep hardware clock adjustment data
  environment.etc.adjtime.source = "/mnt/cache/tejingdesk/adjtime";

  # TODO: don't do this if building for a VM (use (config.fileSystems."/tmp/xchg".fsType == "9p")?)
  # just before mounting, create empty subvolume where nixos' mounting code expects it
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    # wait for device to show up
    waitDevice ${config.fileSystems."/mnt/cache".device}

    # temporarily mount subvolume '/' of lvm/cache
    mkdir -p /mnt
    mount -o subvol=/ ${config.fileSystems."/mnt/cache".device} /mnt

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
  # TODO: implement proper recursive subvolume deletion, rather than hardcoding the expected subvolumes
  systemd.services.root-subvol-cleanup = let
    keepAtLeast = 5;
    cutoffDate = "30 days ago";
  in
    {
      description = "old root subvolume cleaner";
      startAt = "daily";
      script = ''
        cutoff="$(date -d ${lib.escapeShellArg cutoffDate} '+%s')"
        prev=$(date '+%s')
        count=${toString keepAtLeast}
        for f in $(ls -1Adt --time=birth /mnt/cache/tejingdesk/root/root-*);do
          cur="$(stat -c '%W' "$f")"
          if [ "$prev" -lt "$cutoff" ] && [ "$count" -lt 1 ]; then
            echo Removing subvolume "$f"
            ${pkgs.btrfs-progs}/bin/btrfs subvolume delete "$f/srv" "$f/var/lib/machines" "$f"
          fi
          prev="$cur"
          count=$(($count - 1))
        done
      '';
    };
}
