#! /usr/bin/env bash

set -euo pipefail
shopt -s nullglob dotglob

die() {
  printf "error: %s\n" "$1" >&2
  exit 1
}

parseopts() {
  # Global variable we create
  declare -gA opts=()

  # Accumulators for defining the option interface
  local shortopts=
  local longopts=
  local -a optionshelp=()

  set -- mkopts "$@"
  while true; do
    case "$1" in
      mkopts)
        optionshelp+=("-i," "--index" "Bring the index to its fixed point. May be combined with -w/--worktree.")
        shortopts+="i"
        longopts+="index,"
        opts[index]=
        ;;&
      -i|--index)
        opts[index]=1
        shift 1
        ;;

      mkopts)
        optionshelp+=("-w," "--worktree" "Bring the worktree to its fixed point. May be combined with -i/--index. If neither target is specified, this is the default.")
        shortopts+="w"
        longopts+="worktree,"
        opts[worktree]=
        ;;&
      -w|--worktree)
        opts[worktree]=1
        shift 1
        ;;
      --)
        if [ -z "${opts[index]}" ] && [ -z "${opts[worktree]}" ]; then
          opts[worktree]=1
        fi
        ;;&

      mkopts)
        optionshelp+=("-f," "--force" "Overwrite existing paths not listed in the manifest and paths that have been modified relative to the manifest.")
        shortopts+="f"
        longopts+="force,"
        opts[force]=
        ;;&
      -f|--force)
        opts[force]=1
        shift 1
        ;;

      mkopts)
        optionshelp+=("-k," "--keep" "Delete removed paths only from the manifest, leaving the files behind.")
        shortopts+="k"
        longopts+="keep,"
        opts[keep]=
        ;;&
      -k|--keep)
        opts[keep]=1
        shift 1
        ;;

      mkopts)
        optionshelp+=("-t <num>," "--tries <num>" "How many times to regenerate before giving up on finding a fixed point. Defaults to 5.")
        shortopts+="t:"
        longopts+="tries:,"
        opts[tries]=5
        ;;&
      -t|--tries)
        [ "$2" -gt 0 ] || die "bad argument to --tries, must be positive integer: $2"
        opts[tries]="$2"
        shift 2
        ;;

      mkopts)
        optionshelp+=("-h," "--help" "Show this help")
        shortopts+="h"
        longopts+="help,"
        ;;&
      -h|--help)
        local -i maxshort=0 maxlong=0
        for n in $(seq 0 3 $(( ${#optionshelp[@]} - 1 )));do
          maxshort=$(($maxshort>${#optionshelp[n]}?maxshort:${#optionshelp[n]}))
        done
        for n in $(seq 1 3 $(( ${#optionshelp[@]} - 1 )));do
          maxlong=$(($maxlong>${#optionshelp[n]}?maxlong:${#optionshelp[n]}))
        done

        echo Usage: "$progname" '[options]'
        echo Generates files and incorporates results back into a git repository until a fixed point is reached.
        echo
        echo Options:
        printf "  % ${maxshort}s % -${maxlong}s  %s\n" "${optionshelp[@]}"
        exit 0
        ;;

      --)
        [ $# -eq 1 ] || die "Positional arguments not accepted"
        break
        ;;

      mkopts)
        shift 1
        local progname
        progname="$(basename -- "$0")"
        local normalizedargs
        normalizedargs="$(getopt -s bash -n "$progname" -o "$shortopts" -l "${longopts%,}" -- "$@")"
        eval "set -- $normalizedargs"
        ;;
    esac
  done
}

cachecolors() {
  # Global variables we create
  declare -gA fg=()
  declare -g bold underline reset

  local -A colors=()
  colors[red]=1
  colors[green]=2
  colors[yellow]=3
  colors[magenta]=5
  colors[cyan]=6
  local term="${TERM:-dumb}"
  [ -t 1 ] || term=dumb
  local color
  for color in "${!colors[@]}"; do
    fg["$color"]="$(tput -T "$term" setaf "${colors["$color"]}")"
  done
  bold="$(tput -T "$term" bold)"
  underline="$(tput -T "$term" smul)"
  reset="$(tput -T "$term" sgr0)"
}

# hash_path <target> <path>
# Determines a git mode and object id for $path inside $target
# Also ensures the object id actually exists in the repo
# Sets global 'retval' to a string suitable for a line of 'git mktree' input describing the path
hash_path() {
  local target="$1" path="$2"
  [[ "$target" == @(eval|result|worktree|index) ]] || die "Bad target argument to 'hash_path': $target"

  local rootpath mode type hash name
  name="$(basename -- "$path")"
  case "$target" in
    index)
      if git ls-files -s --error-unmatch -- "$path" &>/dev/null; then
        if git cat-file -e :"$path" &>/dev/null; then
          hash="$(git ls-files -zs --full-name -- "$path" | cut -zsf1 | head -c -1)"
          mode="${hash%% *}"
          type=blob
          hash="${hash#* }"
          hash="${hash% 0}"
          [[ "$mode" =~ [0-7]+    ]] || die "failed to parse sensible mode from git ls-files output"
          [[ "$hash" =~ [0-9a-f]+ ]] || die "failed to parse sensible hash from git ls-files output"
        else
          mode=040000
          type=tree
          hash="$(git write-tree --prefix="$path")"
        fi
      else
        hash=
      fi
      ;;
    worktree)
      rootpath="$GIT_WORK_TREE"
      ;;&
    eval|result)
      rootpath="$tmpdir/$target"
      ;;&
    eval|result|worktree)
      if   [ -L "$rootpath/$path" ]; then
        mode=120000
        type=blob
        hash="$(readlink -n "$rootpath/$path" | git hash-object -w --stdin)"
      elif [ -f "$rootpath/$path" ]; then
        if [[ "$(stat --format="%a" "$rootpath/$path")" =~ (7|5|3|1)..$ ]]; then
          mode=100755
        else
          mode=100644
        fi
        type=blob
        hash="$(git hash-object -w --path="$path" "$rootpath/$path")"
      elif [ -d "$rootpath/$path" ]; then
        mode=040000
        type=tree

        local -a entries=()
        for f in "$rootpath/$path"/*; do # Note: nullglob and dotglob are important here
          hash_path "$target" "${f#"$rootpath/"}"
          [ -z "$retval" ] || entries+=("$retval")
        done
        if [ "${#entries[@]}" -gt 0 ]; then
          hash="$(printf "%s\x00" "${entries[@]}" | git mktree -z)"
        else
          hash=
        fi
      elif [ ! -e "$rootpath/$path" ]; then
        hash=
      else
        die "hash_path: exists, but not a symlink, normal file, or directory: $rootpath/$path"
      fi
      ;;
  esac

  declare -g retval
  if [ -n "$hash" ]; then
    printf -v retval "%s %s %s\t%s" "$mode" "$type" "$hash" "$name"
  else
    retval=
  fi
}

open() {
  local target="$1" fd prevpath moderec obidrec status modeact obidact path part lpath rpath fd2 link
  [[ "$target" == @(eval|result|worktree|index) ]] || die "Bad target argument to 'open': $target"

  [ ! -e $target.manifest ] || die "$target does not seem to have been properly closed"
  [ ! -e $target.manifest.changed  ] || die "$target does not seem to have been properly closed"
  [ ! -e $target.changed  ] || die "$target does not seem to have been properly closed"

  case "$target" in
    eval|result)
      if [ -e "$target/.generated-files-manifest" ]; then
        cat -- "$target/.generated-files-manifest" >$target.manifest.tmp
      else
        : >$target.manifest.tmp
      fi
      ;;&
    worktree)
      if [ -e "$GIT_WORK_TREE/.generated-files-manifest" ]; then
        cat -- "$GIT_WORK_TREE/.generated-files-manifest" >$target.manifest.tmp
      else
        : >$target.manifest.tmp
      fi
      ;;&
    index)
      if git cat-file -e :.generated-files-manifest &>/dev/null; then
        git cat-file --filters :.generated-files-manifest >$target.manifest.tmp
      else
        : >$target.manifest.tmp
      fi
      ;;&
    result)
      sed -E 's/^([^\x00\n]+)$/\x00\x00\1\//;t;Q1' -- $target.manifest.tmp > $target.manifest.tmp.part || die "malformed manifest in $target"
      mv -f $target.manifest.tmp{.part,}
      ;;&
    eval|worktree|index)
      sed -E 's/^([0-7]+) ([0-9a-f]+) ([^\x00\n]+)$/\1\x00\2\x00\3\//;t;Q1' -- $target.manifest.tmp > $target.manifest.tmp.part || die "malformed manifest in $target"
      mv -f $target.manifest.tmp{.part,}
      ;;&
  esac
  if ! LC_ALL=C sort -t'\0' -k3 --check=quiet $target.manifest.tmp; then
    [ "$target" == result ] && die "generated manifest in result was not properly sorted"
    printf "Sorting manifest in %s\n" "$target"
    LC_ALL=C sort -t'\0' -k3 $target.manifest.tmp > $target.manifest.tmp.part
    mv -f $target.manifest.tmp{.part,}
    touch $target.manifest.changed
  fi
  LC_ALL=C sort -t'\0' -k3 -u --check=quiet $target.manifest.tmp || die "manifest has repeated paths in $target"

  prevpath=""
  : {fd}< <(tr '\0' $'\x1f' <$target.manifest.tmp)
  while IFS=$'\x1f' read -ru $fd moderec obidrec path; do
    [ "$target" == result ] || [ -n "$moderec" ] || die "missing mode in $target/.generated-files-manifest"
    [ "$target" == result ] || [ -n "$obidrec" ] || die "missing object id in $target/.generated-files-manifest"
    if [[ "${path%/}" =~ (^|/)(|\.|\.\.)(/|$) ]]; then
      [[ "${path%/}" !=   /* ]] || die "path from $target/.generated-files-manifest is absolute: ${path%/}"
      [[ "${path%/}" != */   ]] || die "path from $target/.generated-files-manifest ends in /: ${path%/}"
      [[ "${path%/}" != *//* ]] || die "path from $target/.generated-files-manifest contains //: ${path%/}"
      [ -n "${path%/}" ] || die "missing path in $target/.generated-files-manifest"
      die "path from $target/.generated-files-manifest involves . or ..: ${path%/}"
    fi
    [[ "$path" != .git/* ]] || die "$target/.generated-files-manifest lists path inside .git: $path"
    if [ -n "$prevpath" ]; then
      [[ "$path" != "$prevpath"* ]] || die "non-disjoint paths in $target/.generated-files-manifest: $path, $prevpath"
      [[ "$prevpath" != "$path"* ]] || die "non-disjoint paths in $target/.generated-files-manifest: $prevpath, $path"
    fi
    prevpath="$path"

    part="${path%%/*}"
    lpath="$part"
    rpath="${path#"$part"}"
    rpath="${rpath#/}"
    rpath="${rpath%/}"
    while [ -n "$rpath" ]; do
      case "$target" in
        eval|result)
          [ ! -L "$target/$lpath" ] || die "path in $target/.generated-files-manifest follows symlink: $path"
          [ ! -f "$target/$lpath" ] || die "path in $target/.generated-files-manifest collides with file: $path"
          ;;
        worktree)
          [ ! -L "$GIT_WORK_TREE/$lpath" ] || die "path in $target/.generated-files-manifest follows symlink: $path"
          [ ! -f "$GIT_WORK_TREE/$lpath" ] || die "path in $target/.generated-files-manifest collides with file: $path"
          ;;
        index)
          ! git cat-file -e :"$lpath" 2>/dev/null || die die "path in $target/.generated-files-manifest collides with file/symlink: $path"
          ;;
      esac

      part="${rpath%%/*}"
      lpath="$lpath/$part"
      rpath="${rpath#"$part"}"
      rpath="${rpath#/}"
    done
    hash_path "$target" "${path%/}"
    if [ -n "$retval" ]; then
      [[ "$retval" =~ ([0-9]+)\ (blob|tree)\ ([0-9a-f]+)$'\t'(.+) ]] || die "bad result from hash_path"
      modeact="${BASH_REMATCH[1]}"
      obidact="${BASH_REMATCH[3]}"
    else
      modeact=
      obidact=
    fi
    if [ "$target" == result ]; then
      moderec="$modeact"
      obidrec="$obidact"
      status=clean
    else
      if [ "$moderec" == "$modeact" ] && [ "$obidrec" == "$obidact" ]; then
        status=clean
      else
        status=dirty
      fi
    fi
    printf "%s\x00%s\x00%s\x00%s\x00%s\x00%s\n" "$moderec" "$obidrec" "$status" "$modeact" "$obidact" "$path" >>$target.manifest.tmp.part
  done
  : {fd}<&-
  mv -f $target.manifest.tmp{.part,}
  mv -f $target.manifest{.tmp,}
}

flush() {
  local target="$1"
  [[ "$target" == @(eval|result|worktree|index) ]] || die "Bad target argument to 'flush': $target"

  if [ -e $target.manifest ] && [ -e $target.manifest.changed ]; then
    cut -d '' -f 1,2,6 < $target.manifest > $target.manifest.tmp.part
    mv -f $target.manifest.tmp{.part,}
    sed -i 's/\/$//' $target.manifest.tmp
    tr '\0' ' ' < $target.manifest.tmp > $target.manifest.tmp.part
    mv -f $target.manifest.tmp{.part,}
    if [ -s $target.manifest.tmp ]; then
      case "$target" in
        eval)
          cat $target.manifest.tmp > eval/.generated-files-manifest
          ;;
        worktree)
          cat $target.manifest.tmp > "$GIT_WORK_TREE/.generated-files-manifest"
          ;;
        index)
          hash="$(git hash-object -w --path=".generated-files-manifest" $target.manifest.tmp)"
          printf '%s %s\t%s\n' "100644" "$hash" ".generated-files-manifest" | git update-index --index-info
          ;;
        result)
          die "cannot write back to result"
          ;;
      esac
    else
      case "$target" in
        eval)
          rm -f eval/.generated-files-manifest
          ;;
        worktree)
          rm -f -- "$GIT_WORK_TREE/.generated-files-manifest"
          ;;
        index)
          git rm -q --cached --ignore-unmatch -- ".generated-files-manifest"
          ;;
        result)
          die "cannot write back to result"
          ;;
      esac
    fi
    rm -f $target.manifest.{tmp,changed}
    touch $target.changed
  fi
}

close() {
  local target="$1"
  [[ "$target" == @(eval|result|worktree|index) ]] || die "Bad target argument to 'close': $target"

  flush "$target"

  rm -f $target.manifest
}

update_from() {
  local source target fd prevpath oldmoderec oldobidrec oldstatus oldmodeact oldobidact newmoderec newobidrec newstatus newmodeact newobidact path targetchar dirtychar recchar actchar pathcolor actions
  source="$1"
  [[ "$source" == @(result) ]] || die "Bad source argument to 'update': $source"
  target="$2"
  [[ "$target" == @(eval|index|worktree) ]] || die "Bad target argument to 'update': $target"
  shift 2

  LC_ALL=C join -t'\0' -j6 -e '' -a1 -a2 -o '1.1,1.2,1.3,1.4,1.5,2.1,2.2,2.3,2.4,2.5,0' $target.manifest $source.manifest > manifest.combined

  : {fd}< <(tr '\0' $'\x1f' <manifest.combined)
  prevpath=""
  while IFS=$'\x1f' read -ru $fd oldmoderec oldobidrec oldstatus oldmodeact oldobidact newmoderec newobidrec newstatus newmodeact newobidact path; do
    if [ -n "$prevpath" ]; then
      [[ "$path" == "$prevpath"* ]] && die "non-disjoint paths when combining manifests from $target and $source: $path, $prevpath"
      [[ "$prevpath" == "$path"* ]] && die "non-disjoint paths when combining manifests from $target and $source: $prevpath, $path"
    fi
    prevpath="$path"
  done
  : {fd}<&-

  : {fd}< <(tr '\0' $'\x1f' <manifest.combined)
  while IFS=$'\x1f' read -ru $fd oldmoderec oldobidrec oldstatus oldmodeact oldobidact newmoderec newobidrec newstatus newmodeact newobidact path; do
    if [ -z "$oldstatus" ]; then
      # Path does not exist in target manifest, so it hasn't been hashed yet
      hash_path "$target" "${path%/}"
      if [ -n "$retval" ]; then
        [[ "$retval" =~ ([0-9]+)\ (blob|tree)\ ([0-9a-f]+)$'\t'(.+) ]] || die "bad result from hash_path"
        oldmodeact="${BASH_REMATCH[1]}"
        oldobidact="${BASH_REMATCH[3]}"
        oldstatus=dirty
      else
        oldmodeact=
        oldobidact=
        oldstatus=clean
      fi
    fi
    [[ "$oldstatus" == @(clean|dirty) ]] || die "bad value for oldstatus: $oldstatus"

    if [ -z "$newstatus" ]; then
      if [ "$source" == result ]; then
        newstatus=clean
      else
        # Path does not exist in source manifest, so it hasn't been hashed yet
        hash_path "$source" "${path%/}"
        if [ -n "$retval" ]; then
          [[ "$retval" =~ ([0-9]+)\ (blob|tree)\ ([0-9a-f]+)$'\t'(.+) ]] || die "bad result from hash_path"
          newmodeact="${BASH_REMATCH[1]}"
          newobidact="${BASH_REMATCH[3]}"
          newstatus=dirty
        else
          newmodeact=
          newobidact=
          newstatus=clean
        fi
      fi
    fi
    [[ "$newstatus" == @(clean|dirty) ]] || die "bad value for newstatus: $newstatus"

    # If target is dirty, don't do anything, unless --force is passed
    if [ "$oldstatus" == dirty ] && [ -z "${opts[force]}" ]; then
      if   [ -z "$oldobidact" ]; then
        echo "error: in manifest but does not exist, skipping: $target/$path" >&2
      elif [ -z "$oldobidrec" ]; then
        echo "error: exists but not in manifest, skipping: $target/$path" >&2
      else
        echo "error: hash mismatch with manifest, skipping: $target/$path" >&2
      fi

      # Set failure flag for later and skip to next path
      touch $target.failed
      continue
    fi

    # If source is dirty, don't do anything, even if --force is passed
    if [ "$newstatus" == dirty ]; then
      if   [ -z "$newobidact" ]; then
        echo "error: in manifest but does not exist, skipping: $source/$path" >&2
      elif [ -z "$newobidrec" ]; then
        echo "error: exists but not in manifest, skipping: $source/$path" >&2
      else
        echo "error: hash mismatch with manifest, skipping: $source/$path" >&2
      fi

      # Set failure flag for later and skip to next path
      touch $target.failed
      continue
    fi

    if [ "$oldstatus" == dirty ]; then
      actions=d
    else
      actions=-
    fi

    if [ "$oldmoderec" != "$newmoderec" ] || [ "$oldobidrec" != "$newobidrec" ] || [ "$oldmodeact" != "$newmodeact" ] || [ "$oldobidact" != "$newobidact" ]; then
      if [ -n "$oldobidrec" ]; then
        LC_ALL=C join -t'\0' -j6 -v2 -o '2.1,2.2,2.3,2.4,2.5,0' <(
          printf "%s\x00%s\x00%s\x00%s\x00%s\x00%s\n" "$oldmoderec" "$oldobidrec" "$oldstatus" "$oldmodeact" "$oldobidact" "$path"
        ) $target.manifest > $target.manifest.part
        mv -f $target.manifest{.part,}
        touch $target.manifest.changed

        if [ "$oldmoderec" != "$newmoderec" ] || [ "$oldobidrec" != "$newobidrec" ]; then
          actions+=r
        else
          actions+=-
        fi
      else
        actions+=-
      fi
      if [ -n "$newobidrec" ]; then
        LC_ALL=C sort -t'\0' -k6 -u <(
          printf "%s\x00%s\x00%s\x00%s\x00%s\x00%s\n" "$newmoderec" "$newobidrec" "$newstatus" "$newmodeact" "$newobidact" "$path"
        ) $target.manifest > $target.manifest.part
        mv -f $target.manifest{.part,}
        touch $target.manifest.changed

        if [ "$oldmoderec" != "$newmoderec" ] || [ "$oldobidrec" != "$newobidrec" ]; then
          actions+=c
        else
          actions+=-
        fi
      else
        actions+=-
      fi
    else
      actions+=--
    fi

    if [ "$oldmodeact" != "$newmodeact" ] || [ "$oldobidact" != "$newobidact" ]; then
      if [ -n "$oldobidact" ]; then
        if [ -n "$newobidact" ] || [ -z "${opts[keep]}" ]; then
          case "$target" in
            eval)
              rm -rf "eval/${path%/}"
              ;;
            worktree)
              rm -rf -- "$GIT_WORK_TREE/${path%/}"
              ;;
            index)
              git rm -qr --cached -- "${path%/}"
              ;;
            result)
              die "cannot modify result"
              ;;
          esac
          touch $target.changed

          actions+=r
        else
          actions+=-
        fi
      else
        actions+=-
      fi
      if [ -n "$newobidact" ]; then
        case "$target" in
          eval)
            mkdir -p "$(dirname "eval/${path%/}")"
            cp -PrT "$source/${path%/}" "eval/${path%/}"
            chmod -RP '-7677,+rwX' "eval/${path%/}"
            ;;
          worktree)
            mkdir -p -- "$(dirname -- "$GIT_WORK_TREE/${path%/}")"
            cp -PrT -- "$source/${path%/}" "$GIT_WORK_TREE/${path%/}"
            chmod -RP '-7677,+rwX' -- "$GIT_WORK_TREE/${path%/}"
            ;;
          index)
            if [ "$newmodeact" == 040000 ]; then
              git read-tree --prefix="$path" "$newobidact"
            else
              git update-index --add --cacheinfo "$newmodeact,$newobidact,${path%/}"
            fi
            ;;
          result)
            die "cannot modify result"
            ;;
        esac
        touch $target.changed

        actions+=c
      else
        actions+=-
      fi
    else
      actions+=--
    fi

    actions+=-
    case "$actions" in
      ------)
        continue
        ;;

      -????-)
        dirtychar=" "
        ;;&
      d????-)
        dirtychar="!"
        ;;&
      ?--??-)
        recchar=" "
        ;;&
      ?-c??-)
        recchar="+"
        ;;&
      ?rc??-)
        recchar="%"
        ;;&
      ?r-??-)
        recchar="-"
        ;;&
      ???---)
        actchar=" "
        ;;&
      ???-c-)
        actchar="+"
        ;;&
      ???rc-)
        actchar="%"
        ;;&
      ???r--)
        actchar="-"
        ;;&

      # Normal operations
      --c-c-)
        # Created
        pathcolor="${fg[green]}"
        ;;
      -r-r--)
        # Removed
        pathcolor="${fg[red]}"
        ;;
      -rcrc-)
        # Modified
        pathcolor="${fg[yellow]}"
        ;;

      -r----)
        # Removed with --keep active
        pathcolor="${fg[magenta]}"
        ;;

      # Forced operations
      d-crc-)
        # Created, overwriting dirty content
        pathcolor="${fg[green]}$bold$underline"
        ;;
      drcrc-)
        # Modified, overwriting dirty content
        pathcolor="${fg[yellow]}$bold$underline"
        ;;
      drc-c-)
        # Modified manifest, content was missing
        pathcolor="${fg[yellow]}$bold"
        ;;
      dr-r--)
        # Removed dirty content
        pathcolor="${fg[red]}$bold$underline"
        ;;

      # Cleaning operations
      d--rc-)
        # Untouched manifest, fixed content
        pathcolor="${fg[cyan]}$bold$underline"
        ;;
      d---c-)
        # Untouched manifest, recreated content
        pathcolor="${fg[cyan]}$bold"
        ;;

      # Manifest-only operations
      d-c---)
        # Created in manifest, dirty content happened to already be correct
        pathcolor="${fg[green]}"
        ;;
      drc---)
        # Modified manifest, dirty content happened to already be correct
        pathcolor="${fg[yellow]}"
        ;;
      dr----)
        # Removed from manifest, content already gone
        pathcolor="${fg[red]}"
        ;;
      *)
        # Others should all be impossible
        die "bad actions value: $actions"
        ;;
    esac
    case "$target" in
      eval)
        targetchar=' '
        ;;
      worktree)
        targetchar='W'
        ;;
      index)
        targetchar='I'
        ;;
    esac
    printf "%s%s%s%s %s%s%s\n" "$targetchar" "$dirtychar" "$recchar" "$actchar" "$pathcolor" "${path%/}" "$reset"
  done
  : {fd}<&-
  rm -f manifest.combined
}

find_fixed_point() {
  local target="$1"
  [[ "$target" == @(worktree|index) ]] || die "Bad target argument to 'find_fixed_point': $target"
  shift 1

  if [ -e eval ]; then
    rm -rf eval
  fi

  echo "Copying $target..."
  case "$target" in
    index)
      git checkout-index -a --prefix="$tmpdir/eval/"
      ;;
    worktree)
      mkdir -p eval
      pushd -- "$GIT_WORK_TREE" >/dev/null
      git ls-files -cz --full-name | { xargs -0r stat --printf="%n\0" -- 2>/dev/null || [ "$?" == 123 ]; } | xargs -0r cp --parents -Pt "$tmpdir/eval" --
      popd >/dev/null
      ;;
  esac
  open eval

  declare -i attempt=1
  while true; do
    echo "Building generated files from copy of $target..."
    close result
    rm -rf result
    pushd eval >/dev/null
    ./.generate-files "$tmpdir/result"
    popd >/dev/null
    open result

    update_from result eval
    flush eval
    [ -e eval.failed ] && break
    [ -e eval.changed ] || break
    rm -f eval.changed

    attempt+=1
    if [ $attempt -gt "${opts[tries]}" ]; then
      echo "Retry limit (${opts[tries]}) reached for $target, giving up on finding fixed point." >&2
      touch eval.failed
      break
    fi
  done

  close eval
  if [ -e eval.failed ]; then
    echo "Aborting due to earlier failure."
    rm eval.failed
    touch $target.failed
    exit 1
  fi

  if [ $attempt -le 1 ]; then
    # We didn't set 'changed' in the first run and immediately quit without an error
    echo "$target is already a fixed point. No need to write back."
  else
    # We set 'changed' at least once, so there's something to do
    echo "Fixed point of $target found. Writing back..."
    open $target
    update_from result $target
    close $target
  fi

  if   [ -e $target.failed ]; then
    echo "Writeback not fully successful."
    exit 1
  fi
}

parseopts "$@"
cachecolors

# Retain git environment
export       GIT_DIR="$(git rev-parse --path-format=absolute --git-dir)"
[ -v GIT_INDEX_FILE ] && [[ "$GIT_INDEX_FILE" != /* ]] && export GIT_INDEX_FILE="$PWD/$GIT_INDEX_FILE"
export GIT_WORK_TREE="$(git rev-parse --path-format=absolute --show-toplevel)"

# Avoid globbing in git commands since we'll be working with arbitrary data
export GIT_LITERAL_PATHSPECS=1

# Make a tmpdir and set a hook to automatically clean up after ourselves
unset tmpdir
cleanup() {
  if [ -v tmpdir ] && [ -d "$tmpdir" ]; then
    cd -- "$tmpdir"
    close index
    close worktree
    rm -rf -- "$tmpdir"
  fi
}
trap cleanup EXIT
tmpdir="$(mktemp -td regenerate-files-XXXXX)"
cd -- "$tmpdir"


for target in index worktree; do
  if [ -n "${opts[$target]}" ]; then
    (find_fixed_point $target) || touch $target.failed
  fi
done

for target in index worktree; do
  if [ -e $target.failed ]; then
    echo "${fg[red]}$target failed to reach fixed point!$reset"
  fi
done

if [ -e index.failed ] || [ -e worktree.failed ]; then
  exit 1
else
  exit 0
fi
