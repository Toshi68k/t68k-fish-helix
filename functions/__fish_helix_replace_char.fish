function __fish_helix_prepare_replace --description 'Helix: prepare replace character (r)'
    set -g __fish_helix_replace_start -1
    set -g __fish_helix_replace_len 0
    if commandline --selection-start >/dev/null 2>&1
        set -l sel (string join \n -- (commandline -s))
        set -l sel_start (commandline --selection-start)
        set -l sel_end (commandline --selection-end)
        set -g __fish_helix_replace_start (math "min($sel_start, $sel_end)")
        set -g __fish_helix_replace_len (string length -- "$sel")
    else
        set -g __fish_helix_replace_start (commandline -C)
        set -g __fish_helix_replace_len 1
    end
    set fish_bind_mode replace_one
    commandline -f repaint-mode
end

function __fish_helix_execute_replace --argument-names char --description 'Helix: execute character replace'
    set -l buf (string join \n -- (commandline -b))
    set -l len (string length -- "$buf")
    set -l r_start $__fish_helix_replace_start
    set -l r_len $__fish_helix_replace_len
    set -e __fish_helix_replace_start
    set -e __fish_helix_replace_len

    if test -z "$r_start" -o $r_start -lt 0
        set r_start (commandline -C)
        set r_len 1
    end

    if test $r_start -ge $len
        set fish_bind_mode default
        commandline -f repaint-mode
        return
    end

    set -l rep_str (string repeat -n $r_len -- "$char")

    set -l prefix ""
    if test $r_start -gt 0
        set prefix (string sub -s 1 -l $r_start -- "$buf" | string collect)
    end
    set -l suffix ""
    if test (math $r_start + $r_len) -lt $len
        set suffix (string sub -s (math $r_start + $r_len + 1) -- "$buf" | string collect)
    end

    set -l new_buf "$prefix$rep_str$suffix"
    commandline -f end-selection
    commandline -r -- "$new_buf"
    commandline -C $r_start
    set fish_bind_mode default
    commandline -f repaint-mode
end
