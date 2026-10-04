function __fish_helix_join_lines --argument-names mode --description 'Helix: join lines (J / Alt+J)'
    set -l sep " "
    if test "$mode" = "no_space"
        set sep ""
    end

    # Check if there is an active multiline selection
    if commandline --selection-start >/dev/null 2>&1
        set -l sel_start (commandline --selection-start)
        set -l sel_end (commandline --selection-end)
        set -l min_pos (math "min($sel_start, $sel_end)")
        set -l max_pos (math "max($sel_start, $sel_end)")
        set -l last_pos
        if test "$fish_cursor_selection_mode" = exclusive
            set last_pos $max_pos
        else
            set last_pos (math "$max_pos - 1")
        end

        set -l sel_lines (commandline -s)
        if test (count $sel_lines) -gt 1
            set -l joined_sel "$sel_lines[1]"
            for l in $sel_lines[2..-1]
                set -l trimmed (string replace -r '^[ \t]+' '' -- "$l")
                set joined_sel "$joined_sel$sep$trimmed"
            end

            set -l full_buf (commandline -b | string collect)
            set -l full_len (string length -- "$full_buf")

            set -l prefix ""
            if test $min_pos -gt 0
                set prefix (string sub -s 1 -l $min_pos -- "$full_buf" | string collect)
            end
            set -l suffix ""
            if test (math $last_pos + 1) -lt $full_len
                set suffix (string sub -s (math $last_pos + 2) -- "$full_buf" | string collect)
            end

            set -l new_buf "$prefix$joined_sel$suffix"
            commandline -f end-selection
            commandline -r -- "$new_buf"
            commandline -C $min_pos
            commandline -f repaint-mode
            return
        end
    end

    # Single-line selection or no selection: join current line with next line
    set -l lines (commandline -b)
    set -l total_lines (count $lines)
    if test $total_lines -le 1
        return
    end

    set -l cur_line (commandline -L)
    if test -z "$cur_line"; or test $cur_line -ge $total_lines
        return
    end

    set -l join_cursor 0
    if test $cur_line -gt 1
        for i in (seq (math $cur_line - 1))
            set -l line_len (string length -- "$lines[$i]")
            set join_cursor (math "$join_cursor + $line_len + 1")
        end
    end
    set -l cur_len (string length -- "$lines[$cur_line]")
    set join_cursor (math "$join_cursor + $cur_len")

    set -l next_line_idx (math $cur_line + 1)
    set -l trimmed_next (string replace -r '^[ \t]+' '' -- "$lines[$next_line_idx]")
    set lines[$cur_line] "$lines[$cur_line]$sep$trimmed_next"
    set -e lines[$next_line_idx]

    commandline -f end-selection
    commandline -r -- (string join \n -- $lines)
    commandline -C $join_cursor
    commandline -f repaint-mode
end
