#! /usr/bin/env bash

kill_dunstify () {
    if [ -n "$COPROC_PID" ]; then
        kill "$COPROC_PID"
        wait "$COPROC_PID" 2>/dev/null
    fi
}

replace_note () {
    kill_dunstify
    if [ -z "$notification_id" ]; then
        coproc dunstify -pb "$@"
    else
        coproc dunstify -pbr "$notification_id" "$@"
    fi
    read -u "${COPROC[0]}" notification_id
}

close_note () {
    kill_dunstify
    if [ -n "$notification_id" ]; then
        dunstify -C "$notification_id"
        unset notification_id
    fi
}
trap close_note EXIT

alter_note () {
    [ -n "$COPROC_PID" ] && replace_note "$@"
}

update_count () {
    prev_message_count="$message_count"
    message_count="$(for d in "${maildirs[@]}";do ls -A1q "$d/new/";done | wc -l)"
    if [ "$message_count" -eq 0 ]; then
        close_note
    elif [ "$message_count" -lt "$prev_message_count" ]; then
        alter_note -t 0 "You have $message_count new messages."
    elif [ "$message_count" -gt "$prev_message_count" ]; then
        replace_note -t 0 "You have $message_count new messages."
    fi
}

read_changed () {
    read -rd $'\0' -u $inotifyfd || return
    newbox="${REPLY%/???/}"
    for box in "${changed[@]}"; do
        [ "$box" == "$newbox" ] && return
    done
    changed+=( "$newbox" )
}

sync_changed () {
    local -A channel=(
        [fastmail/Inbox]=fastmail:INBOX
        [fastmail/Archive]=fastmail:Archive
        [fastmail/Drafts]=fastmail:Drafts
        [fastmail/Sent]=fastmail:Sent
        [fastmail/Spam]=fastmail:Spam
        [fastmail/Trash]=fastmail:Trash
        [yahoo/Sent]=yahoo-other:Sent
        [yahoo/Trash]=yahoo-other:Trash
        [yahoo/Archive]=yahoo-other:Archive
        [yahoo/Inbox]=yahoo-other:INBOX
        [yahoo/Spam]=yahoo-spam
        [yahoo/Drafts]=yahoo-drafts
        [gmail/Drafts]=gmail-other:Drafts
        [gmail/Spam]=gmail-other:Spam
        [gmail/Trash]=gmail-other:Trash
        [gmail/Inbox]=gmail-inbox
        [gmail/Sent]=gmail-sent
        [gmail/All]=gmail-all
    )
    local -a args=()
    for box in "${changed[@]}"; do
        args+=( "${channel[$box]}" )
    done
    mbsync -- "${args[@]}"
    changed=()
    update_count
}

cd /mnt/persist/tejing/mail/
exec {tmpfd}< <(find -type d -execdir test -d '{}/new' -a -d '{}/cur' -a -d '{}/tmp' ';' -print0 | sed -ze 's/^\.\///')
readarray -td $'\0' -u $tmpfd maildirs
unset tmpfd

[ "${#maildirs}" -eq 0 ] && { echo "No maildirs found!" >&2; exit 1; }

message_count=0
changed=( "${maildirs[@]}" )
exec {inotifyfd}< <(exec inotifywait -me create,move,delete,close_write,attrib --format '%w%0' --no-newline "${maildirs[@]/%//new/}" "${maildirs[@]/%//cur/}")
while true; do
    if read -rd $'\0' -u $inotifyfd -t 0; then
        # still some rapid-fire changes to read
        read_changed

    else
        # ran out of rapid-fire changes. update now
        sync_changed

        # don't reconnect too soon after syncing
        sleep 5

        # most of the idle time happens here
        read_changed || break

        # wait for multiple rapid-fire changes before updating
        sleep 1

    fi
done
