# Paste functions for Helix keybindings (p / P)

function __fish_helix_paste_after --argument-names reg --description 'Helix: paste register contents after cursor (p)'
    if test -z "$reg"
        set reg (__fish_helix_consume_register)
    end
    set -l count (__fish_helix_consume_count)

    if test "$reg" = '_'
        return
    end

    set -l text (__fish_helix_get_register "$reg")

    # If default register and text is empty, fall back to standard fish yank
    if test "$reg" = '"' -a -z "$text"
        set -g fish_cursor_end_mode exclusive
        commandline -f forward-char
        set -g fish_cursor_end_mode inclusive
        for i in (seq $count)
            commandline -f yank
        end
        return
    end

    if test -z "$text"
        return
    end

    if test $count -gt 1
        set text (string repeat -n $count -- "$text")
    end

    set -l buf (commandline -b | string collect)
    set -l buf_len (string length -- "$buf")
    set -l text_len (string length -- "$text")

    # If selection is active, replace selection
    if commandline --selection-start >/dev/null 2>&1
        set -l sel_start (commandline --selection-start)
        set -l sel_end (commandline --selection-end)
        set -l min_pos (math "min($sel_start, $sel_end)")
        set -l max_pos (math "max($sel_start, $sel_end)")
        set -l sel_len (math "$max_pos - $min_pos")
        if test $sel_len -le 0
            set sel_len 1
        end

        set -l prefix ""
        if test $min_pos -gt 0
            set prefix (string sub -s 1 -l $min_pos -- "$buf" | string collect)
        end
        set -l suffix (string sub -s (math $min_pos + $sel_len + 1) -- "$buf" | string collect)
        set -l new_buf "$prefix$text$suffix"

        commandline -f end-selection
        commandline -r -- "$new_buf"
        commandline -C (math "max(0, $min_pos + $text_len - 1)")
        set fish_bind_mode default
        commandline -f repaint-mode
        return
    end

    # Normal paste after cursor
    set -l pos (commandline -C)
    set -l insert_pos $pos
    if test $buf_len -gt 0
        set insert_pos (math "$pos + 1")
    end

    set -l prefix ""
    if test $insert_pos -gt 0
        set prefix (string sub -s 1 -l $insert_pos -- "$buf" | string collect)
    end
    set -l suffix ""
    if test $insert_pos -lt $buf_len
        set suffix (string sub -s (math $insert_pos + 1) -- "$buf" | string collect)
    end

    set -l new_buf "$prefix$text$suffix"
    commandline -r -- "$new_buf"
    commandline -C (math "max(0, $insert_pos + $text_len - 1)")
    set fish_bind_mode default
    commandline -f repaint-mode
end

function __fish_helix_paste_before --argument-names reg --description 'Helix: paste register contents before cursor (P)'
    if test -z "$reg"
        set reg (__fish_helix_consume_register)
    end
    set -l count (__fish_helix_consume_count)

    if test "$reg" = '_'
        return
    end

    set -l text (__fish_helix_get_register "$reg")

    if test "$reg" = '"' -a -z "$text"
        for i in (seq $count)
            commandline -f yank
        end
        return
    end

    if test -z "$text"
        return
    end

    if test $count -gt 1
        set text (string repeat -n $count -- "$text")
    end

    set -l buf (commandline -b | string collect)
    set -l buf_len (string length -- "$buf")
    set -l text_len (string length -- "$text")

    # If selection is active, replace selection
    if commandline --selection-start >/dev/null 2>&1
        set -l sel_start (commandline --selection-start)
        set -l sel_end (commandline --selection-end)
        set -l min_pos (math "min($sel_start, $sel_end)")
        set -l max_pos (math "max($sel_start, $sel_end)")
        set -l sel_len (math "$max_pos - $min_pos")
        if test $sel_len -le 0
            set sel_len 1
        end

        set -l prefix ""
        if test $min_pos -gt 0
            set prefix (string sub -s 1 -l $min_pos -- "$buf" | string collect)
        end
        set -l suffix (string sub -s (math $min_pos + $sel_len + 1) -- "$buf" | string collect)
        set -l new_buf "$prefix$text$suffix"

        commandline -f end-selection
        commandline -r -- "$new_buf"
        commandline -C (math "max(0, $min_pos + $text_len - 1)")
        set fish_bind_mode default
        commandline -f repaint-mode
        return
    end

    # Normal paste before cursor
    set -l pos (commandline -C)
    set -l insert_pos $pos

    set -l prefix ""
    if test $insert_pos -gt 0
        set prefix (string sub -s 1 -l $insert_pos -- "$buf" | string collect)
    end
    set -l suffix ""
    if test $insert_pos -lt $buf_len
        set suffix (string sub -s (math $insert_pos + 1) -- "$buf" | string collect)
    end

    set -l new_buf "$prefix$text$suffix"
    commandline -r -- "$new_buf"
    commandline -C (math "max(0, $insert_pos + $text_len - 1)")
    set fish_bind_mode default
    commandline -f repaint-mode
end
