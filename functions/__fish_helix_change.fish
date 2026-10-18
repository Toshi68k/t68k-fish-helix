function __fish_helix_change --argument-names reg --description 'Helix: change selection or char under cursor (c)'
    if test -z "$reg"
        set reg (__fish_helix_consume_register)
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

    set fish_bind_mode insert
end

function __fish_helix_change_noyank --description 'Helix: change without yanking (Alt-c)'
    __fish_helix_delete_noyank
    set fish_bind_mode insert
end
