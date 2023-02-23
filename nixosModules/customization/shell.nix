{ inputs, inputSpecs, lib, my, pkgs, ... }:
let
  inherit (builtins) attrValues;
  inherit (lib) genAttrs mkOverride mkEnableOption mkOption mkIf;

  revPath = "${my.command-not-found.stateDir}/programs.rev";
  dbPath = "${my.command-not-found.stateDir}/programs.sqlite";

  # downloads programs.sqlite from the appropriate iteration of the
  # channel corresponding to the nixpkgs branch in use, if not already
  # downloaded.
  downloadDatabase = my.lib.mkShellScript "download-programs-database" {
    inputs = attrValues {
      inherit (pkgs) coreutils curl jq xz gnutar;
      inherit (my.pkgs) hred;
    };
    execer = [ "cannot:${my.pkgs.hred}/bin/hred" ];
  } ''
    set -e -o pipefail

    channel="$1"
    rev="$2"

    [ -e ${revPath} ] && [ "$(cat ${revPath})" == "$rev" ] && exit 0
    rm -f ${revPath}

    url="$(curl -sSw '%{redirect_url}' "https://channels.nixos.org/$channel")"
    url="''${url%/*}"
    url="https://nix-releases.s3.amazonaws.com/?delimiter=/&prefix=''${url#https://releases.nixos.org/}/"

    hred_code='contents key @.textContent'
    jq_code='
    def prefixof(str): . as $prefix | str | startswith($prefix);
    map(select(split(".") | last | prefixof($rev))) |
    if length == 1 then
      .[0]
    else
      error("Git revision must have exactly one match among the channel releases. Matches: \(.)")
    end'
    url="https://releases.nixos.org/$(curl -sSL "$url" | hred "$hred_code" | jq -r "$jq_code" --arg rev "$rev")/nixexprs.tar.xz"
    curl -sSL "$url" | xz -d | tar -xO --wildcards '*/programs.sqlite' > ${dbPath}
    echo "$rev" > ${revPath}
  '';
in
{
  options.my.customize.shell = mkEnableOption "shell customization";
  options.my.command-not-found.stateDir = mkOption {
    type = lib.types.path;
  };
  config = mkIf my.customize.shell {
    # undo default shellAliases
    environment.shellAliases = genAttrs [ "l" "ll" "ls" ] (_: mkOverride 999 null);

    # suggest packages to install for commands not in PATH
    programs.command-not-found.enable = true;

    # ensure the command -> package database is correct
    programs.command-not-found.dbPath = dbPath;
    systemd.services.programdb = {
      description = "Program Database Download";
      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${downloadDatabase} ${inputSpecs.nixpkgs.ref} ${inputs.nixpkgs.rev}";
        RemainAfterExit = true;
      };
    };
  };
}
