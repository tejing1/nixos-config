{ config, lib, my, pkgs, ... }:
let
  inherit (builtins) attrValues;
  inherit (lib) mkForce;

  accountTemplate = name: {
    realName = "Jeff Huffman";
    maildir.path = name;
    imap.host = "imap.${name}.com";
    smtp.host = "smtp.${name}.com";
    gpg = {
      encryptByDefault = true;
      signByDefault = true;
      key = "46E96F6FF44F3D74";
    };
    imapnotify = {
      enable = true;
      boxes = [ "Inbox" ];
      onNotify = "${pkgs.coreutils}/bin/touch -c -- ${config.accounts.email.maildirBasePath}/${name}/Inbox/new";
    };
    mbsync = {
      enable = true;
      create = "both";
      remove = "both";
      expunge = "both";
      patterns = [ "*" ];
    };
    msmtp.enable = true;
    neomutt.enable = true;
    neomutt.sendMailCommand = "msmtpq --read-envelope-from";
  };
in
{
  accounts.email.maildirBasePath = "/mnt/persist/tejing/mail";
  accounts.email.accounts.fastmail = lib.recursiveUpdate (accountTemplate "fastmail") {
    primary = true;
    address = "tejing@tejing.com";
    aliases = [ "tejing@fastmail.com" ];
    userName = "tejing@fastmail.com";
    passwordCommand = "${my.getpass} fastmail.com/app";
  };
  accounts.email.accounts.yahoo = lib.recursiveUpdate (accountTemplate "yahoo") {
    address = "tejing2001@yahoo.com";
    imap.host = "imap.mail.yahoo.com";
    smtp.host = "smtp.mail.yahoo.com";
    userName = "tejing2001@yahoo.com";
    passwordCommand = "${my.getpass} yahoo.com/app";
    mbsync.groups.yahoo.channels = builtins.mapAttrs (_: v:{extraConfig={Create="both";Remove="both";Expunge="both";SyncState="*";};}//v) {
      drafts = { nearPattern = "Drafts"; farPattern = "Draft";     };
      spam   = { nearPattern = "Spam";   farPattern = "Bulk Mail"; };
      other.patterns = [ "*" "!Draft" "!Drafts" "\"!Bulk Mail\"" "!Spam" ];
    };
    mbsync.extraConfig.account.PipelineDepth = 1; # yahoo's imap servers are horrible
  };
  accounts.email.accounts.gmail = lib.recursiveUpdate (accountTemplate "gmail") {
    address = "ttejing@gmail.com";
    userName = "ttejing@gmail.com";
    passwordCommand = "${my.getpass} google.com/app";
    mbsync.groups.gmail.channels = builtins.mapAttrs (_: v:{extraConfig={Create="both";Remove="both";Expunge="both";SyncState="*";};}//v) {
      inbox = { patterns = [ "INBOX" ]; };
      sent  = { nearPattern = "Sent"; farPattern = "[Gmail]/Sent Mail"; };
      all   = { nearPattern = "All";  farPattern = "[Gmail]/All Mail";  };
      other = {
        farPattern = "[Gmail]/";
        patterns = [ "*" "!INBOX" "\"!Sent Mail\"" "!Sent" "\"!All Mail\"" "!All" "!Important" "!Starred" ];
      };
    };
  };
  xsession.importedVariables = [ "PASSWORD_STORE_DIR" ]; # So imapnotify knows where to find the password store
  services.imapnotify.enable = true;
  systemd.user.services.imapnotify-fastmail = {
    Unit.After = [ "passphrases.service" ];
    Unit.BindsTo = [ "passphrases.service" ];
    Install.WantedBy = mkForce [ "passphrases.service" ];
  };
  systemd.user.services.imapnotify-yahoo = {
    Unit.After = [ "passphrases.service" ];
    Unit.BindsTo = [ "passphrases.service" ];
    Install.WantedBy = mkForce [ "passphrases.service" ];
  };
  systemd.user.services.imapnotify-gmail = {
    Unit.After = [ "passphrases.service" ];
    Unit.BindsTo = [ "passphrases.service" ];
    Install.WantedBy = mkForce [ "passphrases.service" ];
  };
  systemd.user.services.mailwatch = {
    Unit = {
      Description = "New mail notifier and mail syncer";
      After = [ "passphrases.service" ];
      BindsTo = [ "passphrases.service" ];
    };
    Install.WantedBy = mkForce [ "passphrases.service" ];
    Service.ExecStart = "${my.lib.mkShellScript "mailwatch.sh" {
      inputs = attrValues { inherit (pkgs) coreutils dunst isync findutils gnused inotify-tools; };
      execer = [ "cannot:${pkgs.isync}/bin/mbsync" "cannot:${pkgs.dunst}/bin/dunstify" ];
    } ./mailwatch.sh}";
  };
  programs.mbsync.enable = true;
  programs.msmtp.enable = true;
  programs.neomutt = {
    enable = true;
    sidebar.enable = true;
    sort = "reverse-date-received";
    extraConfig = ''
      set mail_check_stats
      set text_flowed
      set reflow_wrap=140
      set alias_file=/mnt/persist/tejing/mail/neomutt_aliases
      source /mnt/persist/tejing/mail/neomutt_aliases
      unset wait_key
      unmailboxes *
      set folder='${config.accounts.email.maildirBasePath}/${config.accounts.email.accounts.fastmail.maildir.path}'
      mailboxes +Inbox +Sent +Drafts +Spam +Trash +Archive
      set folder='${config.accounts.email.maildirBasePath}/${config.accounts.email.accounts.yahoo.maildir.path}'
      mailboxes +Inbox +Sent +Drafts +Spam +Archive
      set folder='${config.accounts.email.maildirBasePath}/${config.accounts.email.accounts.gmail.maildir.path}'
      mailboxes +Inbox +Sent +Drafts +Spam +Trash +All
      set pgp_default_key=46E96F6FF44F3D74

      # retain previous appearance
      color normal white black
    '';
  };
  home.file.".mailcap".text = ''
    text/html; ${pkgs.lynx}/bin/lynx %s; nametemplate=%s.html
    text/html; ${pkgs.lynx}/bin/lynx -dump -width ''${COLUMNS:-80} %s; nametemplate=%s.html; copiousoutput
    image/png; ${pkgs.feh}/bin/feh %s; nametemplate=%s.png
    image/jpeg; ${pkgs.feh}/bin/feh %s; nametemplate=%s.jpg
    image/heic; ${pkgs.feh}/bin/feh %s; nametemplate=%s.heic
    application/pdf; ${pkgs.zathura}/bin/zathura %s; nametemplate=%s.pdf
  '';
  xsession.windowManager.i3.config.assigns."10" = [{class = "^URxvt$";instance = "^neomutt$";}];
  xsession.windowManager.i3.config.window.commands = [{ criteria = { class = "^URxvt$"; instance = "^neomutt$"; }; command = "layout tabbed"; }];
  xsession.windowManager.i3.config.startup = [{ command = "${my.launch.term} app neomutt ${pkgs.neomutt}/bin/neomutt"; always = false; notification = false; }];
}
