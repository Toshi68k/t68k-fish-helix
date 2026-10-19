function __fish_helix_yank --argument-names reg --description 'Helix: yank selection or char under cursor (y)'
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

    # Store text into selected register
    __fish_helix_set_register "$reg" "$text"

    # Also sync into Fish standard kill-ring unless black hole register was explicitly selected
    if test "$reg" != '_'
        set -g fish_cursor_end_mode exclusive
        if commandline --selection-start >/dev/null 2>&1
            commandline -f kill-selection yank end-selection
        else
            commandline -f begin-selection forward-char kill-selection yank backward-char end-selection
        end
        set -g fish_cursor_end_mode inclusive
    else
        commandline -f end-selection
    end

    set fish_bind_mode default
    commandline -f repaint-mode
end
