{ lib, my, pkgs, ... }:
let
  inherit (lib) mkBefore mkAfter mkOption types;
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
        ExecStart = "${pkgs.writeShellScript "passphrases-start" ''
          ${pkgs.gnupg}/bin/gpg-connect-agent 'keyinfo --list' /bye |
          ${pkgs.gawk}/bin/awk '/^S / { if ($7 == 1 && $10 == "-") print $3 }' |
          ${pkgs.coreutils}/bin/sort |
          ${pkgs.diffutils}/bin/diff -q - ~/.pam-gnupg
        ''}";
        ExecStop = "${pkgs.writeShellScript "passphrases-stop" ''
          exec < ~/.pam-gnupg
          while read keygrip; do
            cmd="clear_passphrase $keygrip"
            echo -n "$cmd: ";${pkgs.gnupg}/bin/gpg-connect-agent "$cmd" /bye
            cmd="clear_passphrase --mode=normal $keygrip"
            echo -n "$cmd: ";${pkgs.gnupg}/bin/gpg-connect-agent "$cmd" /bye
            cmd="clear_passphrase --mode=ssh $keygrip"
            echo -n "$cmd: ";${pkgs.gnupg}/bin/gpg-connect-agent "$cmd" /bye
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
        pass-import
      ;
    });
    programs.password-store.settings = {
      PASSWORD_STORE_SIGNING_KEY = "963D3AFB8AA4D693153C150046E96F6FF44F3D74";
      PASSWORD_STORE_X_SELECTION = "primary";
    };
    my.getpass = my.lib.mkShellScript "mygetpass" {
      inputs = builtins.attrValues {
        inherit (pkgs) coreutils pass;
      };
      execer = [ "cannot:${pkgs.pass}/bin/pass" ];
    } ''
      pass show -- "$@" | head -n 1
    '';
  };
}
