{ inputs, lib, my, ... }:

let

  inherit (builtins)
    mapAttrs
    parseFlakeRef
  ;
  inherit (lib)
    genAttrs
  ;

  flakeNixInputs = (import (inputs.self + "/flake.nix")).inputs;

  canonicalizeInputSpec = spec: if spec ? url then removeAttrs spec [ "url" ] // parseFlakeRef spec.url else spec;
in lib.mkMerge [
  {
    flake.nixosModules = my.lib.getImportableExcept ./. [ "fpentry" ];

    # FIXME These are here so the options are defined for now. Don't want these options long term.
    perHost.nixos.cfg = { lib, my, ... }: let
      inherit (lib) mkEnableOption;
    in {
      options.my.customize.users = mkEnableOption "customization of options applying to all users";
      options.my.customize.shell = mkEnableOption "shell customization";
      options.my.customize.nix = mkEnableOption "customization of nix";
      options.my.users.tejing.enable = mkEnableOption "user \"tejing\"";
      options.my.users.tejing.pam = mkEnableOption "pam settings for user \"tejing\"";
      options.my.users.tejing.desktop = mkEnableOption "desktop-specific settings for user \"tejing\"";
      options.my.users.tejing.network = mkEnableOption "networking settings for user \"tejing\"";
      options.my.users.tejing.adb = mkEnableOption "adb usage by user \"tejing\"";
    };
  }

  {
    perHost.nixos.cfg = { lib, my, ... }: let
      inherit (lib)
        mkOption
        mkOverride
        types
      ;
    in {
      imports = [
      ];

      config._module.args.inputSpecs = mapAttrs (_: canonicalizeInputSpec) flakeNixInputs;

      options.my.isBuildVm = mkOption {
        type = types.bool;
        description = "Whether the system being built is part of a nixos-rebuild build-vm or build-vm-with-bootloader";
        default = false;
      };
      options.my.isBuildVmWithBootLoader = mkOption {
        type = types.bool;
        description = "Whether the system being built is part of a nixos-rebuild build-vm-with-bootloader";
        default = false;
      };

      config.virtualisation.vmVariant.my.isBuildVm = true;
      config.virtualisation.vmVariantWithBootLoader.my.isBuildVm = true;
      config.virtualisation.vmVariantWithBootLoader.my.isBuildVmWithBootLoader = true;
      config.home-manager.sharedModules = [{
        my.isBuildVm = my.isBuildVm;
        my.isBuildVmWithBootLoader = my.isBuildVmWithBootLoader;
      }];

      # Strictly definitional users, passwords, and groups
      config.users.mutableUsers = false;

      # undo default shellAliases
      config.environment.shellAliases = genAttrs [ "l" "ll" "ls" ] (_: mkOverride 999 null);
    };
  }

  {
    my.flake.inputs.flake-programdb.url = "github:tejing1/flake-programdb";
    perHost.nixos.cfg = { lib, my, ... }: {
      imports = [
        inputs.flake-programdb.nixosModules.flake-programdb
      ];
      options.my.command-not-found.stateDir = lib.mkOption {
        type = lib.types.path;
      };
      config.flake-programdb.enable = true;
      config.flake-programdb.dbDir = my.command-not-found.stateDir;
    };
  }

  {
    perHost.nixos.cfg = { config, inputs, lib, my, pkgs, ... }: let
      inherit (lib) mkEnableOption mkIf mkMerge;
      inherit (my.lib) readSecret;
    in {
      config = mkMerge [
        {
          users.users.tejing = {
            isNormalUser = true;
            uid = 1000;
            extraGroups = [ "wheel" "audio" ];
            shell = pkgs.zsh;
            password = mkIf (config.users.users.tejing.hashedPassword == null) "password"; # Fallback for locked build
            hashedPassword = readSecret null ./users/tejing/pwhash.secret;
            openssh.authorizedKeys.keys = [ "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDDD59yTSccmS5YdrrbH79dtnyqqQ6Jid+i2D2DIaO5I/4UnI4s2eff7MAXF5xg80eEilzpbqR+BMykbEtCRkosNk0WYfbrbTmosihmItPe+xkoedQpKd60ADyYMjmJSfUrHbIZ4E07BacZcD+UUM5s4cYZPjxDjz9DFgychhG4BN0m8vjQOP1ds9jvPqnZw2tmcGCuim8c1lQDMAiYZXV+Vqrda31iFFb87fmsHv7ZlVXaUPJ2RJjz6a+LsD49eV2pSycatwM7Z4bM+DD7HJR+HvDQxfLwWP2bVxxBw3KSXNHGTlnH9VF/n11vWnkiNcPV4QbHpKd2Y5MKxU3eGLJ/ subkey 004FFE9C78916342 of key 46E96F6FF44F3D74 keygrip is 0B9AF8FB49262BBE699A9ED715A7177702D9E640" ];
          };

          programs.fish.enable = true;
          programs.zsh.enable = true;

          nixpkgs.config.allowUnfree = true;

          # Set available fonts
          fonts.packages = builtins.attrValues {
            nerdfonts = pkgs.nerd-fonts.dejavu-sans-mono;
          };

          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget
          environment.systemPackages = builtins.attrValues {
            inherit (pkgs.haskellPackages)
              git-annex
            ;
            inherit (pkgs)
              lsof # needed for git-annex webapp
              rclone # used to connect git-annex to my phone's ftp server
            ;
          };

          nixpkgs.overlays = [
            # Prevents gh from leaving garbage characters in the input
            # buffer when urxvt is set to a transparent background
            inputs.self.overlays.gh-urxvt-fix-termenv
          ];

          # PAM rules for i3lock are no longer enabled by default.
          security.pam.services.i3lock.enable = true;
        }
        {
          # unlock gpg keys with my login password
          security.pam.services = {
            login.gnupg.enable = true;
            login.gnupg.noAutostart = true;
            login.gnupg.storeOnly = true;
            lightdm-greeter.gnupg.enable = true;
            lightdm-greeter.gnupg.noAutostart = true;
            lightdm-greeter.gnupg.storeOnly = true;
            i3lock.gnupg.enable = true;
            i3lock.gnupg.noAutostart = true;
          };
        }
        {
          # Enable touchpad support.
          # I actually just need this for the mouse acceleration settings that I'm used to.
          services.libinput.enable = true;
          services.libinput.mouse.accelSpeed = "0.6";

          programs.dconf.enable = true;

          systemd.tmpfiles.rules = [ "d /mnt/persist/tejing 0755 tejing users - -" ];

          # Start urxvtd with user sessions
          services.urxvtd.enable = true;
          services.urxvtd.package = pkgs.rxvt-unicode-emoji;
        }
        {
          # rtorrent peer & dht ports
          networking.firewall.allowedTCPPorts = [ 62813 ];
          networking.firewall.allowedUDPPorts = [ 62813 ];
        }
        {
          programs.adb.enable = true;
          users.users.tejing.extraGroups = [ "adbusers" ];
        }
      ];
    };
  }

  {
    perHost.nixos.cfg = { lib, my, pkgs, ... }: let
      inherit (builtins) attrValues;
      inherit (lib) mkEnableOption mkIf escapeShellArg;
    in {
      nix = {
        # Use the new CLI and enable flakes
        settings.experimental-features = [ "nix-command" "flakes" ];
        # Make builds run with low priority so my system stays responsive
        daemonCPUSchedPolicy = "idle";
        daemonIOSchedClass = "idle";
        # automatically hardlink identical files
        optimise = {
          automatic = true;
          dates = [ "daily" ];
        };
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

  {
    perHost.nixos.cfg = { config, home-manager, inputs, inputSpecs, lib, my, nixpkgs, pkgs, ... }: let
      inherit (builtins) toFile parseFlakeRef;
      inherit (inputs) self;
      inherit (lib) mkEnableOption mkIf;
      inherit (lib.strings) escapeNixIdentifier;
      inherit (my.lib) mkFlake repoLockedTestResult flakeClosureRef;
    in {
      options.my.customize.registry = mkEnableOption "nix flake registry customization";
      config = mkIf my.customize.registry {
        # Let 'nixos-version --json' know about the Git revision
        # of this flake.
        system.configurationRevision = mkIf (self ? rev) self.rev;

        system.extraDependencies = [

          # Save our single IFD derivation so we don't usually have to
          # rebuild it
          repoLockedTestResult

          # Save the whole input closure of this flake, so we have all the
          # nix code necessary to rebuild this system
          (flakeClosureRef self)

        ];

        # Don't install nix-channel or create stuff on the filesystem
        # for channels
        nix.channel.enable = false;

        # Indirect our NIX_PATH through /etc so that it updates without a
        # relog
        nix.nixPath = [ "/etc/nix/path" ];

        # Don't talk to the internet every time I use the registry
        # I don't use it anyway
        nix.settings.flake-registry = toFile "global-registry.json" ''{"flakes":[],"version":2}'';

        # the version of nixpkgs used to build the system
        nix.registry.nixpkgs.flake = nixpkgs;
        environment.etc."nix/path/nixpkgs".source = nixpkgs;

        # the version of home-manager used to build the system
        nix.registry.home-manager.flake = home-manager;
        environment.etc."nix/path/home-manager".source = home-manager;

        # the version of this flake used to build the system
        nix.registry.activeconfig.flake = self;
        environment.etc."nix/path/activeconfig".source = self;

        # build and register a flake to capture this config's pkgs attribute
        nix.registry.pkgs.flake = mkFlake {config = self;}
          "{config,...}: {legacyPackages.${escapeNixIdentifier pkgs.stdenv.hostPlatform.system}=config.nixosConfigurations.${escapeNixIdentifier config.networking.hostName}.pkgs;}";

        # the (runtime) current version of this flake
        nix.registry.config.to = { type = "path"; path = "/mnt/persist/tejing/flake"; };
        environment.etc."nix/path/config".source = "/mnt/persist/tejing/flake";

        # the (runtime) current version of nixos stable
        nix.registry.nixpkgs-stable.to = inputSpecs.nixpkgs;

        # the (runtime) current version of nixos unstable
        nix.registry.nixpkgs-unstable.to = parseFlakeRef "github:NixOS/nixpkgs/nixos-unstable";
      };
    };
  }
]
