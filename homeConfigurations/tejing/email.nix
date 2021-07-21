{ config, pkgs, lib, my, ... }:
let
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
      onNotify = "${pkgs.isync}/bin/mbsync ${name}";
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
    passwordCommand = "${pkgs.writeShellScript "get-fastmail-app-password" "${pkgs.pass}/bin/pass fastmail.com/app | ${pkgs.coreutils}/bin/head -n 1"}";
  };
  accounts.email.accounts.yahoo = lib.recursiveUpdate (accountTemplate "yahoo") {
    address = "tejing2001@yahoo.com";
    imap.host = "imap.mail.yahoo.com";
    smtp.host = "smtp.mail.yahoo.com";
    userName = "tejing2001@yahoo.com";
    passwordCommand = "${pkgs.writeShellScript "get-yahoo-app-password" "${pkgs.pass}/bin/pass yahoo.com/app | ${pkgs.coreutils}/bin/head -n 1"}";
    mbsync.groups.yahoo.channels = builtins.mapAttrs (_: v:{extraConfig={Create="both";Remove="both";Expunge="both";};}//v) {
      drafts = { nearPattern = "Drafts"; farPattern = "Draft";     };
      spam   = { nearPattern = "Spam";   farPattern = "Bulk Mail"; };
      other.patterns = [ "*" "!Draft" "!Drafts" "\"!Bulk Mail\"" "!Spam" ];
    };
    mbsync.extraConfig.account.PipelineDepth = 1; # yahoo's imap servers are horrible
  };
  accounts.email.accounts.gmail = lib.recursiveUpdate (accountTemplate "gmail") {
    address = "ttejing@gmail.com";
    userName = "ttejing@gmail.com";
    passwordCommand = "${pkgs.writeShellScript "get-google-password" "${pkgs.pass}/bin/pass google.com | ${pkgs.coreutils}/bin/head -n 1"}";
    mbsync.groups.gmail.channels = builtins.mapAttrs (_: v:{extraConfig={Create="both";Remove="both";Expunge="both";};}//v) {
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
    Service.ExecStartPost = "${pkgs.isync}/bin/mbsync fastmail";
  };
  systemd.user.services.imapnotify-yahoo = {
    Unit.After = [ "passphrases.service" ];
    Unit.BindsTo = [ "passphrases.service" ];
    Install.WantedBy = mkForce [ "passphrases.service" ];
    Service.ExecStartPost = "${pkgs.isync}/bin/mbsync yahoo";
  };
  systemd.user.services.imapnotify-gmail = {
    Unit.After = [ "passphrases.service" ];
    Unit.BindsTo = [ "passphrases.service" ];
    Install.WantedBy = mkForce [ "passphrases.service" ];
    Service.ExecStartPost = "${pkgs.isync}/bin/mbsync gmail";
  };
  systemd.user.services.mymailwatch = {
    Unit = {
      Description = "Show desktop notifications for new mail in /mnt/persist/tejing/mail";
      After = [ "graphical-session-pre.target" ];
      PartOf = [ "graphical-session.target" ];
    };
    Install.WantedBy = [ "graphical-session.target" ];
    Service.ExecStart = my.scripts.mymailwatch;
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
      unset wait_key
      unmailboxes *
      set folder='${config.accounts.email.maildirBasePath}/${config.accounts.email.accounts.fastmail.maildir.path}'
      mailboxes +Inbox +Sent +Drafts +Spam +Trash +Archive
      set folder='${config.accounts.email.maildirBasePath}/${config.accounts.email.accounts.yahoo.maildir.path}'
      mailboxes +Inbox +Sent +Drafts +Spam +Trash +Archive
      set folder='${config.accounts.email.maildirBasePath}/${config.accounts.email.accounts.gmail.maildir.path}'
      mailboxes +Inbox +Sent +Drafts +Spam +Trash +All
      set pgp_default_key=46E96F6FF44F3D74
    '';
  };
  home.file.".mailcap".text = ''
    text/html; ${pkgs.lynx}/bin/lynx %s; nametemplate=%s.html
    text/html; ${pkgs.lynx}/bin/lynx -dump -width ''${COLUMNS:-80} %s; nametemplate=%s.html; copiousoutput
  '';
}
