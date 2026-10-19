function __fish_helix_delete --argument-names reg --description 'Helix: delete selection or char under cursor (d)'
    if test -z "$reg"
        set reg (__fish_helix_consume_register)
    else
        set -e __fish_helix_register
        set -e __fish_helix_prev_mode
    end

    set -l buf (commandline -b | string collect)
    set -l text ""
    if commandline --selection-start >/dev/null 2>&1
        set -l sel_start (commandline --selection-start)
        set -l sel_end (commandline --selection-end)
        set -l min_pos (math "min($sel_start, $sel_end)")
        set -l max_pos (math "max($sel_start, $sel_end)")
        set -l sel_len (math "$max_pos - $min_pos")
        if test $sel_len -le 0
            set sel_len 1
        end
        set text (string sub -s (math $min_pos + 1) -l $sel_len -- "$buf")
    else
        set -l pos (commandline -C)
        set text (string sub -s (math $pos + 1) -l 1 -- "$buf")
    end

    __fish_helix_set_register "$reg" "$text"

    if test "$reg" = '_' -o "$reg" = '+' -o (string match -qr '^[a-zA-Z0-9]' -- "$reg")
        __fish_helix_delete_noyank
    else
        if commandline --selection-start >/dev/null 2>&1
            commandline -f kill-selection end-selection repaint-mode
        else
            commandline -f delete-char repaint-mode
        end
    end

    set fish_bind_mode default
end

function __fish_helix_delete_noyank --description 'Helix: delete selection without yanking (Alt-d)'
    if commandline --selection-start >/dev/null 2>&1
        set -l start (commandline --selection-start)
        set -l end (commandline --selection-end)
        set -l len (math "abs($end - $start)")
        if test $len -eq 0
            set len 1
        end
        commandline -f end-selection
        for i in (seq $len)
            commandline -f delete-char
        end
        commandline -f repaint-mode
    else
        commandline -f delete-char repaint-mode
    end
    set fish_bind_mode default
end
