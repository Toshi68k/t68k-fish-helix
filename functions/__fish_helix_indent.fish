function __fish_helix_indent --description 'Helix: indent line or selection (>)'
    set -l count (__fish_helix_consume_count)
    set -l indent_spaces (string repeat -n $count -- "    ")
    set -l indent_len (string length -- "$indent_spaces")

    set -l buf (commandline -b | string collect)
    set -l lines (string split \n -- "$buf")
    set -l num_lines (count $lines)
    if test $num_lines -eq 0
        return
    end

    set -l is_selected 0
    set -l start_line 1
    set -l end_line 1
    set -l orig_cursor (commandline -C)

    set -l line_starts
    set -l line_ends
    set -l cur_pos 0
    for i in (seq $num_lines)
        set -a line_starts $cur_pos
        set -l line_len (string length -- "$lines[$i]")
        set -l end_pos (math "$cur_pos + $line_len")
        set -a line_ends $end_pos
        set cur_pos (math "$end_pos + 1")
    end

    set -l min_pos 0
    set -l max_pos 0

    if commandline --selection-start >/dev/null 2>&1
        set is_selected 1
        set -l sel_start (commandline --selection-start)
        set -l sel_end (commandline --selection-end)
        set min_pos (math "min($sel_start, $sel_end)")
        set max_pos (math "max($sel_start, $sel_end)")

        for i in (seq $num_lines)
            if test $min_pos -ge $line_starts[$i]
                set start_line $i
            end
            if test $max_pos -ge $line_starts[$i]
                set end_line $i
            end
        end

        if test $end_line -gt $start_line -a $max_pos -eq $line_starts[$end_line]
            set end_line (math "$end_line - 1")
        end
    else
        set start_line (commandline -L)
        if test -z "$start_line" -o $start_line -lt 1
            set start_line 1
        end
        if test $start_line -gt $num_lines
            set start_line $num_lines
        end
        set end_line $start_line
    end

    for i in (seq $start_line $end_line)
        set lines[$i] "$indent_spaces$lines[$i]"
    end

    set -l new_buf (string join \n -- $lines)
    commandline -r -- "$new_buf"

    if test $is_selected -eq 1
        set -l num_indented (math "$end_line - $start_line + 1")
        set -l total_added (math "$num_indented * $indent_len")
        set -l new_min $min_pos
        set -l new_max (math "$max_pos + $total_added")

        commandline -f end-selection
        commandline -C $new_min
        commandline -f begin-selection
        set -l diff (math "$new_max - $new_min")
        for i in (seq $diff)
            commandline -f forward-char
        end
        set fish_bind_mode visual
    else
        commandline -C (math "$orig_cursor + $indent_len")
        set fish_bind_mode default
    end

    commandline -f repaint-mode
end

function __fish_helix_unindent --description 'Helix: unindent line or selection (<)'
    set -l count (__fish_helix_consume_count)
    set -l buf (commandline -b | string collect)
    set -l lines (string split \n -- "$buf")
    set -l num_lines (count $lines)
    if test $num_lines -eq 0
        return
    end

    set -l is_selected 0
    set -l start_line 1
    set -l end_line 1
    set -l orig_cursor (commandline -C)

    set -l line_starts
    set -l line_ends
    set -l cur_pos 0
    for i in (seq $num_lines)
        set -a line_starts $cur_pos
        set -l line_len (string length -- "$lines[$i]")
        set -l end_pos (math "$cur_pos + $line_len")
        set -a line_ends $end_pos
        set cur_pos (math "$end_pos + 1")
    end

    set -l min_pos 0
    set -l max_pos 0

    if commandline --selection-start >/dev/null 2>&1
        set is_selected 1
        set -l sel_start (commandline --selection-start)
        set -l sel_end (commandline --selection-end)
        set min_pos (math "min($sel_start, $sel_end)")
        set max_pos (math "max($sel_start, $sel_end)")

        for i in (seq $num_lines)
            if test $min_pos -ge $line_starts[$i]
                set start_line $i
            end
            if test $max_pos -ge $line_starts[$i]
                set end_line $i
            end
        end

        if test $end_line -gt $start_line -a $max_pos -eq $line_starts[$end_line]
            set end_line (math "$end_line - 1")
        end
    else
        set start_line (commandline -L)
        if test -z "$start_line" -o $start_line -lt 1
            set start_line 1
        end
        if test $start_line -gt $num_lines
            set start_line $num_lines
        end
        set end_line $start_line
    end

    set -l total_removed 0
    set -l start_line_removed 0

    for i in (seq $start_line $end_line)
        set -l cur_line "$lines[$i]"
        set -l new_line "$cur_line"
        set -l line_removed 0
        for c in (seq $count)
            set -l before_len (string length -- "$new_line")
            set new_line (string replace -r '^ {1,4}|^\t' '' -- "$new_line")
            set -l after_len (string length -- "$new_line")
            set line_removed (math "$line_removed + $before_len - $after_len")
        end
        set lines[$i] "$new_line"
        set total_removed (math "$total_removed + $line_removed")
        if test $i -eq $start_line
            set start_line_removed $line_removed
        end
    end

    set -l new_buf (string join \n -- $lines)
    commandline -r -- "$new_buf"

    if test $is_selected -eq 1
        set -l new_min $min_pos
        if test $min_pos -gt $line_starts[$start_line]
            set new_min (math "max($line_starts[$start_line], $min_pos - $start_line_removed)")
        end
        set -l new_max (math "max($new_min, $max_pos - $total_removed)")

        commandline -f end-selection
        commandline -C $new_min
        commandline -f begin-selection
        set -l diff (math "$new_max - $new_min")
        for i in (seq $diff)
            commandline -f forward-char
        end
        set fish_bind_mode visual
    else
        set -l new_cur (math "max(0, $orig_cursor - $start_line_removed)")
        commandline -C $new_cur
        set fish_bind_mode default
    end

    commandline -f repaint-mode
end
