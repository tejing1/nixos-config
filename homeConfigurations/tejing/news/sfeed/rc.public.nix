{ my, pkgs, ... }:

let
  inherit (builtins) toFile;
  inherit (pkgs.lib) escapeShellArg;

  innocuousUserAgent = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/101.0.4951.64 Safari/537.36";
in
{
  # Basic, normal rss feeds.
  feeds."XKCD".url = https://xkcd.com/rss.xml;
  feeds."PINE64".url = https://www.pine64.org/feed/;

  # For when you want multiple feeds to download from the same url,
  # but not actually download repeatedly
  fetch.shared = {
    code = ''
      local file="$sfeedtmpdir/shared/$(basenc --base64url <<<"$2")"
      mkdir -p "$(dirname "$file")"
      while [ ! -f "$file" ]; do
        if lockfile-create -q --retry 0 "$file"; then
          _fetch "$@" > "$file.part" || { local err=$?; touch "$file.fail"; return $err; }
          mv -f "$file.part" "$file" || { local err=$?; touch "$file.fail"; return $err; }
          lockfile-remove "$file"
        else
          sleep 0.1
          [ -f "$file.fail" ] && return 1
        fi
      done
      cat "$file"'';
    inputs = [ pkgs.coreutils pkgs.lockfileProgs ];
  };

  # Useful for simple filters
  helper.has_category = {
    code = ''awk -F'\t' -v category="$1" -f '' + toFile "sfeed_has_category.awk" ''
      {
        split($9, cs, "|")
        for (i in cs)
          if (cs[i] == category) {
            print
            break
          }
      }
    '';
    inputs = [ pkgs.gawk ];
  };
  helper.title_starts_with = {
    code = ''awk -F'\t' -v titlestart="$1" -f '' + toFile "sfeed_title_starts_with.awk" ''
      {
        if (index($2,titlestart) == 1)
          print
      }
    '';
    inputs = [ pkgs.gawk ];
  };

  # Gets around cloudflare's bot detection, last time I checked
  fetch.imitate_browser = {
    code = ''
      curl --no-alpn -fsSLm 15 -A ${escapeShellArg innocuousUserAgent} "$2"'';
    inputs = [ pkgs.curl ];
  };
  fetch.imitate_browser_post = {
    code = ''
      curl --no-alpn -fsSLm 15 -A ${escapeShellArg innocuousUserAgent} -X POST "$2"'';
    inputs = [ pkgs.curl ];
  };

  # A good general pattern for scraping html pages
  helper.website_parse = {
    code = ''hred "$(<"$1")" | jq -rf "$2"'';
    inputs = [ my.pkgs.hred pkgs.jq ];
    execer = [ "cannot:${my.pkgs.hred}/bin/hred" ];
  };

  # Sources often specify dates in unhelpful formats. You can just
  # pass through their format to the tsv, then pipe it through this.
  helper.normalize_dates = {
    code = ''awk -F'\t' -v OFS=$'\t' -f '' + toFile "sfeed_process_dates.awk" ''
      BEGIN {
        PROCINFO["date -f- +%s", "pty"] = 1
      }
      {
        print $1 |& "date -f- +%s"
        "date -f- +%s" |& getline $1
        print
      }
    '';
    inputs = [ pkgs.gawk ];
  };

  # Fetch from crunchyroll beta api. Always pair with the crunchyroll parser.
  fetch.crunchyroll = {
    code = ''
      local api_domain="https://beta.crunchyroll.com"
      local initial_auth="Y3Jfd2ViOg=="

      #local initialdata="$(curl -sSL "$2" | hred '^ div#preload-data > script @.innerHTML' | jq -c '[capture("window.__INITIAL_STATE__ = (?<initial_state>[^\n]+);","window.__APP_CONFIG__ = (?<app_config>[^\n]+);")] | add | .[] |= fromjson')"
      #local api_domain="$(jq '.app_config.cxApiParams.apiDomain' -r <<<"$initialdata")"
      #local initial_auth="$(jq '.app_config.cxApiParams.anonClientId | "\(.):" | @base64' -r <<<"$initialdata")"

      local series_id="''${2#https://beta.crunchyroll.com/series/}"
      local series_id="''${series_id%%/*}"
      if [ "''${#series_id}" -ne 9 ] || [ -n "''${id//[A-Z0-9]/}" ]; then
        echo "Failed to parse url \"$2\": got series_id \"$series_id\"... count is \"''${#series_id}\" and collapsed is \"''${id//[A-Z0-9]/}\"" >&2
        return 1
      fi

      local file="$sfeedtmpdir/crunchyroll_policy"
      while [ ! -f "$file" ]; do
        if lockfile-create -q --retry 0 "$file"; then
          local restore_opts="$(shopt -po pipefail)"
          set -o pipefail
          local auth="$(curl -sSfH "Authorization: Basic $initial_auth" "$api_domain/auth/v1/token" -X POST -d grant_type=client_id | jq '"\(.token_type) \(.access_token)"' -r)" &&
            curl -sSfH "Authorization: $auth" "$api_domain/index/v2" > "$file.part" &&
            mv -f "$file.part" "$file" ||
            { local err=$?; touch "$file.fail"; return $err; }
          lockfile-remove "$file"
          eval "$restore_opts"
        else
          sleep 0.1
          [ -f "$file.fail" ] && return 1
        fi
      done

      local bucket="$(jq '.cms_beta // .cms | .bucket' -r "$file")"
      local params="$(jq '.cms_beta // .cms | @uri "Policy=\(.policy)&Signature=\(.signature)&Key-Pair-Id=\(.key_pair_id)"' -r "$file")"

      for season_id in $(curl -sS "$api_domain/cms/v2$bucket/seasons?series_id=$series_id" -G -d "$params" | jq '.items | map(select(.is_subbed) | .id) | join(" ")' -r); do
          curl -sS "$api_domain/cms/v2$bucket/episodes?season_id=$season_id" -G -d "$params" | jq '.items[]' -c
      done'';
    inputs = [ pkgs.curl pkgs.jq pkgs.lockfileProgs ];
  };
  # Parse crunchyroll beta api. Always pair with the crunchyroll fetcher.
  parse.crunchyroll = {
    code = ''
      jq '[ .episode_air_date, "S\(.season_number | tostring | (2 - length) * "0" + .)E\(.episode_number | tostring | (2 - length) * "0" + .) - \(.title)", "https://beta.crunchyroll.com/watch/\(.id)/\(.slug_title)", .description, "plain", .id, "", "", .season_id ] | @tsv' -r | normalize_dates'';
    inputs = [ pkgs.jq ];
  };
}
