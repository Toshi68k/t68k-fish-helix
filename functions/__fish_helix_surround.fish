function __fish_helix_get_surround_pair --argument-names char
    switch $char
        case '(' ')' 'b'
            echo '('\n')'
        case '[' ']' 'r'
            echo '['\n']'
        case '{' '}' 'B'
            echo '{'\n'}'
        case '<' '>'
            echo '<'\n'>'
        case '*'
            echo "$char"\n"$char"
    end
end

function __fish_helix_find_pair --argument-names char buf cursor_pos
    set -l pair (__fish_helix_get_surround_pair "$char")
    set -l open_c $pair[1]
    set -l close_c $pair[2]
    set -l len (string length -- "$buf")
    if test $len -eq 0
        return 1
    end

    if test "$open_c" != "$close_c"
        # Bracket matching with nesting stack
        set -l stack
        set -l pairs
        set -l i 0
        while test $i -lt $len
            set -l c (string sub -s (math $i + 1) -l 1 -- "$buf")
            if test "$c" = "$open_c"
                set -a stack $i
            else if test "$c" = "$close_c"
                if test (count $stack) -gt 0
                    set -l o $stack[-1]
                    set -e stack[-1]
                    set -a pairs "$o $i"
                end
            end
            set i (math $i + 1)
        end

        # Innermost enclosing pair (o <= cursor <= c, max o)
        set -l best_o -1
        set -l best_c -1
        for p in $pairs
            set -l parts (string split " " -- $p)
            set -l o $parts[1]
            set -l c $parts[2]
            if test $cursor_pos -ge $o -a $cursor_pos -le $c
                if test $o -gt $best_o
                    set best_o $o
                    set best_c $c
                end
            end
        end
        if test $best_o -ge 0
            echo $best_o
            echo $best_c
            return 0
        end

        # Next pair after cursor
        set -l next_o 999999
        set -l next_c -1
        for p in $pairs
            set -l parts (string split " " -- $p)
            set -l o $parts[1]
            set -l c $parts[2]
            if test $o -gt $cursor_pos -a $o -lt $next_o
                set next_o $o
                set next_c $c
            end
        end
        if test $next_c -ge 0
            echo $next_o
            echo $next_c
            return 0
        end
    else
        # Symmetric quote/delimiter matching
        set -l in_quote 0
        set -l open_idx -1
        set -l pairs
        set -l i 0
        set -l prev_char ""
        while test $i -lt $len
            set -l c (string sub -s (math $i + 1) -l 1 -- "$buf")
            if test "$c" = "$open_c" -a "$prev_char" != "\\"
                if test $in_quote -eq 0
                    set in_quote 1
                    set open_idx $i
                else
                    set in_quote 0
                    set -a pairs "$open_idx $i"
                end
            end
            set prev_char "$c"
            set i (math $i + 1)
        end

        for p in $pairs
            set -l parts (string split " " -- $p)
            if test $cursor_pos -ge $parts[1] -a $cursor_pos -le $parts[2]
                echo $parts[1]
                echo $parts[2]
                return 0
            end
        end
        for p in $pairs
            set -l parts (string split " " -- $p)
            if test $parts[1] -gt $cursor_pos
                echo $parts[1]
                echo $parts[2]
                return 0
            end
        end
    end
    return 1
end

function __fish_helix_surround_add --argument-names char
    set -l pair (__fish_helix_get_surround_pair "$char")
    set -l open $pair[1]
    set -l close $pair[2]

    if commandline --selection-start >/dev/null 2>&1
        set -l sel (commandline -s)
        set -l start (commandline --selection-start)
        set -l end (commandline --selection-end)
        set -l min_pos (math "min($start, $end)")
        set -l max_pos (math "max($start, $end)")
        set -l len (math "$max_pos - $min_pos")

        commandline -f end-selection
        commandline -C $min_pos
        for i in (seq $len)
            commandline -f delete-char
        end
        commandline -i "$open$sel$close"
        commandline -f repaint-mode
    else
        # If no selection, surround word under cursor
        commandline -f forward-word-end begin-selection backward-word
        set -l sel (commandline -s)
        set -l start (commandline --selection-start)
        set -l end (commandline --selection-end)
        set -l min_pos (math "min($start, $end)")
        set -l max_pos (math "max($start, $end)")
        set -l len (math "$max_pos - $min_pos")

        commandline -f end-selection
        commandline -C $min_pos
        for i in (seq $len)
            commandline -f delete-char
        end
        commandline -i "$open$sel$close"
        commandline -f repaint-mode
    end
    set fish_bind_mode default
end

function __fish_helix_surround_delete --argument-names char
    set -l buf (commandline -b)
    set -l cursor (commandline -C)
    set -l len (string length -- "$buf")
    if test $len -eq 0
        return
    end

    set -l pair (__fish_helix_find_pair "$char" "$buf" "$cursor")
    if test (count $pair) -lt 2
        return
    end

    set -l open_idx $pair[1]
    set -l close_idx $pair[2]

    set -l prefix ""
    if test $open_idx -gt 0
        set prefix (string sub -s 1 -l $open_idx -- "$buf")
    end
    set -l middle (string sub -s (math $open_idx + 2) -l (math $close_idx - $open_idx - 1) -- "$buf")
    set -l suffix ""
    if test (math $close_idx + 1) -lt $len
        set suffix (string sub -s (math $close_idx + 2) -- "$buf")
    end

    set -l new_buf "$prefix$middle$suffix"
    set -l new_cursor $cursor
    if test $cursor -gt $close_idx
        set new_cursor (math $cursor - 2)
    else if test $cursor -gt $open_idx
        set new_cursor (math $cursor - 1)
    end
    set -l new_len (string length -- "$new_buf")
    if test $new_cursor -ge $new_len
        set new_cursor (math $new_len - 1)
    end
    if test $new_cursor -lt 0
        set new_cursor 0
    end

    commandline -f end-selection
    commandline -r -- "$new_buf"
    commandline -C $new_cursor
    commandline -f repaint-mode
    set fish_bind_mode default
end

function __fish_helix_surround_replace_direct --argument-names old_char new_char
    set -l buf (commandline -b)
    set -l cursor (commandline -C)
    set -l len (string length -- "$buf")
    if test $len -eq 0
        return
    end

    set -l pair (__fish_helix_find_pair "$old_char" "$buf" "$cursor")
    if test (count $pair) -lt 2
        return
    end

    set -l open_idx $pair[1]
    set -l close_idx $pair[2]

    set -l new_pair (__fish_helix_get_surround_pair "$new_char")
    set -l new_open $new_pair[1]
    set -l new_close $new_pair[2]

    set -l prefix ""
    if test $open_idx -gt 0
        set prefix (string sub -s 1 -l $open_idx -- "$buf")
    end
    set -l middle (string sub -s (math $open_idx + 2) -l (math $close_idx - $open_idx - 1) -- "$buf")
    set -l suffix ""
    if test (math $close_idx + 1) -lt $len
        set suffix (string sub -s (math $close_idx + 2) -- "$buf")
    end

    set -l new_buf "$prefix$new_open$middle$new_close$suffix"
    commandline -f end-selection
    commandline -r -- "$new_buf"
    commandline -C $cursor
    commandline -f repaint-mode
    set fish_bind_mode default
end

function __fish_helix_surround_save_old --argument-names char
    set -g __fish_helix_surround_old "$char"
end

function __fish_helix_surround_replace --argument-names new_char
    set -l old_char "$__fish_helix_surround_old"
    set -g __fish_helix_surround_old ""
    __fish_helix_surround_replace_direct "$old_char" "$new_char"
end
