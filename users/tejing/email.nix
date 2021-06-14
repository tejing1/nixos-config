{ config, pkgs, ... }:

{
  accounts.email.maildirBasePath = "/mnt/persist/tejing/mail";
  accounts.email.accounts.fastmail = {
    primary = true;
    realName = "Jeff Huffman";
    address = "tejing@tejing.com";
    aliases = [ "tejing@fastmail.com" ];
    maildir.path = "fastmail";
    imap.host = "imap.fastmail.com";
    smtp.host = "smtp.fastmail.com";
    userName = "tejing@fastmail.com";
    passwordCommand = "${pkgs.writeShellScript "get-fastmail-app-password" "${pkgs.pass}/bin/pass fastmail.com/app | ${pkgs.coreutils}/bin/head -n 1"}";
    gpg = {
      encryptByDefault = true;
      signByDefault = true;
      key = "46E96F6FF44F3D74";
    };
    imapnotify = {
      enable = true;
      boxes = [ "Inbox" ];
      onNotify = "${pkgs.isync}/bin/mbsync fastmail";
      # onNotifyPost = {};
    };
    mbsync = {
      enable = true;
      create = "both";
      expunge = "both";
      patterns = [ "*" ];
    };
    msmtp.enable = true;
    neomutt.enable = true;
  };
  accounts.email.accounts.yahoo = {
    realName = "Jeff Huffman";
    address = "tejing2001@yahoo.com";
    maildir.path = "yahoo";
    imap.host = "imap.mail.yahoo.com";
    smtp.host = "smtp.mail.yahoo.com";
    userName = "tejing2001@yahoo.com";
    passwordCommand = "${pkgs.writeShellScript "get-yahoo-app-password" "${pkgs.pass}/bin/pass yahoo.com/app | ${pkgs.coreutils}/bin/head -n 1"}";
    gpg = {
      encryptByDefault = true;
      signByDefault = true;
      key = "46E96F6FF44F3D74";
    };
    imapnotify = {
      enable = true;
      boxes = [ "Inbox" ];
      onNotify = "${pkgs.isync}/bin/mbsync yahoo";
      # onNotifyPost = {};
    };
    mbsync = {
      enable = true;
      create = "both";
      # expunge = "both";
      patterns = [ "*" ];
      extraConfig.account.PipelineDepth = 1;
    };
    msmtp.enable = true;
    neomutt.enable = true;
  };
  accounts.email.accounts.gmail = {
    realName = "Jeff Huffman";
    address = "ttejing@gmail.com";
    maildir.path = "gmail";
    imap.host = "imap.gmail.com";
    smtp.host = "smtp.gmail.com";
    userName = "ttejing@gmail.com";
    passwordCommand = "${pkgs.writeShellScript "get-google-password" "${pkgs.pass}/bin/pass google.com | ${pkgs.coreutils}/bin/head -n 1"}";
    gpg = {
      encryptByDefault = true;
      signByDefault = true;
      key = "46E96F6FF44F3D74";
    };
    imapnotify = {
      enable = true;
      boxes = [ "Inbox" ];
      onNotify = "${pkgs.isync}/bin/mbsync gmail";
      # onNotifyPost = {};
    };
    mbsync = {
      enable = true;
      create = "both";
      # expunge = "both";
      patterns = [ "*" ];
      extraConfig.account.PipelineDepth = 1;
    };
    msmtp.enable = true;
    neomutt.enable = true;
  };
  xsession.importedVariables = [ "PASSWORD_STORE_DIR" ]; # So imapnotify knows where to find the password store
  services.imapnotify.enable = true;
  programs.mbsync.enable = true;
  programs.msmtp.enable = true;
  programs.neomutt = {
    enable = true;
    sidebar.enable = true;
    sort = "reverse-date-received";
    extraConfig = ''
      set mail_check_stats
      unset wait_key
      unmailboxes *
      set folder='${config.accounts.email.maildirBasePath}/${config.accounts.email.accounts.fastmail.maildir.path}'
      mailboxes +Inbox +Sent +Drafts +Archive +Spam +Trash
      set folder='${config.accounts.email.maildirBasePath}/${config.accounts.email.accounts.yahoo.maildir.path}'
      mailboxes +Inbox +Archive '+Bulk Mail' +Draft +Drafts +Sent +Trash
      set folder='${config.accounts.email.maildirBasePath}/${config.accounts.email.accounts.gmail.maildir.path}'
      mailboxes +Inbox +Drafts +Sent '+[Gmail]/All Mail' '+[Gmail]/Drafts' '+[Gmail]/Important' '+[Gmail]/Sent Mail' '+[Gmail]/Spam' '+[Gmail]/Starred' '+[Gmail]/Trash'
      set pgp_default_key=46E96F6FF44F3D74
    '';
  };
  home.file.".mailcap".text = ''
    text/html; ${pkgs.lynx}/bin/lynx %s; nametemplate=%s.html
    text/html; ${pkgs.lynx}/bin/lynx -dump -width ''${COLUMNS:-80} %s; nametemplate=%s.html; copiousoutput
  '';
}
