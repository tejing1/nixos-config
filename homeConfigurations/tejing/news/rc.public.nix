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
    code = ''
      # Pop first 2 arguments into local vars. Additional args go to json_parse.
      local basesiteurl="$1" hred_source="$2"; shift 2

      # Temporarily set pipefail
      local restore_opts="$(shopt -po pipefail)";set -o pipefail

      # Extract json datastructures from html
      hred -u "$basesiteurl" -f "$hred_source" -c |

      # Continue like you would for a json api
      json_parse "$@"

      # Restore pipefail setting and return exit code from pipeline
      local retval="$?";eval "$restore_opts";return "$retval"'';
    inputs = [ my.pkgs.hred pkgs.jq ];
    execer = [ "cannot:${my.pkgs.hred}/bin/hred" ];
  };

  # A good general pattern for scraping json apis
  helper.json_parse = {
    code = ''
      # Pop first argument into local var. Additional args go to jq.
      local jq_source="$1"; shift 1

      # Temporarily set pipefail
      local restore_opts="$(shopt -po pipefail)";set -o pipefail

      # Process json into TSV
      jq -f "$jq_source" -r "$@" |

      # Parse human-readable dates into unix epoch seconds
      normalize_dates

      # Restore pipefail setting and return exit code from pipeline
      local retval="$?";eval "$restore_opts";return "$retval"'';
    inputs = [ my.pkgs.hred pkgs.jq ];
    execer = [ "cannot:${my.pkgs.hred}/bin/hred" ];
  };

  # Sources often specify dates in unhelpful formats. You can just
  # pass through their format to the tsv, then pipe it through this.
  helper.normalize_dates = {
    code = ''awk -F'\t' -v OFS=$'\t' -f '' + pkgs.writeText "sfeed_process_dates.awk" ''
      BEGIN {
        datecmd = "${pkgs.coreutils}/bin/date -f- +%s"
        PROCINFO[datecmd, "pty"] = 1
      }
      {
        if ($1 !~ /^[0-9]+$/) {
          print $1 |& datecmd
          datecmd |& getline $1
        }
        print
      }
    '';
    inputs = [ pkgs.gawk ];
  };

  # Helps preserve correct sorting when many articles have identical
  # timestamps, but the parser order is the intended order.
  helper.force_increasing_dates = {
    code = ''awk -F'\t' -v OFS=$'\t' -f '' + toFile "sfeed_force_decreasing_dates.awk" ''
      BEGIN {
        prev = 0
      }
      {
        if (strtonum($1) <= prev)
          $1 = prev + 1
        print
        prev = strtonum($1)
      }
    '';
    inputs = [ pkgs.gawk ];
  };

  # Reversing the file before and after allows many timestamps at,
  # say, 00:00 on the same day to all stay within that day.  It also
  # ensures that timestamps do not change so long as backdated entries
  # are not added before existing entries.
  helper.force_decreasing_dates = {
    code = ''tac | force_increasing_dates | tac'';
  };

  # Fetch from crunchyroll api. Always pair with the crunchyroll parser.
  fetch.crunchyroll = {
    code = ''
      local series_id="''${2#https://www.crunchyroll.com/series/}"
      local series_id="''${series_id%%/*}"
      if [ "''${#series_id}" -ne 9 ] || [ -n "''${id//[A-Z0-9]/}" ]; then
        echo "Failed to parse url \"$2\": got series_id \"$series_id\"... count is \"''${#series_id}\" and collapsed is \"''${id//[A-Z0-9]/}\"" >&2
        return 1
      fi

      local cookiefile="$sfeedtmpdir/crunchyroll_cookies"
      local policyfile="$sfeedtmpdir/crunchyroll_policy"
      local initialdatafile="$sfeedtmpdir/crunchyroll_initialdata"
      local failurefil="$sfeedtmpdir/crunchyroll_failure"
      while [ ! -f "$policyfile" ]; do
        if lockfile-create -q --retry 0 "$policyfile"; then
          local restore_opts="$(shopt -po pipefail)"
          set -o pipefail

          # We need the cookies from this request in order for auth to work
          curl -c "$cookiefile" --no-alpn -fsSLm 15 -A ${escapeShellArg innocuousUserAgent} "https://www.crunchyroll.com" | hred '^ div#preload-data > script @.innerHTML' | jq -c '[capture("window.__INITIAL_STATE__ = (?<initial_state>[^\n]+);","window.__APP_CONFIG__ = (?<app_config>[^\n]+);")] | add | .[] |= fromjson' > "$initialdatafile"
          local api_domain="$(jq '.app_config.cxApiParams.apiDomain' -r "$initialdatafile")"
          local initial_auth="$(jq '.app_config.cxApiParams.anonClientId | "\(.):" | @base64' -r "$initialdatafile")"

          local auth=""
          auth="$(curl -b "$cookiefile" -c "$cookiefile" --no-alpn -fsSLm 15 -A ${escapeShellArg innocuousUserAgent} -H "Authorization: Basic $initial_auth" "$api_domain/auth/v1/token" -X POST -d grant_type=client_id | jq '"\(.token_type) \(.access_token)"' -r)" &&
            curl -b "$cookiefile" -c "$cookiefile" --no-alpn -fsSLm 15 -A ${escapeShellArg innocuousUserAgent} -H "Authorization: $auth" "$api_domain/index/v2" > "$policyfile.part" &&
            mv -f "$policyfile.part" "$policyfile" ||
            { local err=$?; touch "$failurefile"; eval "$restore_opts"; return $err; }
          lockfile-remove "$policyfile"
          eval "$restore_opts"
        else
          sleep 0.1
          [ -f "$failurefile" ] && return 1
        fi
      done

      local api_domain=""
      api_domain="$(jq '.app_config.cxApiParams.apiDomain' -r "$initialdatafile")"
      local bucket=""
      bucket="$(jq '.cms_web | .bucket' -r "$policyfile")" || return 1
      local params=""
      params="$(jq '.cms_web | @uri "Policy=\(.policy)&Signature=\(.signature)&Key-Pair-Id=\(.key_pair_id)"' -r "$policyfile")" || return 1

      local restore_opts="$(shopt -po pipefail)"
      set -o pipefail
      local seasons=""
      seasons="$(curl -b "$cookiefile" -c "$cookiefile" --no-alpn -fsSLm 15 -A ${escapeShellArg innocuousUserAgent} "$api_domain/cms/v2$bucket/seasons?series_id=$series_id" -G -d "$params" | jq '.items | map(select(.is_subbed) | .id) | join(" ")' -r)" || { eval "$restore_opts"; return 1; }
      for season_id in $seasons; do
          curl -b "$cookiefile" -c "$cookiefile" --no-alpn -fsSLm 15 -A ${escapeShellArg innocuousUserAgent} "$api_domain/cms/v2$bucket/episodes?season_id=$season_id" -G -d "$params" | jq '.items[]' -c || { eval "$restore_opts"; return 1; }
      done
      eval "$restore_opts"'';
    inputs = [ pkgs.curl pkgs.jq pkgs.lockfileProgs ];
  };
  # Parse crunchyroll api. Always pair with the crunchyroll fetcher.
  parse.crunchyroll = {
    code = ''
      jq '[ .episode_air_date, "S\(.season_number | tostring | (2 - length) * "0" + .)E\(.episode_number | tostring | (2 - length) * "0" + .) - \(.title)", "https://www.crunchyroll.com/watch/\(.id)/\(.slug_title)", .description, "plain", .id, "", "", .season_id ] | @tsv' -r | normalize_dates'';
    inputs = [ pkgs.jq ];
  };

  # Fetch from mangadex api. Always pair with the mangadex parser.
  fetch.mangadex = {
    code = ''
      local offset=0 limit=100
      local total newtotal
      id="''${2#https://mangadex.org/title/}"
      if [ "$id" == "$2" ]; then
        echo "Could not parse url: $2" >&2
        return 1
      fi
      id="''${id%%/*}"
      if [ "''${id/#[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]-[0-9a-f][0-9a-f][0-9a-f][0-9a-f]-[0-9a-f][0-9a-f][0-9a-f][0-9a-f]-[0-9a-f][0-9a-f][0-9a-f][0-9a-f]-[0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f][0-9a-f]}" != "" ]; then
        echo "Could not parse url: $2" >&2
        exit 1 # not return, because we're in a subshell
      fi
      url="https://api.mangadex.org/manga/$id/feed?includes\[\]=scanlation_group&order\[chapter\]=desc"
      while [ -z "$total" ] || [ "$offset" -lt "$total" ]; do
        exec {fd}< <(curl -sSf "$url&limit=$limit&offset=$offset" | jq 'if .result == "ok" and .response == "collection" then .total, (.data | length), .data[] else -1, error("Bad response: \(.)") end' -rc)
        read -u $fd -r newtotal
        if ! [ "$newtotal" -ge 0 ]; then
          echo "Bad response, aborting fetch" >&2
          exec {fd}<&-
          return 1
        fi
        [ -z "$total" ] && total="$newtotal"
        if ! [ "$newtotal" -eq "$total" ]; then
          echo "Reported total malformed or changed! Aborting fetch" >&2
          exec {fd}<&-
          return 1
        fi
        read -u $fd -r count
        if ! [ "$count" -ge 0 ]; then
          echo "Negative or malformed count; misaligned reads? Aborting fetch" >&2
          exec {fd}<&-
          return 1
        fi
        if ! [ "$count" -ne 0 ] && ! [ "$offset" -eq "$total" ]; then
          echo "Zero count, haven't reached total, aborting fetch" >&2
          exec {fd}<&-
          return 1
        fi
        cat <&$fd
        exec {fd}<&-
        offset=$((offset + count))
      done'';
  };
  # Parse mangadex api. Always pair with the mangadex fetcher.
  parse.mangadex = {
    code = ''json_parse '' + toFile "mangadex.jq" ''
      select (.attributes.translatedLanguage == "en") |
      .groups = ([.relationships[] | select(.type == "scanlation_group") | .attributes.name] | join(" & ")) |
      [ .attributes.createdAt, "\(.attributes.chapter) - \(.attributes.title | if . == "" or . == null then "No Title" else . end) (\(.groups))", "https://mangadex.org/chapter/\(.id)", "", "", .id, .groups, "", "" ] | @tsv
    '';
  };

  # Parse nyaa.si
  parse.nyaa = {
    code = ''website_parse "$3" ${toFile "nyaa.hred" ''
      table.torrent-list > tbody > tr {
        ^:scope > td:nth-child(2) > a:not(.comments) ...{
          @.textContent => title,
          @.href => link
        },
        ^:scope > td:nth-child(5) @data-timestamp => timestamp,
        ^:scope > td:nth-child(3) > a[href^=magnet] @.href => magnet
      }
    ''} ${toFile "nyaa.jq" ''
      [ .timestamp, .title, .link, "", "", .link, "", .magnet, "" ] | @tsv
    ''}'';
  };
}
