function __fish_helix_find_word_bounds --argument-names type mode buf cursor_pos
    set -l len (string length -- "$buf")
    if test $len -eq 0
        return 1
    end
    if test $cursor_pos -ge $len
        set cursor_pos (math $len - 1)
    end

    set -l cur_char (string sub -s (math $cursor_pos + 1) -l 1 -- "$buf")

    set -l class 2
    if string match -qr "^\s" -- "$cur_char"
        set class 0
    else if test "$type" = "W"
        set class 1
    else if string match -qr "^[a-zA-Z0-9_]" -- "$cur_char"
        set class 1
    end

    set -l start $cursor_pos
    while test $start -gt 0
        set -l prev_char (string sub -s $start -l 1 -- "$buf")
        set -l prev_class 2
        if string match -qr "^\s" -- "$prev_char"
            set prev_class 0
        else if test "$type" = "W"
            set prev_class 1
        else if string match -qr "^[a-zA-Z0-9_]" -- "$prev_char"
            set prev_class 1
        end
        if test $prev_class -ne $class
            break
        end
        set start (math $start - 1)
    end

    set -l end (math $cursor_pos + 1)
    while test $end -lt $len
        set -l next_char (string sub -s (math $end + 1) -l 1 -- "$buf")
        set -l next_class 2
        if string match -qr "^\s" -- "$next_char"
            set next_class 0
        else if test "$type" = "W"
            set next_class 1
        else if string match -qr "^[a-zA-Z0-9_]" -- "$next_char"
            set next_class 1
        end
        if test $next_class -ne $class
            break
        end
        set end (math $end + 1)
    end

    if test "$mode" = "a" -a $class -ne 0
        while test $end -lt $len
            set -l next_char (string sub -s (math $end + 1) -l 1 -- "$buf")
            if not string match -qr "^\s" -- "$next_char"
                break
            end
            set end (math $end + 1)
        end
    end

    echo $start
    echo $end
end

function __fish_helix_textobject --argument-names target_mode char
    set -l buf (commandline -b)
    set -l cursor (commandline -C)
    set -l len (string length -- "$buf")
    if test $len -eq 0
        return
    end

    set -l start -1
    set -l end -1

    if test "$char" = "w" -o "$char" = "W"
        set -l bounds (__fish_helix_find_word_bounds "$char" "$target_mode" "$buf" "$cursor")
        if test (count $bounds) -lt 2
            return
        end
        set start $bounds[1]
        set end $bounds[2]
    else
        set -l pair (__fish_helix_find_pair "$char" "$buf" "$cursor")
        if test (count $pair) -lt 2
            return
        end
        set -l open_idx $pair[1]
        set -l close_idx $pair[2]

        if test "$target_mode" = "i"
            set start (math $open_idx + 1)
            set end $close_idx
        else
            set start $open_idx
            set end (math $close_idx + 1)
        end
    end

    set -l diff (math "$end - $start")
    commandline -f end-selection
    commandline -C $start
    if test $diff -gt 0
        commandline -f begin-selection
        for i in (seq $diff)
            commandline -f forward-char
        end
        set fish_bind_mode visual
    else
        set fish_bind_mode default
    end
    commandline -f repaint-mode
end
