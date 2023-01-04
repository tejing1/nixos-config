#! /usr/bin/env nix-shell
#! nix-shell -p inotify-tools findutils coreutils bash
#! nix-shell -i bash

export SFEED_URL_FILE=~/.sfeed/read_items

exec {feedsfd}< <(find ~/.sfeed/feeds -type f -print0 | sort -z)
readarray -d '' -t -u $feedsfd feeds
exec {feedsfd}<&-
unset feedsfd

sfeed_curses "${feeds[@]}" & uipid="$!"

(
    exec {inotifyfd}< <(exec inotifywait -qme create,move,delete,close_write,attrib --format '%w%0' --no-newline ~/.sfeed/feeds/)
    inotifypid="$!"
    trap 'kill $inotifypid' EXIT

    while true; do
        if read -rd $'\0' -u $inotifyfd -t 0; then
            read -rd $'\0' -u $inotifyfd
        else
            newsums="$(sha256sum ~/.sfeed/feeds/* | sort)"
            if [ "$newsums" != "$sums" ]; then
                sums="$newsums"
                kill -SIGHUP $uipid
            fi;
            read -rd $'\0' -u $inotifyfd || break;
            sleep 5;
        fi;
    done
) & watchpid="$!"
trap 'kill $watchpid' EXIT

wait $uipid
