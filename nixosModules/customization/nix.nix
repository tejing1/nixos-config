{ lib, my, pkgs, ... }:
let
  inherit (builtins) attrValues;
  inherit (lib) mkEnableOption mkIf escapeShellArg;
in
{
  options.my.customize.nix = mkEnableOption "customization of nix";
  config = mkIf my.customize.nix {
    nixpkgs.overlays = [
      # make `nix repl` handle home and end keys in urxvt properly
      my.overlays.editline-urxvt-home-end-fix
    ];

    nix = {
      # Use the new CLI and enable flakes
      settings.experimental-features = [ "nix-command" "flakes" ];
      # Make builds run with low priority so my system stays responsive
      daemonCPUSchedPolicy = "idle";
      daemonIOSchedClass = "idle";
      # Hard link identical files in the store automatically
      settings.auto-optimise-store = true;
      # automatically trigger garbage collection
      gc = {
        automatic = true;
        persistent = true;
        dates = "weekly";
      };
    };

    # Clean up system generations more intelligently than nix-collect-garbage
    systemd.services.system-profile-cleanup = let
      keepAtLeast = 5;
      cutoffDate = "30 days ago";
    in {
      description = "system profile cleaner";
      startAt = "daily";
      script = ''
        cutoff="$(date -d ${escapeShellArg cutoffDate} '+%s')"
        prev=$(date '+%s')
        count=${toString keepAtLeast}
        for f in $(ls -1Adt --time=birth /nix/var/nix/profiles/system-*);do
          cur="$(stat -c '%W' "$f")"
          if [ "$prev" -lt "$cutoff" ] && [ "$count" -lt 1 ]; then
            part="''${f#/nix/var/nix/profiles/system-}"
            echo "Removing generation ''${part%-link}"
            rm -f -- "$f"
          fi
          prev="$cur"
          count=$(($count - 1))
        done
      '';
    };
    systemd.timers.system-profile-cleanup.timerConfig.Persistent = true;

    environment.systemPackages = attrValues {
      inherit (pkgs)
        # Needed to work with my flake
        git git-crypt
      ;
    };
  };
}
