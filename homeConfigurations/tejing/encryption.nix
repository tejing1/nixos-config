{ config, lib, my, pkgs, ... }:
let
  inherit (lib) mkBefore mkAfter mkOption types;
  inherit (my.lib) mkShellScript;
  m = 60; h = 60*m; d = 24*h; y = 365*d;
in
{
  options.my.getpass = mkOption {
    type = types.unspecified;
    description = "A script to get a password from my password store";
    visible = false;
    readOnly = true;
  };

  config = {
    home.packages = builtins.attrValues {
      inherit (pkgs)
        git-remote-gcrypt
      ;
    };
    programs.gpg.enable = true;
    programs.gpg.settings = {
      default-key = "963D 3AFB 8AA4 D693 153C  1500 46E9 6F6F F44F 3D74";
      default-recipient-self = true;
      auto-key-locate = "local,wkd,keyserver";
      keyserver = "hkps://keys.openpgp.org";
      auto-key-retrieve = true;
      auto-key-import = true;
      keyserver-options = "honor-keyserver-url";
      no-autostart = true;
    };
    services.gpg-agent = {
      enable = true;
      enableSshSupport = true;
      defaultCacheTtl = 6*h;
      defaultCacheTtlSsh = 6*h;
      maxCacheTtl = 100*y; # effectively unlimited
      maxCacheTtlSsh = 100*y; # effectively unlimited
      sshKeys = [ "0B9AF8FB49262BBE699A9ED715A7177702D9E640" ];
      extraConfig = ''
        allow-preset-passphrase
      '';
    };
    # it's important that this file be sorted, because I use it in the
    # passphrases service
    home.file.".pam-gnupg".source = pkgs.runCommand ".pam-gnupg" {keys = [
      "0283E984AD421E8903D27C147E92DE82ABED47E6"
      "089DF248E14CACA5F2C19EB7F8CDFBF73B82BAEA"
      "0B9AF8FB49262BBE699A9ED715A7177702D9E640"
    ];} "for k in $keys; do echo \"$k\" >> file;done;sort file > $out";
    systemd.user.services.passphrases = {
      Unit = {
        Description = "Preset passphrases in gpg-agent";
        After = [ "graphical-session-pre.target" ];
        PartOf = [ "graphical-session.target" ];
      };
      Install.WantedBy = [ "graphical-session.target" ];
      Service = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = "${mkShellScript "passphrases-start" {
          inputs = builtins.attrValues {
            inherit (pkgs) coreutils gnupg gawk diffutils;
          };
          execer = [
            "cannot:${pkgs.gnupg}/bin/gpg-connect-agent"
            "cannot:${pkgs.diffutils}/bin/diff"
          ];
        } ''
          gpg-connect-agent 'keyinfo --list' /bye |
          awk '/^S / { if ($7 == 1 && $10 == "-") print $3 }' |
          sort |
          diff -q - ~/.pam-gnupg
        ''}";
        ExecStop = "${mkShellScript "passphrases-stop" {
          inputs = builtins.attrValues {
            inherit (pkgs) gnupg;
          };
          execer = [
            "cannot:${pkgs.gnupg}/bin/gpg-connect-agent"
          ];
        } ''
          exec < ~/.pam-gnupg
          while read keygrip; do
            cmd="clear_passphrase $keygrip"
            echo -n "$cmd: ";gpg-connect-agent "$cmd" /bye
            cmd="clear_passphrase --mode=normal $keygrip"
            echo -n "$cmd: ";gpg-connect-agent "$cmd" /bye
            cmd="clear_passphrase --mode=ssh $keygrip"
            echo -n "$cmd: ";gpg-connect-agent "$cmd" /bye
          done
        ''}";
      };
    };

    # make GPG_TTY initialization and p10k's instant prompt play nice
    programs.zsh.initExtraFirst = mkBefore ''
      current_tty="$(tty)"
      tty() { echo "$current_tty"; }
    '';
    programs.zsh.initExtra = mkAfter ''
      unfunction tty
      unset current_tty
    '';

    programs.password-store.enable = true;
    programs.password-store.package = pkgs.pass.withExtensions (exts: builtins.attrValues {
      inherit (exts)
        pass-otp
      ;
    });
    programs.password-store.settings = {
      PASSWORD_STORE_SIGNING_KEY = "963D3AFB8AA4D693153C150046E96F6FF44F3D74";
      PASSWORD_STORE_X_SELECTION = "primary";
    };
    my.getpass = mkShellScript "mygetpass" {
      inputs = builtins.attrValues {
        inherit (pkgs) coreutils;
        pass = config.programs.password-store.package;
      };
      execer = [
        "cannot:${config.programs.password-store.package}/bin/pass"
      ];
    } ''
      pass show -- "$@" | head -n 1
    '';

    xsession.windowManager.i3.config = let
      mod = config.xsession.windowManager.i3.config.modifier;
      pass-interact = mkShellScript "pass-interact" {
        inputs = builtins.attrValues {
          inherit (pkgs) coreutils findutils gnused rofi xdotool scrot zbar dunst;
          pass = config.programs.password-store.package;
        };
        execer = [ # Some of these are not true globally, but fine for the features I'm using.
          "cannot:${pkgs.xdotool}/bin/xdotool"
          "cannot:${pkgs.rofi}/bin/rofi"
          "cannot:${pkgs.scrot}/bin/scrot"
          "cannot:${config.programs.password-store.package}/bin/pass"
        ];
      } ''
        set -euo pipefail

        storedir="''${PASSWORD_STORE_DIR:-"$HOME/.password-store"}"
        lastused_file="$HOME/.cache/pass-interact/lastused"

        mode="$1"

        die() {
            printf "pass-interact error: %s\n" "$1" >&2 || true
            dunstify -u critical -- "pass-type error: $1" || true
            exit 1
        }

        # Wrap rofi to preserve window focus
        rofi_() {
            focused_window="$(xdotool getwindowfocus)"
            if rofi "$@"; then
                xdotool windowfocus "$focused_window"
            else
                err="$?"
                xdotool windowfocus "$focused_window"
                [ "$err" -eq 1 ] && exit 1
                die "rofi failed with exit code $err"
            fi
        }

        entry_exists() {
            [ -f "$storedir/$1.gpg" ] || [ -L "$storedir/$1.gpg" ]
        }

        type_out() {
            # Check that we actually got some data
            [ -n "''${1:-}" ] || die "empty argument to type_out"

            # Type value into focused window
            # Pass the command on stdin to avoid password being exposed through /proc
            xdotool - <<<"type --delay 0 --clearmodifiers -- ''\'''${1//\'/\'\"\'\"\'}'" || die "xdotool failed"
        }

        case "$mode" in
            password|username|usertabpass)
                entry_must_exist=1
                ;;
            generate)
                ;;
            otp)
                entry_must_exist=1
                ;;
            otp-import-qrcode)
                uri="$(scrot -izscapture -l 'mode=edge,width=1,color=#00FF00,opacity=255' - | zbarimg -Sdisable -Sqrcode.enable -qD --raw -)" || die "scrot/zbarimg failed"
                [ "$(wc -l <<<"$uri")" -eq 1 ] && [ "''${uri:0:10}" = "otpauth://" ] || die "zbarimg result does not look like exactly one otpauth uri"
                ;;
            *)
                die "bad mode: $mode"
                ;;
        esac

        if [ -f "$lastused_file" ]; then
            lastentry="$(< "$lastused_file")"
        fi
        entry="$(find "$storedir" -not -\( -name '.*' -prune -\) -not -type d -name '*.gpg' -printf '%P\0' \
          | sed -ze 's/.gpg$//' \
          | rofi_ -dmenu -sep '\0' -i -matching fuzzy -p "pass entry ($mode)" ''${entry_must_exist:+-no-custom} ''${lastentry:+-select} ''${lastentry:+"$lastentry"})"
        [ -n "$entry" ] || die "empty entry name"
        mkdir -p -- "$(dirname -- "$lastused_file")"
        printf "%s\n" "$entry" > "$lastused_file"

        case "$mode" in
            password)
                result="$(pass show -- "$entry" | sed -ne '1p')" || die "pass show / sed failed"
                type_out "$result"
                ;;
            username)
                result="$(pass show -- "$entry" | sed -ne 's/^username: //;Te;p;:e')" || die "pass show / sed failed"
                type_out "$result"
                ;;
            usertabpass)
                result="$(pass show -- "$entry" | sed -ne '1h;s/^username: //;Te;G;s/\n/\t/;p;:e')" || die "pass show / sed failed"
                type_out "$result"
                ;;
            generate)
                if entry_exists "$entry"; then
                    pass generate -i -- "$entry" || die "pass generate failed"
                    dunstify -- "Successfully re-generated password for $entry"
                else
                    pass generate -- "$entry" <<<"$uri" || die "pass generate failed"
                    dunstify -- "Successfully added $entry with newly generated password"
                fi
                ;;
            otp)
                result="$(pass otp code -- "$entry")"
                type_out "$result"
                ;;
            otp-import-qrcode)
                if entry_exists "$entry"; then
                    pass otp append -f -- "$entry" <<<"$uri" || die "pass otp append failed"
                    dunstify -- "Successfully appended otpauth uri to $entry"
                else
                    pass otp insert -- "$entry" <<<"$uri" || die "pass otp insert failed"
                    dunstify -- "Successfully inserted $entry with otpauth uri"
                fi
                ;;
        esac
      '';
    in {
      keybindings."${mod}+p" = "mode pass-interact";

      modes."pass-interact".Escape        = "mode default";
      modes."pass-interact".u             = "mode default; exec --no-startup-id ${pass-interact} username";
      modes."pass-interact".p             = "mode default; exec --no-startup-id ${pass-interact} password";
      modes."pass-interact".l             = "mode default; exec --no-startup-id ${pass-interact} usertabpass";
      modes."pass-interact".g             = "mode default; exec --no-startup-id ${pass-interact} generate";
      modes."pass-interact".o             = "mode default; exec --no-startup-id ${pass-interact} otp";
      modes."pass-interact"."--release q" = "mode default; exec --no-startup-id ${pass-interact} otp-import-qrcode";
    };

    programs.ssh.enable = true;
    programs.ssh.matchBlocks = {
      "rsync.net" = {
        hostname = "de1348.rsync.net";
        user = "de1348";
      };
      tejingdroid-nix = {
        hostname = "192.168.0.131";
        extraOptions.HostKeyAlias = "tejingdroid-nix";
        user = "nix-on-droid";
        port = 49008;
      };
      tejingdroid-termux = {
        hostname = "192.168.0.131";
        extraOptions.HostKeyAlias = "tejingdroid-termux";
        user = "u0_a323";
        port = 8022;
      };
      tejingphone = {
        hostname = "192.168.0.209";
        extraOptions.HostKeyAlias = "tejingphone";
      };
    };
  };
}
