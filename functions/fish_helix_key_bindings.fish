# ==============================================================================
# Helper functions for Helix keybindings
# Defining these here guarantees they are always available when
# fish_helix_key_bindings is loaded, regardless of how files were sourced.
# ==============================================================================

function __fish_helix_arg_digit --description 'Accumulate a digit for repeat counts'
    set -g __fish_helix_count "$__fish_helix_count$argv[1]"
end

function __fish_helix_consume_count --description 'Consume and reset accumulated count'
    if test -n "$__fish_helix_count"
        set -l count $__fish_helix_count
        set -g __fish_helix_count
        echo $count
    else
        echo 1
    end
end

function __fish_helix_run_count --description 'Run a motion or command N times based on count prefix'
    set -l count (__fish_helix_consume_count)
    for i in (seq $count)
        if functions -q -- $argv[1]
            $argv
        else
            commandline -f $argv
        end
    end
end

# Helper: categorize character into word class
# class 0: whitespace (\s)
# class 1: word character ([a-zA-Z0-9_] for w/b/e; all non-whitespace for W/B/E)
# class 2: punctuation / symbol character (everything else, e.g. ", =, -, (, etc.)
function __fish_helix_char_class --argument-names type ch
    if string match -qr '^\s' -- "$ch"
        echo 0
        return
    end
    if test "$type" = "w" -o "$type" = "b" -o "$type" = "e"
        if string match -qr '^[a-zA-Z0-9_]' -- "$ch"
            echo 1
        else
            echo 2
        end
    else
        echo 1
    end
end

# Helper: find end index of next word/BIGWORD (inclusive index)
function __fish_helix_find_next_word_end --argument-names type buf cursor_pos
    set -l len (string length -- "$buf")
    if test $len -eq 0
        echo $cursor_pos
        return
    end
    if test $cursor_pos -ge $len
        echo (math $len - 1)
        return
    end

    set -l pos $cursor_pos

    # If on whitespace, advance past whitespace first
    while test $pos -lt $len
        set -l ch (string sub -s (math $pos + 1) -l 1 -- "$buf")
        if not string match -qr '^\s' -- "$ch"
            break
        end
        set pos (math $pos + 1)
    end
    if test $pos -ge $len
        echo (math $len - 1)
        return
    end

    set -l word_start $pos
    set -l cur_char (string sub -s (math $pos + 1) -l 1 -- "$buf")
    set -l class (__fish_helix_char_class "$type" "$cur_char")

    # Advance past characters of the same word class
    while test $pos -lt $len
        set -l ch (string sub -s (math $pos + 1) -l 1 -- "$buf")
        set -l ch_class (__fish_helix_char_class "$type" "$ch")
        if test $ch_class -ne $class
            break
        end
        set pos (math $pos + 1)
    end

    # Advance past trailing whitespace
    while test $pos -lt $len
        set -l ch (string sub -s (math $pos + 1) -l 1 -- "$buf")
        if not string match -qr '^\s' -- "$ch"
            break
        end
        set pos (math $pos + 1)
    end

    if test $pos -gt $word_start
        echo (math $pos - 1)
    else
        echo $word_start
    end
end

# Helper: find start index of previous word/BIGWORD
function __fish_helix_find_prev_word_start --argument-names type buf pos
    set -l len (string length -- "$buf")
    if test $len -eq 0 -o $pos -le 0
        echo 0
        return
    end

    set -l cur $pos
    if test $cur -ge $len
        set cur (math $len - 1)
    end

    # Step 1: If on whitespace, skip all whitespace backwards
    while test $cur -gt 0
        set -l ch (string sub -s (math $cur + 1) -l 1 -- "$buf")
        if not string match -qr '^\s' -- "$ch"
            break
        end
        set cur (math $cur - 1)
    end

    set -l ch (string sub -s (math $cur + 1) -l 1 -- "$buf")
    set -l class (__fish_helix_char_class "$type" "$ch")

    # Step 2: Skip characters of the same word class backwards
    while test $cur -gt 0
        set -l prev_ch (string sub -s $cur -l 1 -- "$buf")
        set -l prev_class (__fish_helix_char_class "$type" "$prev_ch")
        if test $prev_class -ne $class
            break
        end
        set cur (math $cur - 1)
    end

    echo $cur
end

# Helix Normal mode movements (Selection-First):
function __fish_helix_normal_w --description 'Helix normal mode: select next word start (w)'
    set -l count (__fish_helix_consume_count)
    set -l buf (commandline -b)
    set -l cursor (commandline -C)
    set -l len (string length -- "$buf")
    if test $len -eq 0 -o $cursor -ge $len
        return
    end

    set -l start $cursor
    if commandline --selection-start >/dev/null 2>&1
        set -l sel_start (commandline --selection-start)
        set -l sel_end (commandline --selection-end)
        set -l max_sel (math "max($sel_start, $sel_end)")
        if test "$fish_cursor_selection_mode" = exclusive
            set start (math $max_sel + 1)
        else
            set start $max_sel
        end
    else
        set -l cur_char (string sub -s (math $cursor + 1) -l 1 -- "$buf")
        set -l next_char (string sub -s (math $cursor + 2) -l 1 -- "$buf")
        set -l cur_class (__fish_helix_char_class "w" "$cur_char")
        set -l next_class (__fish_helix_char_class "w" "$next_char")
        if test $cur_class -ne $next_class
            set start (math $cursor + 1)
        end
    end

    while test $start -lt $len
        set -l ch (string sub -s (math $start + 1) -l 1 -- "$buf")
        if not string match -qr '^\s' -- "$ch"
            break
        end
        set start (math $start + 1)
    end
    if test $start -ge $len
        return
    end

    set -l target_end $start
    for i in (seq $count)
        if test $i -gt 1
            set target_end (math $target_end + 1)
            while test $target_end -lt $len
                set -l ch (string sub -s (math $target_end + 1) -l 1 -- "$buf")
                if not string match -qr '^\s' -- "$ch"
                    break
                end
                set target_end (math $target_end + 1)
            end
            set start $target_end
        end
        set target_end (__fish_helix_find_next_word_end "w" "$buf" $target_end)
    end

    set -l diff (math "$target_end - $start")

    commandline -f end-selection
    commandline -C $start
    commandline -f begin-selection
    for i in (seq $diff)
        commandline -f forward-char
    end
    commandline -f repaint-mode
end

function __fish_helix_normal_b --description 'Helix normal mode: select prev word start (b)'
    set -l count (__fish_helix_consume_count)
    set -l buf (commandline -b)
    set -l cursor (commandline -C)
    set -l len (string length -- "$buf")
    if test $len -eq 0 -o $cursor -le 0
        return
    end

    set -l anchor $cursor
    if commandline --selection-start >/dev/null 2>&1
        set -l sel_start (commandline --selection-start)
        set -l sel_end (commandline --selection-end)
        set -l min_sel (math "min($sel_start, $sel_end)")
        set anchor (math $min_sel - 1)
    else
        set -l cur_char (string sub -s (math $cursor + 1) -l 1 -- "$buf")
        set -l prev_char (string sub -s $cursor -l 1 -- "$buf")
        set -l cur_class (__fish_helix_char_class "w" "$cur_char")
        set -l prev_class (__fish_helix_char_class "w" "$prev_char")
        if test $cur_class -ne $prev_class
            set anchor (math $cursor - 1)
        end
    end

    if test $anchor -lt 0
        return
    end

    set -l target_pos $anchor
    for i in (seq $count)
        set target_pos (__fish_helix_find_prev_word_start "w" "$buf" $target_pos)
        if test $target_pos -gt 0 -a $i -lt $count
            set target_pos (math $target_pos - 1)
        end
    end

    set -l diff (math "$anchor - $target_pos")
    commandline -f end-selection
    commandline -C $anchor
    commandline -f begin-selection
    for i in (seq $diff)
        commandline -f backward-char
    end
    commandline -f repaint-mode
end

function __fish_helix_normal_e --description 'Helix normal mode: select next word end (e)'
    set -l count (__fish_helix_consume_count)
    commandline -f end-selection begin-selection
    for i in (seq $count)
        commandline -f forward-word-end
    end
    commandline -f repaint-mode
end

function __fish_helix_normal_W --description 'Helix normal mode: select next WORD start (W)'
    set -l count (__fish_helix_consume_count)
    set -l buf (commandline -b)
    set -l cursor (commandline -C)
    set -l len (string length -- "$buf")
    if test $len -eq 0 -o $cursor -ge $len
        return
    end

    set -l start $cursor
    if commandline --selection-start >/dev/null 2>&1
        set -l sel_start (commandline --selection-start)
        set -l sel_end (commandline --selection-end)
        set -l max_sel (math "max($sel_start, $sel_end)")
        if test "$fish_cursor_selection_mode" = exclusive
            set start (math $max_sel + 1)
        else
            set start $max_sel
        end
    else
        set -l cur_char (string sub -s (math $cursor + 1) -l 1 -- "$buf")
        set -l next_char (string sub -s (math $cursor + 2) -l 1 -- "$buf")
        set -l cur_class (__fish_helix_char_class "W" "$cur_char")
        set -l next_class (__fish_helix_char_class "W" "$next_char")
        if test $cur_class -ne $next_class
            set start (math $cursor + 1)
        end
    end

    while test $start -lt $len
        set -l ch (string sub -s (math $start + 1) -l 1 -- "$buf")
        if not string match -qr '^\s' -- "$ch"
            break
        end
        set start (math $start + 1)
    end
    if test $start -ge $len
        return
    end

    set -l target_end $start
    for i in (seq $count)
        if test $i -gt 1
            set target_end (math $target_end + 1)
            while test $target_end -lt $len
                set -l ch (string sub -s (math $target_end + 1) -l 1 -- "$buf")
                if not string match -qr '^\s' -- "$ch"
                    break
                end
                set target_end (math $target_end + 1)
            end
            set start $target_end
        end
        set target_end (__fish_helix_find_next_word_end "W" "$buf" $target_end)
    end

    set -l diff (math "$target_end - $start")

    commandline -f end-selection
    commandline -C $start
    commandline -f begin-selection
    for i in (seq $diff)
        commandline -f forward-char
    end
    commandline -f repaint-mode
end

function __fish_helix_normal_B --description 'Helix normal mode: select prev WORD start (B)'
    set -l count (__fish_helix_consume_count)
    set -l buf (commandline -b)
    set -l cursor (commandline -C)
    set -l len (string length -- "$buf")
    if test $len -eq 0 -o $cursor -le 0
        return
    end

    set -l anchor $cursor
    if commandline --selection-start >/dev/null 2>&1
        set -l sel_start (commandline --selection-start)
        set -l sel_end (commandline --selection-end)
        set -l min_sel (math "min($sel_start, $sel_end)")
        set anchor (math $min_sel - 1)
    else
        set -l cur_char (string sub -s (math $cursor + 1) -l 1 -- "$buf")
        set -l prev_char (string sub -s $cursor -l 1 -- "$buf")
        set -l cur_class (__fish_helix_char_class "B" "$cur_char")
        set -l prev_class (__fish_helix_char_class "B" "$prev_char")
        if test $cur_class -ne $prev_class
            set anchor (math $cursor - 1)
        end
    end

    if test $anchor -lt 0
        return
    end

    set -l target_pos $anchor
    for i in (seq $count)
        set target_pos (__fish_helix_find_prev_word_start "B" "$buf" $target_pos)
        if test $target_pos -gt 0 -a $i -lt $count
            set target_pos (math $target_pos - 1)
        end
    end

    set -l diff (math "$anchor - $target_pos")
    commandline -f end-selection
    commandline -C $anchor
    commandline -f begin-selection
    for i in (seq $diff)
        commandline -f backward-char
    end
    commandline -f repaint-mode
end

function __fish_helix_normal_E --description 'Helix normal mode: select next WORD end (E)'
    set -l count (__fish_helix_consume_count)
    commandline -f end-selection begin-selection
    for i in (seq $count)
        commandline -f forward-bigword-end
    end
    commandline -f repaint-mode
end

function __fish_helix_visual_w --description 'Helix visual mode: extend selection to next word start'
    set -l count (__fish_helix_consume_count)
    set -l buf (commandline -b)
    set -l cursor (commandline -C)
    set -l target_end $cursor
    for i in (seq $count)
        set target_end (__fish_helix_find_next_word_end "w" "$buf" (math $target_end + 1))
    end
    set -l diff (math "$target_end - $cursor")
    if test $diff -gt 0
        for i in (seq $diff)
            commandline -f forward-char
        end
    end
    commandline -f repaint-mode
end

function __fish_helix_visual_W --description 'Helix visual mode: extend selection to next WORD start'
    set -l count (__fish_helix_consume_count)
    set -l buf (commandline -b)
    set -l cursor (commandline -C)
    set -l target_end $cursor
    for i in (seq $count)
        set target_end (__fish_helix_find_next_word_end "W" "$buf" (math $target_end + 1))
    end
    set -l diff (math "$target_end - $cursor")
    if test $diff -gt 0
        for i in (seq $diff)
            commandline -f forward-char
        end
    end
    commandline -f repaint-mode
end

function __fish_helix_visual_b --description 'Helix visual mode: extend selection to prev word start'
    set -l count (__fish_helix_consume_count)
    set -l buf (commandline -b)
    set -l cursor (commandline -C)
    set -l target_start $cursor
    for i in (seq $count)
        if test $target_start -le 0
            break
        end
        set target_start (__fish_helix_find_prev_word_start "w" "$buf" (math $target_start - 1))
    end
    set -l diff (math "$cursor - $target_start")
    if test $diff -gt 0
        for i in (seq $diff)
            commandline -f backward-char
        end
    end
    commandline -f repaint-mode
end

function __fish_helix_visual_B --description 'Helix visual mode: extend selection to prev WORD start'
    set -l count (__fish_helix_consume_count)
    set -l buf (commandline -b)
    set -l cursor (commandline -C)
    set -l target_start $cursor
    for i in (seq $count)
        if test $target_start -le 0
            break
        end
        set target_start (__fish_helix_find_prev_word_start "B" "$buf" (math $target_start - 1))
    end
    set -l diff (math "$cursor - $target_start")
    if test $diff -gt 0
        for i in (seq $diff)
            commandline -f backward-char
        end
    end
end

function __fish_helix_visual_h --description 'Helix visual mode: extend selection left (h)'
    __fish_helix_run_count backward-char
    commandline -f repaint-mode
end

function __fish_helix_visual_l --description 'Helix visual mode: extend selection right (l)'
    __fish_helix_run_count forward-char
    commandline -f repaint-mode
end

function __fish_helix_visual_k --description 'Helix visual mode: extend selection up (k)'
    __fish_helix_run_count up-line
    commandline -f repaint-mode
end

function __fish_helix_visual_j --description 'Helix visual mode: extend selection down (j)'
    __fish_helix_run_count down-line
    commandline -f repaint-mode
end

function __fish_helix_visual_e --description 'Helix visual mode: extend selection to word end (e)'
    __fish_helix_run_count forward-word-end
    commandline -f repaint-mode
end

function __fish_helix_visual_E --description 'Helix visual mode: extend selection to WORD end (E)'
    __fish_helix_run_count forward-bigword-end
    commandline -f repaint-mode
end

function __fish_helix_normal_h --description 'Helix normal mode: collapse selection and move left (h)'
    set -l count (__fish_helix_consume_count)
    commandline -f end-selection
    for i in (seq $count)
        commandline -f backward-char
    end
    commandline -f repaint-mode
end

function __fish_helix_normal_l --description 'Helix normal mode: collapse selection and move right (l)'
    set -l count (__fish_helix_consume_count)
    commandline -f end-selection
    for i in (seq $count)
        commandline -f forward-char
    end
    commandline -f repaint-mode
end

function __fish_helix_normal_k --description 'Helix normal mode: collapse selection and move up (k)'
    set -l count (__fish_helix_consume_count)
    commandline -f end-selection
    for i in (seq $count)
        if test "$fish_helix_atuin_up" = true -a $count -eq 1; and __fish_helix_is_atuin_enabled
            if not functions -q _atuin_bind_up; and type -q atuin
                atuin init fish | source
            end
            if functions -q _atuin_bind_up
                _atuin_bind_up
                continue
            end
        end

        if functions -q up-or-search
            up-or-search
        else
            commandline -f up-line
        end
    end
    commandline -f repaint-mode
end

function __fish_helix_normal_j --description 'Helix normal mode: collapse selection and move down (j)'
    set -l count (__fish_helix_consume_count)
    commandline -f end-selection
    for i in (seq $count)
        if functions -q down-or-search
            down-or-search
        else
            commandline -f down-line
        end
    end
    commandline -f repaint-mode
end

function __fish_helix_select_line --description 'Helix: select line or extend line below (x)'
    set -l count (__fish_helix_consume_count)
    set -l is_selected 0
    if commandline --selection-start >/dev/null 2>&1
        set is_selected 1
    end

    if test $is_selected -eq 1
        # Selection already active: extend line down by count lines
        for i in (seq $count)
            commandline -f end-of-line forward-char end-of-line
        end
    else
        # Select current line and extend if count > 1
        commandline -f beginning-of-line begin-selection end-of-line
        if test $count -gt 1
            for i in (seq (math $count - 1))
                commandline -f end-of-line forward-char end-of-line
            end
        end
    end

    set fish_bind_mode visual
    commandline -f repaint-mode
end

function __fish_helix_extend_to_line_bounds --description 'Helix: extend to line bounds (X)'
    if not commandline --selection-start >/dev/null 2>&1
        commandline -f begin-selection
    end
    commandline -f beginning-of-line swap-selection-start-stop end-of-line repaint-mode
    set fish_bind_mode visual
end

function __fish_helix_shrink_to_line_bounds --description 'Helix: shrink to line bounds (Alt-x)'
    if not commandline --selection-start >/dev/null 2>&1
        return
    end

    set -l buf (commandline -b | string collect)
    set -l lines (string split \n -- "$buf")
    set -l num_lines (count $lines)
    if test $num_lines -eq 0
        return
    end

    set -l sel_start (commandline --selection-start)
    set -l sel_end (commandline --selection-end)
    set -l min_pos (math "min($sel_start, $sel_end)")
    set -l max_pos (math "max($sel_start, $sel_end)")

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

    set -l L_start 1
    for i in (seq $num_lines)
        if test $min_pos -ge $line_starts[$i]
            set L_start $i
        end
    end

    set -l L_end 1
    for i in (seq $num_lines)
        if test $max_pos -ge $line_starts[$i]
            set L_end $i
        end
    end

    set -l shrunk_start_line $L_start
    if test $min_pos -gt $line_starts[$L_start]
        set shrunk_start_line (math "$L_start + 1")
    end

    set -l shrunk_end_line $L_end
    if test $max_pos -lt $line_ends[$L_end]
        set shrunk_end_line (math "$L_end - 1")
    end

    if test $shrunk_start_line -le $shrunk_end_line -a $shrunk_start_line -le $num_lines -a $shrunk_end_line -ge 1
        set -l new_start $line_starts[$shrunk_start_line]
        set -l new_end $line_ends[$shrunk_end_line]
        set -l diff (math "$new_end - $new_start")

        commandline -f end-selection
        commandline -C $new_start
        commandline -f begin-selection
        for i in (seq $diff)
            commandline -f forward-char
        end
        set fish_bind_mode visual
        commandline -f repaint-mode
    else
        commandline -f end-selection
        set fish_bind_mode default
        commandline -f repaint-mode
    end
end

# --- Register Support Functions ---
function __fish_helix_select_register --description 'Helix: enter register selection mode (")'
    set -g __fish_helix_prev_mode $fish_bind_mode
    if test "$fish_bind_mode" = visual
        set fish_bind_mode helix_register_visual
    else
        set fish_bind_mode helix_register
    end
    commandline -f repaint-mode
end

function __fish_helix_set_active_register --argument-names reg --description 'Helix: activate selected register'
    set -g __fish_helix_register "$reg"
    set -l prev default
    if set -q __fish_helix_prev_mode
        set prev $__fish_helix_prev_mode
        set -e __fish_helix_prev_mode
    end
    set fish_bind_mode $prev
    commandline -f repaint-mode
end

function __fish_helix_consume_register --description 'Helix: consume and reset active register'
    if set -q __fish_helix_register; and test -n "$__fish_helix_register"
        set -l reg $__fish_helix_register
        set -e __fish_helix_register
        echo $reg
    else
        echo '"'
    end
end

function __fish_helix_get_register --argument-names reg --description 'Helix: get register contents'
    if test -z "$reg"
        set reg '"'
    end

    switch $reg
        case '_'
            return
        case '+'
            fish_clipboard_paste
        case '\*'
            if type -q wl-paste
                wl-paste --primary 2>/dev/null; or fish_clipboard_paste
            else if type -q xsel
                xsel -p -o 2>/dev/null; or fish_clipboard_paste
            else if type -q pbpaste
                pbpaste
            else
                fish_clipboard_paste
            end
        case '"'
            if set -q __fish_helix_reg_default
                printf '%s' "$__fish_helix_reg_default"
            end
        case '/'
            if set -q __fish_helix_reg_slash
                printf '%s' "$__fish_helix_reg_slash"
            end
        case ':'
            if test (count $history) -gt 0
                printf '%s' "$history[1]"
            end
        case '%'
            commandline -b
        case '*'
            set -l var "__fish_helix_reg_$reg"
            if set -q $var
                printf '%s' "$$var"
            end
    end
end

function __fish_helix_set_register --argument-names reg text --description 'Helix: store text in register'
    if test -z "$reg"
        set reg '"'
    end

    if test "$reg" != '_'
        set -g __fish_helix_reg_default "$text"
    end

    switch $reg
        case '_'
            return
        case '+'
            printf '%s' "$text" | fish_clipboard_copy
        case '\*'
            if type -q wl-copy
                printf '%s' "$text" | wl-copy --primary 2>/dev/null; or printf '%s' "$text" | fish_clipboard_copy
            else if type -q xsel
                printf '%s' "$text" | xsel -p -i 2>/dev/null; or printf '%s' "$text" | fish_clipboard_copy
            else
                printf '%s' "$text" | fish_clipboard_copy
            end
        case '"'
            return
        case '/'
            set -g __fish_helix_reg_slash "$text"
        case ':' '%'
            return
        case '*'
            set -g "__fish_helix_reg_$reg" "$text"
    end
end

function __fish_helix_show_registers --description 'Helix: display active registers (<space>")'
    set -l pager cat
    if test -t 1; and command -v less >/dev/null 2>&1
        set pager less -FRX
    else if command -v more >/dev/null 2>&1; and test -t 1
        set pager more
    end

    set -l c_title (set_color --bold cyan)
    set -l c_key (set_color --bold green)
    set -l c_label (set_color yellow)
    set -l c_val (set_color normal)
    set -l c_dim (set_color brblack)
    set -l c_reset (set_color normal)

    set -l out "
$c_title Helix Registers$c_reset
$c_dim================================================================================$c_reset
"
    if set -q __fish_helix_reg_default; and test -n "$__fish_helix_reg_default"
        set -l preview (string replace -a \n ' ' -- "$__fish_helix_reg_default" | string sub -l 60)
        set out "$out  $c_key\"$c_reset $c_label(default)  $c_reset: $c_val$preview$c_reset\n"
    end

    set -l clip (fish_clipboard_paste 2>/dev/null)
    if test -n "$clip"
        set -l preview (string replace -a \n ' ' -- "$clip" | string sub -l 60)
        set out "$out  $c_key+$c_reset $c_label(clipboard)$c_reset: $c_val$preview$c_reset\n"
    end

    if test (count $history) -gt 0
        set -l preview (string replace -a \n ' ' -- "$history[1]" | string sub -l 60)
        set out "$out  $c_key:$c_reset $c_label(last cmd) $c_reset: $c_val$preview$c_reset\n"
    end

    set -l all_named a b c d e f g h i j k l m n o p q r s t u v w x y z 0 1 2 3 4 5 6 7 8 9
    for r in $all_named
        set -l var "__fish_helix_reg_$r"
        if set -q $var; and test -n "$$var"
            set -l preview (string replace -a \n ' ' -- "$$var" | string sub -l 60)
            set out "$out  $c_key$r$c_reset $c_label(named)    $c_reset: $c_val$preview$c_reset\n"
        end
    end

    set out "$out$c_dim================================================================================$c_reset\n"
    printf '%b' "$out" | $pager
    commandline -f repaint
end

function __fish_helix_delete --argument-names reg --description 'Helix: delete selection or char under cursor (d)'
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

function __fish_helix_yank --argument-names reg --description 'Helix: yank selection or char under cursor (y)'
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

function __fish_helix_paste_after --argument-names reg --description 'Helix: paste register contents after cursor (p)'
    if test -z "$reg"
        set reg (__fish_helix_consume_register)
    end
    set -l count (__fish_helix_consume_count)

    if test "$reg" = '_'
        return
    end

    set -l text (__fish_helix_get_register "$reg")

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

function __fish_helix_replace_with_register --argument-names reg --description 'Helix: replace selection or char with register content (R)'
    if test -z "$reg"
        set reg (__fish_helix_consume_register)
    end

    if test "$reg" = '_'
        return
    end

    set -l text (__fish_helix_get_register "$reg")
    if test -z "$text"
        return
    end

    set -l buf (commandline -b | string collect)
    set -l pos (commandline -C)
    set -l len 1

    if commandline --selection-start >/dev/null 2>&1
        set -l start (commandline --selection-start)
        set -l end (commandline --selection-end)
        set -l min_pos (math "min($start, $end)")
        set -l max_pos (math "max($start, $end)")
        set len (math "$max_pos - $min_pos")
        if test $len -le 0
            set len 1
        end
        set pos $min_pos
        commandline -f end-selection
    end

    set -l prefix ""
    if test $pos -gt 0
        set prefix (string sub -s 1 -l $pos -- "$buf" | string collect)
    end
    set -l suffix (string sub -s (math $pos + $len + 1) -- "$buf" | string collect)

    set -l new_buf "$prefix$text$suffix"
    commandline -r -- "$new_buf"
    commandline -C (math "$pos + (string length -- \"$text\")")
    set fish_bind_mode default
    commandline -f repaint-mode
end

function __fish_helix_replace_with_yanked --description 'Helix: replace selection or char with yanked text (R)'
    __fish_helix_replace_with_register
end

function __fish_helix_replace_with_clipboard --description 'Helix: replace selection or char with clipboard content (<space>R)'
    set -l clip (fish_clipboard_paste)
    if test -z "$clip"
        return
    end

    set -l buf (string join \n -- (commandline -b))
    set -l pos (commandline -C)
    set -l len 1

    if commandline --selection-start >/dev/null 2>&1
        set -l start (commandline --selection-start)
        set -l end (commandline --selection-end)
        set -l min_pos (math "min($start, $end)")
        set -l max_pos (math "max($start, $end)")
        set len (math "$max_pos - $min_pos")
        if test $len -eq 0
            set len 1
        end
        set pos $min_pos
        commandline -f end-selection
    end

    set -l prefix ""
    if test $pos -gt 0
        set prefix (string sub -s 1 -l $pos -- "$buf" | string collect)
    end
    set -l suffix (string sub -s (math $pos + $len + 1) -- "$buf" | string collect)

    set -l new_buf "$prefix$clip$suffix"
    commandline -r -- "$new_buf"
    commandline -C (math $pos + (string length -- "$clip"))
    commandline -f repaint-mode
    set fish_bind_mode default
end

function __fish_helix_goto_first_nonwhitespace --description 'Helix: goto first non-whitespace character on line (gs)'
    commandline -f beginning-of-line
    set -l line_no (commandline -L)
    set -l buf_lines (commandline -b | string split \n)
    set -l cur_line "$buf_lines[$line_no]"

    set -l trimmed (string replace -r '^\s*' '' -- "$cur_line")
    set -l indent (math (string length -- "$cur_line") - (string length -- "$trimmed"))

    for i in (seq $indent)
        commandline -f forward-char
    end
    commandline -f repaint-mode
end

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

function __fish_helix_surround_add --argument-names char
    set -l pair (__fish_helix_get_surround_pair "$char")
    set -l open $pair[1]
    set -l close $pair[2]

    if commandline --selection-start >/dev/null 2>&1
        set -l sel (commandline -s)
        set -l start (commandline --selection-start)
        set -l end (commandline --selection-end)
        set -l min_pos (math "min($start, $end)")
        set -l len (string length -- "$sel")

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
        set -l len (string length -- "$sel")

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
        set end (math $bounds[2] - 1)
    else
        set -l pair (__fish_helix_find_pair "$char" "$buf" "$cursor")
        if test (count $pair) -lt 2
            return
        end
        set -l open_idx $pair[1]
        set -l close_idx $pair[2]

        if test "$target_mode" = "i"
            set start (math $open_idx + 1)
            set end (math $close_idx - 1)
        else
            set start $open_idx
            set end $close_idx
        end
    end

    if test $end -lt $start
        commandline -f end-selection
        commandline -C $start
        set fish_bind_mode default
        commandline -f repaint-mode
        return
    end

    set -l diff (math "$end - $start")
    commandline -f end-selection
    commandline -C $start
    commandline -f begin-selection
    for i in (seq $diff)
        commandline -f forward-char
    end
    set fish_bind_mode visual
    commandline -f repaint-mode
end

function __fish_helix_trim_selection --description 'Helix: trim whitespace from active selection (_)'
    if not commandline --selection-start >/dev/null 2>&1
        return
    end

    set -l buf (string join \n -- (commandline -b))
    set -l len (string length -- "$buf")
    if test $len -eq 0
        return
    end

    set -l sel_start (commandline --selection-start)
    set -l sel_end (commandline --selection-end)
    set -l min_pos (math "min($sel_start, $sel_end)")
    set -l max_pos (math "max($sel_start, $sel_end)")

    # In inclusive mode, sel_end is max_pos + 1 (exclusive)
    set -l last_pos
    if test "$fish_cursor_selection_mode" = exclusive
        set last_pos $max_pos
    else
        set last_pos (math "$max_pos - 1")
    end

    # Advance min_pos past leading whitespace
    while test $min_pos -le $last_pos
        set -l ch (string sub -s (math $min_pos + 1) -l 1 -- "$buf")
        if not string match -qr '^\s' -- "$ch"
            break
        end
        set min_pos (math $min_pos + 1)
    end

    # Retreat last_pos past trailing whitespace
    while test $last_pos -ge $min_pos
        set -l ch (string sub -s (math $last_pos + 1) -l 1 -- "$buf")
        if not string match -qr '^\s' -- "$ch"
            break
        end
        set last_pos (math $last_pos - 1)
    end

    if test $min_pos -gt $last_pos
        commandline -f end-selection
        commandline -C $min_pos
        commandline -f repaint-mode
        return
    end

    set -l diff (math "$last_pos - $min_pos")
    commandline -f end-selection
    commandline -C $min_pos
    commandline -f begin-selection
    for i in (seq $diff)
        commandline -f forward-char
    end
    commandline -f repaint-mode
end

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

function __fish_helix_ensure_forward_selection --description 'Helix: ensure selection direction is forward (Alt+:)'
    if not commandline --selection-start >/dev/null 2>&1
        return
    end

    set -l sel_start (commandline --selection-start)
    set -l sel_end (commandline --selection-end)
    set -l cursor (commandline -C)
    set -l min_pos (math "min($sel_start, $sel_end)")
    set -l max_pos (math "max($sel_start, $sel_end)")

    if test "$cursor" = "$min_pos" -a "$max_pos" -gt "$min_pos"
        commandline -f swap-selection-start-stop repaint-mode
    end
end

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

function __fish_helix_cheatsheet --description 'Helix: show keybindings cheatsheet (<space>? / <space>h)'
    set -l pager cat
    if test -t 1; and command -v less >/dev/null 2>&1
        set pager less -FRX
    else if command -v more >/dev/null 2>&1; and test -t 1
        set pager more
    end

    set -l c_title (set_color --bold cyan)
    set -l c_sec (set_color --bold yellow)
    set -l c_key (set_color --bold green)
    set -l c_desc (set_color normal)
    set -l c_dim (set_color brblack)
    set -l c_reset (set_color normal)

    set -l text "
$c_title Helix Keybindings Cheatsheet for Fish Shell$c_reset
$c_dim================================================================================$c_reset

$c_sec MODES$c_reset
  $c_key i$c_desc            Insert before selection / cursor$c_reset
  $c_key a$c_desc            Insert after cursor (append)$c_reset
  $c_key I$c_desc            Insert at first non-whitespace character on line$c_reset
  $c_key A$c_desc            Insert at end of line$c_reset
  $c_key c$c_desc            Change selection (delete selection and enter insert mode)$c_reset
  $c_key v, Esc$c_desc       Toggle between Normal and Visual (Select) mode$c_reset
  $c_key r<char>$c_desc      Replace character under cursor or entire selection$c_reset

$c_sec MOTIONS / SELECTIONS$c_reset
  $c_key h, j, k, l$c_desc   Move left, down, up, right$c_reset
  $c_key w / W$c_desc        Select next word / BIGWORD end$c_reset
  $c_key b / B$c_desc        Select previous word / BIGWORD start$c_reset
  $c_key e / E$c_desc        Select to next word / BIGWORD end$c_reset
  $c_key x$c_desc            Select current line (expand selection line by line)$c_reset
  $c_key X$c_desc            Extend selection to whole line$c_reset
  $c_key Alt+x (\ex)$c_desc  Shrink selection to line bounds$c_reset
  $c_key %$c_desc            Select entire buffer$c_reset
  $c_key ;$c_desc            Collapse selection to single cursor$c_reset
  $c_key Alt-; (\e;)$c_desc  Swap selection anchor and cursor$c_reset
  $c_key Alt+: (\e:)$c_desc  Ensure selection direction is forward$c_reset
  $c_key _$c_desc            Trim leading and trailing whitespace from selection$c_reset
  $c_key J$c_desc            Join lines with space (collapsing indentation)$c_reset
  $c_key Alt+J (\eJ)$c_desc  Join lines without space$c_reset
  $c_key >, <$c_desc         Indent / Unindent line or multiline selection$c_reset

$c_sec GOTO (g)$c_reset
  $c_key gh$c_desc           Go to start of line$c_reset
  $c_key gl$c_desc           Go to end of line$c_reset
  $c_key gs$c_desc           Go to first non-whitespace character on line$c_reset
  $c_key gg / gt$c_desc      Go to start of buffer$c_reset
  $c_key ge / gb$c_desc      Go to end of buffer$c_reset
  $c_key gm$c_desc           Jump to matching bracket (alias for mm)$c_reset
  $c_key gp$c_desc           Paste from kill-ring (yank-pop)$c_reset

$c_sec MATCH & SURROUND (m)$c_reset
  $c_key mm$c_desc           Jump to matching bracket$c_reset
  $c_key mi<delim>$c_desc    Select inside delimiter (\", ', `, (), [], {}, <>, w, W)$c_reset
  $c_key ma<delim>$c_desc    Select around delimiter (including quotes/brackets)$c_reset
  $c_key md<delim>$c_desc    Delete surround delimiter$c_reset
  $c_key ms<delim>$c_desc    Add surround delimiter around selection$c_reset
  $c_key mr<old><new>$c_desc Replace surround delimiter <old> with <new>$c_reset

$c_sec EDITING & CLIPBOARD / REGISTERS$c_reset
  $c_key \"<reg>$c_desc       Select register (\"a-\"z, \"0-\"9, \"+, \"*, \"_, \"\")$c_reset
  $c_key <space>\"$c_desc     Display non-empty register contents$c_reset
  $c_key d, Alt+d$c_desc     Delete selection (d yanks, Alt+d does not yank)$c_reset
  $c_key c, Alt+c$c_desc     Change selection (c yanks, Alt+c does not yank)$c_reset
  $c_key y$c_desc            Yank (copy) selection to active / default register$c_reset
  $c_key p, P$c_desc         Paste after / before cursor from active / default register$c_reset
  $c_key R$c_desc            Replace selection or char with register / yanked text$c_reset
  $c_key \"+y / \"+p$c_desc    Yank to / Paste from system clipboard$c_reset
  $c_key \"_d / \"_c$c_desc    Delete / Change into black hole (does not clobber registers)$c_reset
  $c_key ~$c_desc            Toggle case of selection$c_reset
  $c_key `$c_desc            Lowercase selection$c_reset
  $c_key Alt+`$c_desc        Uppercase selection$c_reset
  $c_key u, U$c_desc         Undo / Redo$c_reset
  $c_key <space>y$c_desc     Copy selection to system clipboard$c_reset
  $c_key <space>p / P$c_desc Paste from system clipboard after / before cursor$c_reset
  $c_key <space>R$c_desc     Replace selection with system clipboard contents$c_reset
  $c_key <space>e$c_desc     Open external editor (\$EDITOR)$c_reset
  $c_key Ctrl-x Ctrl-e$c_desc Open external editor (\$EDITOR)$c_reset
  $c_key <space>c, #$c_desc  Toggle line comment$c_reset
  $c_key <space>? / h$c_desc Show this cheatsheet$c_reset

$c_sec SEARCH & HISTORY$c_reset
  $c_key / , ?$c_desc        Search history backward / forward (Atuin integrated)$c_reset
  $c_key Ctrl-r$c_desc       Search history backward$c_reset
  $c_key <space>b$c_desc     Search history$c_reset
  $c_key n, N$c_desc         Jump to next / previous history search match$c_reset
$c_dim================================================================================$c_reset
"

    printf '%s\n' "$text" | $pager
    commandline -f repaint
end


if not functions -q fish_helix_cursor
    function fish_helix_cursor --description 'Set cursor shape for different Helix modes'
        set -q fish_cursor_unknown
        or set -g fish_cursor_unknown block

        set -q fish_cursor_default
        or set -g fish_cursor_default block

        set -q fish_cursor_insert
        or set -g fish_cursor_insert line

        set -q fish_cursor_visual
        or set -g fish_cursor_visual underscore

        set -q fish_cursor_replace_one
        or set -q fish_cursor_helix_replace_one
        and set -g fish_cursor_replace_one $fish_cursor_helix_replace_one
        or set -g fish_cursor_replace_one underscore

        set -q fish_cursor_helix_replace_one
        or set -g fish_cursor_helix_replace_one $fish_cursor_replace_one

        function __fish_helix_cursor --argument-names varname
            if not status is-interactive; and not status is-interactive-read
                return
            end
            if not set -q $varname
                switch $varname
                    case fish_cursor_insert
                        __fish_cursor_xterm line
                    case fish_cursor_visual fish_cursor_replace_one fish_cursor_helix_replace_one fish_cursor_helix_register fish_cursor_helix_register_visual
                        __fish_cursor_xterm underscore
                    case '*'
                        __fish_cursor_xterm $fish_cursor_unknown
                end
                return
            end
            __fish_cursor_xterm $$varname
        end

        function __fish_helix_cursor_handle --on-variable fish_bind_mode --on-event fish_postexec --on-event fish_focus_in --on-event fish_read
            __fish_helix_cursor fish_cursor_$fish_bind_mode
        end

        function __fish_helix_cursor_handle_preexec --on-event fish_preexec --on-event fish_exit
            set -l varname fish_cursor_external
            if not set -q $varname
                set varname fish_cursor_default
            end
            __fish_helix_cursor $varname
        end
    end
end

# ==============================================================================
# History & Atuin Integration Helpers
# ==============================================================================

function __fish_helix_is_atuin_enabled --description 'Check if Atuin integration is enabled and available'
    # 1. Explicit user disable
    if test "$fish_helix_atuin" = false
        return 1
    end

    # 2. Explicit user enable
    if test "$fish_helix_atuin" = true
        if functions -q _atuin_search; or type -q atuin
            return 0
        end
        return 1
    end

    # 3. Auto mode (default when unset or set to 'auto')
    if functions -q _atuin_search; or type -q atuin
        return 0
    end

    return 1
end

function __fish_helix_atuin_search --description 'Helix-aware wrapper for Atuin search'
    # Auto-initialize Atuin on demand if installed but not yet sourced
    if not functions -q _atuin_search
        if type -q atuin
            atuin init fish | source
        end
    end

    if functions -q _atuin_search
        # Temporarily spoof fish_vi_key_bindings so Atuin selects vim-normal or vim-insert
        set -l orig_bindings $fish_key_bindings
        set -g fish_key_bindings fish_vi_key_bindings
        _atuin_search $argv
        set -g fish_key_bindings $orig_bindings
    else
        history-pager
    end
end

function __fish_helix_history_search --description 'History search dispatcher (Helix /, ?, Space-b, Ctrl-r)'
    if __fish_helix_is_atuin_enabled
        __fish_helix_atuin_search $argv
    else
        set fish_bind_mode insert
        commandline -f history-pager repaint-mode
    end
end

function __fish_helix_up --description 'Up arrow dispatcher (respects fish_helix_atuin_up)'
    if test "$fish_helix_atuin_up" = true; and __fish_helix_is_atuin_enabled
        if not functions -q _atuin_bind_up; and type -q atuin
            atuin init fish | source
        end
        if functions -q _atuin_bind_up
            _atuin_bind_up
            return
        end
    end

    if functions -q up-or-search
        up-or-search
    else
        commandline -f up-line
    end
end

# ==============================================================================
# Main key bindings entry point
# ==============================================================================
function fish_helix_key_bindings --description 'Helix-like modal key bindings for fish'
    if contains -- -h $argv
        or contains -- --help $argv
        echo "Usage: fish_helix_key_bindings [--no-erase] [insert|default|visual]" >&2
        return 1
    end

    set -l rebind true
    if test "$argv[1]" = --no-erase
        set rebind false
        set -e argv[1]
    else
        bind --erase --all --preset
    end

    if test "$fish_key_bindings" != fish_helix_key_bindings
        and test "$rebind" = true
        __fish_change_key_bindings fish_helix_key_bindings
    end

    set -l init_mode insert
    if contains -- "$argv[1]" insert default visual
        set init_mode $argv[1]
    end

    # Inherit shared bindings (Enter, Tab, clipboard shortcuts, arrows)
    function __fish_helix_shared
        eval "$(__fish_shared_key_bindings)"
    end
    for mode in insert default visual
        __fish_helix_shared -M $mode
    end
    functions -e __fish_helix_shared

    # --- Mode Switching ---
    set -l on_escape '
        if commandline -P
            commandline -f cancel
        else
            set -g __fish_helix_count
            set fish_bind_mode default
            if test (count (commandline --cut-at-cursor | tail -c2)) != 2
                commandline -f backward-char
            end
            commandline -f repaint-mode
        end
    '
    bind --preset -M insert escape $on_escape
    bind --preset -M insert ctrl-\[ $on_escape

    # --- Insert Mode: Deletion & Editing ---
    bind --preset -M insert backspace backward-delete-char
    bind --preset -M insert shift-backspace backward-delete-char
    bind --preset -M insert ctrl-h backward-delete-char
    bind --preset -M insert delete delete-char
    bind --preset -M insert ctrl-d delete-or-exit
    bind --preset -M insert ctrl-w backward-kill-word
    bind --preset -M insert \e\x7f backward-kill-word
    bind --preset -M insert \e\b backward-kill-word
    bind --preset -M insert ctrl-u backward-kill-line
    bind --preset -M insert ctrl-k kill-line
    bind --preset -M insert ctrl-r __fish_helix_history_search
    bind --preset -M insert up __fish_helix_up

    # Normal mode backspace & delete
    bind --preset -M default backspace backward-char
    bind --preset -M default delete delete-char
    bind --preset -M default up __fish_helix_up

    # Cancel commandline / clear
    bind --preset -M default ctrl-c clear-commandline repaint-mode
    bind --preset -M default :,q exit

    # Reset repeat count & register on escape in default mode
    bind --preset -M default escape 'set -g __fish_helix_count; set -e __fish_helix_register; commandline -f end-selection repaint-mode'
    bind --preset -M default ctrl-\[ 'set -g __fish_helix_count; set -e __fish_helix_register; commandline -f end-selection repaint-mode'

    # Digit counts for repeat motions (1-9, and 0 when count already started)
    for i in (seq 1 9)
        bind --preset -M default $i "__fish_helix_arg_digit $i"
    end
    bind --preset -M default 0 "if test -n \"\$__fish_helix_count\"; __fish_helix_arg_digit 0; end"

    # --- Normal Mode: Insert Transitions ---
    bind --preset -M default -m insert i 'set fish_bind_mode insert; commandline -f repaint-mode'
    bind --preset -M default -m insert a 'set -g fish_cursor_end_mode exclusive; set fish_bind_mode insert' forward-char repaint-mode
    bind --preset -M default -m insert I 'set fish_bind_mode insert' beginning-of-line repaint-mode
    bind --preset -M default -m insert A 'set -g fish_cursor_end_mode exclusive; set fish_bind_mode insert' end-of-line repaint-mode
    bind --preset -M default -m insert o 'set -g fish_cursor_end_mode exclusive; set fish_bind_mode insert' insert-line-under repaint-mode
    bind --preset -M default -m insert O 'set -g fish_cursor_end_mode exclusive; set fish_bind_mode insert' insert-line-over repaint-mode

    # --- Normal Mode: Select / Extend Mode Transition ---
    bind --preset -M default v 'commandline -f begin-selection repaint-mode; set fish_bind_mode visual'

    # --- Normal Mode: Motions (In Helix, movements select/replace range!) ---
    bind --preset -M default h __fish_helix_normal_h
    bind --preset -M default l __fish_helix_normal_l
    bind --preset -M default k __fish_helix_normal_k
    bind --preset -M default j __fish_helix_normal_j
    bind --preset -M default w __fish_helix_normal_w
    bind --preset -M default b __fish_helix_normal_b
    bind --preset -M default e __fish_helix_normal_e
    bind --preset -M default W __fish_helix_normal_W
    bind --preset -M default B __fish_helix_normal_B
    bind --preset -M default E __fish_helix_normal_E

    bind --preset -M default f forward-jump
    bind --preset -M default F backward-jump
    bind --preset -M default t forward-jump-till
    bind --preset -M default T backward-jump-till

    # Enter in jump motions jumps to line bounds (Helix behavior)
    bind --preset -M default t,enter 'commandline -f end-selection begin-selection end-of-line repaint-mode; set fish_bind_mode visual'
    bind --preset -M default t,ctrl-j 'commandline -f end-selection begin-selection end-of-line repaint-mode; set fish_bind_mode visual'
    bind --preset -M default t,ctrl-m 'commandline -f end-selection begin-selection end-of-line repaint-mode; set fish_bind_mode visual'

    bind --preset -M default f,enter 'commandline -f end-selection begin-selection end-of-line repaint-mode; set fish_bind_mode visual'
    bind --preset -M default f,ctrl-j 'commandline -f end-selection begin-selection end-of-line repaint-mode; set fish_bind_mode visual'
    bind --preset -M default f,ctrl-m 'commandline -f end-selection begin-selection end-of-line repaint-mode; set fish_bind_mode visual'

    bind --preset -M default T,enter 'commandline -f end-selection begin-selection beginning-of-line repaint-mode; set fish_bind_mode visual'
    bind --preset -M default T,ctrl-j 'commandline -f end-selection begin-selection beginning-of-line repaint-mode; set fish_bind_mode visual'
    bind --preset -M default T,ctrl-m 'commandline -f end-selection begin-selection beginning-of-line repaint-mode; set fish_bind_mode visual'

    bind --preset -M default F,enter 'commandline -f end-selection begin-selection beginning-of-line repaint-mode; set fish_bind_mode visual'
    bind --preset -M default F,ctrl-j 'commandline -f end-selection begin-selection beginning-of-line repaint-mode; set fish_bind_mode visual'
    bind --preset -M default F,ctrl-m 'commandline -f end-selection begin-selection beginning-of-line repaint-mode; set fish_bind_mode visual'

    bind --preset -M default \e. repeat-jump
    bind --preset -M default \e, repeat-jump-reverse

    # --- Normal Mode: Selection Manipulation ---
    # x in Helix selects line (NOT vim delete char!)
    bind --preset -M default x __fish_helix_select_line
    bind --preset -M default X __fish_helix_extend_to_line_bounds
    bind --preset -M default \ex __fish_helix_shrink_to_line_bounds
    # % in Helix selects all buffer (NOT vim match bracket!)
    bind --preset -M default % 'commandline -f beginning-of-buffer begin-selection end-of-buffer repaint-mode; set fish_bind_mode visual'
    # ; collapses selection
    bind --preset -M default ';' 'commandline -f end-selection repaint-mode'
    # Alt-; flips selection direction
    bind --preset -M default \e\; 'commandline -f swap-selection-start-stop repaint-mode'
    # _ trims whitespace from selection
    bind --preset -M default _ __fish_helix_trim_selection
    # Alt+: ensures selection direction is forward
    bind --preset -M default \e: __fish_helix_ensure_forward_selection
    # J / Alt+J joins lines
    bind --preset -M default J '__fish_helix_join_lines with_space'
    bind --preset -M default \eJ '__fish_helix_join_lines no_space'

    # --- Normal Mode: Registers (") ---
    bind --preset -M default -m helix_register '"' __fish_helix_select_register

    # --- Normal Mode: Changes & Deletions (Selection-First) ---
    # d deletes selection (or char under cursor if no selection)
    bind --preset -M default d __fish_helix_delete
    bind --preset -M default \ed __fish_helix_delete_noyank
    # c changes selection (or char under cursor)
    bind --preset -M default c __fish_helix_change
    bind --preset -M default \ec __fish_helix_change_noyank
    # y yanks selection (or char under cursor)
    bind --preset -M default y __fish_helix_yank

    # Pasting
    bind --preset -M default p __fish_helix_paste_after
    bind --preset -M default P __fish_helix_paste_before

    # Replace with yanked / register
    bind --preset -M default R __fish_helix_replace_with_yanked

    # Case conversions
    bind --preset -M default \~ 'commandline -f togglecase-char repaint-mode'
    bind --preset -M default \` 'commandline -f downcase-word repaint-mode'
    bind --preset -M default \e\` 'commandline -f upcase-word repaint-mode'

    # Indent / Unindent
    bind --preset -M default \> __fish_helix_indent
    bind --preset -M default \< __fish_helix_unindent

    # Undo / Redo (u = undo, U = redo in Helix)
    bind --preset -M default u undo
    bind --preset -M default U redo

    # Comment toggle
    bind --preset -M default \# __fish_toggle_comment_commandline

    # --- Goto Sub-Mode (g) ---
    bind --preset -M default g,h beginning-of-line
    bind --preset -M default g,l end-of-line
    bind --preset -M default g,s __fish_helix_goto_first_nonwhitespace
    bind --preset -M default g,g beginning-of-buffer
    bind --preset -M default g,e end-of-buffer
    bind --preset -M default g,t beginning-of-buffer
    bind --preset -M default g,b end-of-buffer
    bind --preset -M default g,p yank-pop
    bind --preset -M default g,m jump-to-matching-bracket

    # --- Match Sub-Mode (m) ---
    # mm jumps to matching bracket
    bind --preset -M default m,m jump-to-matching-bracket

    # --- Space Sub-Mode ( ) ---
    bind --preset -M default ' ',y fish_clipboard_copy
    bind --preset -M default ' ',p fish_clipboard_paste
    bind --preset -M default ' ',P fish_clipboard_paste
    bind --preset -M default ' ',R __fish_helix_replace_with_clipboard
    bind --preset -M default ' ',e edit_command_buffer
    bind --preset -M default ' ',f complete-and-search
    bind --preset -M default ' ',b __fish_helix_history_search
    bind --preset -M default ' ',c __fish_toggle_comment_commandline
    bind --preset -M default ' ',\? __fish_helix_cheatsheet
    bind --preset -M default ' ',h __fish_helix_cheatsheet
    bind --preset -M default ' ',\" __fish_helix_show_registers

    # External editor readline compatibility
    bind --preset -M default ctrl-x,ctrl-e edit_command_buffer
    bind --preset -M insert ctrl-x,ctrl-e edit_command_buffer

    # --- Search / History ---
    # / and ? open interactive history search (dispatches to Atuin if enabled, otherwise native history-pager)
    bind --preset -M default / __fish_helix_history_search
    bind --preset -M default \? __fish_helix_history_search
    bind --preset -M default ctrl-r __fish_helix_history_search
    # n and N cycle through matching history commands (Helix search next/prev)
    bind --preset -M default n history-search-backward
    bind --preset -M default N history-search-forward

    # --- Character Replace Mode (r) ---
    bind --preset -M default r __fish_helix_prepare_replace

    set -l replace_chars
    for i in (seq 32 126)
        set -a replace_chars (printf "\\x$(printf '%x' $i)")
    end
    for c in $replace_chars
        set -l esc_c (string escape -- "$c")
        bind --preset -M replace_one -m default -- $c "__fish_helix_execute_replace $esc_c"
        bind --preset -M helix_replace_one -m default -- $c "__fish_helix_execute_replace $esc_c"
    end
    bind --preset -M replace_one -m default enter "__fish_helix_execute_replace '\n'"
    bind --preset -M helix_replace_one -m default enter "__fish_helix_execute_replace '\n'"
    bind --preset -M replace_one -m default escape 'set -e __fish_helix_replace_start; set -e __fish_helix_replace_len; set fish_bind_mode default; commandline -f repaint-mode'
    bind --preset -M helix_replace_one -m default escape 'set -e __fish_helix_replace_start; set -e __fish_helix_replace_len; set fish_bind_mode default; commandline -f repaint-mode'
    bind --preset -M replace_one -m default ctrl-\[ 'set -e __fish_helix_replace_start; set -e __fish_helix_replace_len; set fish_bind_mode default; commandline -f repaint-mode'
    bind --preset -M helix_replace_one -m default ctrl-\[ 'set -e __fish_helix_replace_start; set -e __fish_helix_replace_len; set fish_bind_mode default; commandline -f repaint-mode'
    bind --preset -M replace_one -m default '' 'set -e __fish_helix_replace_start; set -e __fish_helix_replace_len; set fish_bind_mode default; commandline -f repaint-mode'
    bind --preset -M helix_replace_one -m default '' 'set -e __fish_helix_replace_start; set -e __fish_helix_replace_len; set fish_bind_mode default; commandline -f repaint-mode'

    # --- Register Selection Modes (") ---
    set -l reg_chars a b c d e f g h i j k l m n o p q r s t u v w x y z 0 1 2 3 4 5 6 7 8 9 '+' '*' '_' '"' '/' ':' '%'
    for r in $reg_chars
        # Modal selection in Normal mode (returns to default mode)
        bind --preset -M helix_register -m default $r "__fish_helix_set_active_register '$r'"
        # Modal selection in Visual mode (returns to visual mode)
        bind --preset -M helix_register_visual -m visual $r "__fish_helix_set_active_register '$r'"

        # Direct chords / sequences (Normal mode)
        bind --preset -M default "\",$r,y" "__fish_helix_yank '$r'"
        bind --preset -M default "\",$r,p" "__fish_helix_paste_after '$r'"
        bind --preset -M default "\",$r,P" "__fish_helix_paste_before '$r'"
        bind --preset -M default "\",$r,d" "__fish_helix_delete '$r'"
        bind --preset -M default -m insert "\",$r,c" "__fish_helix_change '$r'"
        bind --preset -M default "\",$r,R" "__fish_helix_replace_with_yanked '$r'"

        # Direct chords / sequences (Visual mode)
        bind --preset -M visual -m default "\",$r,y" "__fish_helix_yank '$r'"
        bind --preset -M visual -m default "\",$r,p" "__fish_helix_paste_after '$r'"
        bind --preset -M visual -m default "\",$r,P" "__fish_helix_paste_before '$r'"
        bind --preset -M visual -m default "\",$r,d" "__fish_helix_delete '$r' # kill-selection"
        bind --preset -M visual -m insert "\",$r,c" "__fish_helix_change '$r' # kill-selection"
        bind --preset -M visual -m default "\",$r,R" "__fish_helix_replace_with_yanked '$r'"
    end
    for r in (string split ' ' -- 'A B C D E F G H I J K L M N O P Q R S T U V W X Y Z')
        set -l lower_r (string lower -- "$r")
        bind --preset -M helix_register -m default $r "__fish_helix_set_active_register '$lower_r'"
        bind --preset -M helix_register_visual -m visual $r "__fish_helix_set_active_register '$lower_r'"

        # Direct chords for uppercase
        bind --preset -M default "\",$r,y" "__fish_helix_yank '$lower_r'"
        bind --preset -M default "\",$r,p" "__fish_helix_paste_after '$lower_r'"
        bind --preset -M default "\",$r,P" "__fish_helix_paste_before '$lower_r'"
        bind --preset -M default "\",$r,d" "__fish_helix_delete '$lower_r'"
        bind --preset -M default -m insert "\",$r,c" "__fish_helix_change '$lower_r'"
        bind --preset -M default "\",$r,R" "__fish_helix_replace_with_yanked '$lower_r'"

        bind --preset -M visual -m default "\",$r,y" "__fish_helix_yank '$lower_r'"
        bind --preset -M visual -m default "\",$r,p" "__fish_helix_paste_after '$lower_r'"
        bind --preset -M visual -m default "\",$r,P" "__fish_helix_paste_before '$lower_r'"
        bind --preset -M visual -m default "\",$r,d" "__fish_helix_delete '$lower_r' # kill-selection"
        bind --preset -M visual -m insert "\",$r,c" "__fish_helix_change '$lower_r' # kill-selection"
        bind --preset -M visual -m default "\",$r,R" "__fish_helix_replace_with_yanked '$lower_r'"
    end
    bind --preset -M helix_register -m default escape 'set -e __fish_helix_register; set fish_bind_mode default; commandline -f repaint-mode'
    bind --preset -M helix_register -m default ctrl-\[ 'set -e __fish_helix_register; set fish_bind_mode default; commandline -f repaint-mode'
    bind --preset -M helix_register -m default '' 'set -e __fish_helix_register; set fish_bind_mode default; commandline -f repaint-mode'

    bind --preset -M helix_register_visual -m visual escape 'set -e __fish_helix_register; set fish_bind_mode visual; commandline -f repaint-mode'
    bind --preset -M helix_register_visual -m visual ctrl-\[ 'set -e __fish_helix_register; set fish_bind_mode visual; commandline -f repaint-mode'
    bind --preset -M helix_register_visual -m visual '' 'set -e __fish_helix_register; set fish_bind_mode visual; commandline -f repaint-mode'

    # --- Match & Surround Sequences (Direct bindings for instant execution) ---
    # mm: Match Brackets
    bind --preset -M default m,m jump-to-matching-bracket
    bind --preset -M visual m,m jump-to-matching-bracket

    # Textobjects: mi<char> (inside) and ma<char> (around)
    set -l to_delims '"' "'" '`' '(' ')' b '[' ']' r '{' '}' B '<' '>' w W
    for d in $to_delims
        bind --preset -M default m,i,$d "__fish_helix_textobject i '$d'"
        bind --preset -M default m,a,$d "__fish_helix_textobject a '$d'"
        bind --preset -M visual m,i,$d "__fish_helix_textobject i '$d'"
        bind --preset -M visual m,a,$d "__fish_helix_textobject a '$d'"
    end

    # Surround Delete: md<char> & Surround Add: ms<char>
    set -l surr_delims '"' "'" '`' '(' ')' b '[' ']' r '{' '}' B '<' '>' '*' '_' '/'
    for d in $surr_delims
        bind --preset -M default m,d,$d "__fish_helix_surround_delete '$d'"
        bind --preset -M visual m,d,$d "__fish_helix_surround_delete '$d'"
        bind --preset -M default m,s,$d "__fish_helix_surround_add '$d'"
        bind --preset -M visual m,s,$d "__fish_helix_surround_add '$d'"
    end

    # Surround Replace: mr<old><new>
    set -l rep_delims '"' "'" '`' '(' ')' b '[' ']' r '{' '}' B '<' '>'
    for old in $rep_delims
        for new in $rep_delims
            bind --preset -M default m,r,$old,$new "__fish_helix_surround_replace_direct '$old' '$new'"
            bind --preset -M visual m,r,$old,$new "__fish_helix_surround_replace_direct '$old' '$new'"
        end
    end

    # ==========================================
    # --- Select / Extend Mode (visual) ---
    # ==========================================
    # Digit counts for repeat motions in visual mode (1-9, and 0 when count already started)
    for i in (seq 1 9)
        bind --preset -M visual $i "__fish_helix_arg_digit $i"
    end
    bind --preset -M visual 0 "if test -n \"\$__fish_helix_count\"; __fish_helix_arg_digit 0; end"

    # Movements extend selection
    bind --preset -M visual h __fish_helix_visual_h
    bind --preset -M visual l __fish_helix_visual_l
    bind --preset -M visual k __fish_helix_visual_k
    bind --preset -M visual j __fish_helix_visual_j
    bind --preset -M visual w __fish_helix_visual_w
    bind --preset -M visual b __fish_helix_visual_b
    bind --preset -M visual e __fish_helix_visual_e
    bind --preset -M visual W __fish_helix_visual_W
    bind --preset -M visual B __fish_helix_visual_B
    bind --preset -M visual E __fish_helix_visual_E

    bind --preset -M visual f forward-jump
    bind --preset -M visual F backward-jump
    bind --preset -M visual t forward-jump-till
    bind --preset -M visual T backward-jump-till

    # In visual mode, Enter in jump motions extends selection to line bounds
    bind --preset -M visual t,enter 'commandline -f end-of-line repaint-mode'
    bind --preset -M visual t,ctrl-j 'commandline -f end-of-line repaint-mode'
    bind --preset -M visual t,ctrl-m 'commandline -f end-of-line repaint-mode'

    bind --preset -M visual f,enter 'commandline -f end-of-line repaint-mode'
    bind --preset -M visual f,ctrl-j 'commandline -f end-of-line repaint-mode'
    bind --preset -M visual f,ctrl-m 'commandline -f end-of-line repaint-mode'

    bind --preset -M visual T,enter 'commandline -f beginning-of-line repaint-mode'
    bind --preset -M visual T,ctrl-j 'commandline -f beginning-of-line repaint-mode'
    bind --preset -M visual T,ctrl-m 'commandline -f beginning-of-line repaint-mode'

    bind --preset -M visual F,enter 'commandline -f beginning-of-line repaint-mode'
    bind --preset -M visual F,ctrl-j 'commandline -f beginning-of-line repaint-mode'
    bind --preset -M visual F,ctrl-m 'commandline -f beginning-of-line repaint-mode'

    bind --preset -M visual \e. repeat-jump
    bind --preset -M visual \e, repeat-jump-reverse

    bind --preset -M visual g,h beginning-of-line
    bind --preset -M visual g,l end-of-line
    bind --preset -M visual g,s __fish_helix_goto_first_nonwhitespace
    bind --preset -M visual g,g beginning-of-buffer
    bind --preset -M visual g,e end-of-buffer
    bind --preset -M visual g,m jump-to-matching-bracket
    bind --preset -M visual m,m jump-to-matching-bracket

    # Selection manipulation in visual mode
    bind --preset -M visual -m helix_register_visual '"' __fish_helix_select_register
    bind --preset -M visual x __fish_helix_select_line
    bind --preset -M visual X __fish_helix_extend_to_line_bounds
    bind --preset -M visual \ex __fish_helix_shrink_to_line_bounds
    bind --preset -M visual % 'commandline -f beginning-of-buffer begin-selection end-of-buffer repaint-mode'
    bind --preset -M visual ';' 'set -g __fish_helix_count; set -e __fish_helix_register; commandline -f end-selection repaint-mode; set fish_bind_mode default'
    bind --preset -M visual \e\; 'commandline -f swap-selection-start-stop repaint-mode'
    bind --preset -M visual _ __fish_helix_trim_selection
    bind --preset -M visual \e: __fish_helix_ensure_forward_selection
    bind --preset -M visual J '__fish_helix_join_lines with_space; set fish_bind_mode default'
    bind --preset -M visual \eJ '__fish_helix_join_lines no_space; set fish_bind_mode default'
    bind --preset -M visual r __fish_helix_prepare_replace
    bind --preset -M visual v 'set -g __fish_helix_count; set -e __fish_helix_register; commandline -f end-selection repaint-mode; set fish_bind_mode default'
    bind --preset -M visual escape 'set -g __fish_helix_count; set -e __fish_helix_register; commandline -f end-selection repaint-mode; set fish_bind_mode default'
    bind --preset -M visual ctrl-\[ 'set -g __fish_helix_count; set -e __fish_helix_register; commandline -f end-selection repaint-mode; set fish_bind_mode default'

    # Insert mode transitions from visual mode (Helix: i/a/I/A collapse selection and enter insert)
    bind --preset -M visual -m insert i 'commandline -f end-selection repaint-mode; set fish_bind_mode insert'
    bind --preset -M visual -m insert a 'set -g fish_cursor_end_mode exclusive; set fish_bind_mode insert' forward-char end-selection repaint-mode
    bind --preset -M visual -m insert I 'commandline -f end-selection beginning-of-line repaint-mode; set fish_bind_mode insert'
    bind --preset -M visual -m insert A 'set -g fish_cursor_end_mode exclusive; set fish_bind_mode insert' end-of-line end-selection repaint-mode

    # Actions on selection
    bind --preset -M visual -m default d '__fish_helix_delete # kill-selection'
    bind --preset -M visual \ed '__fish_helix_delete_noyank; set fish_bind_mode default'
    bind --preset -M visual -m insert c '__fish_helix_change # kill-selection'
    bind --preset -M visual \ec '__fish_helix_change_noyank; set fish_bind_mode insert'
    bind --preset -M visual y __fish_helix_yank
    bind --preset -M visual p __fish_helix_paste_after
    bind --preset -M visual P __fish_helix_paste_before
    bind --preset -M visual R __fish_helix_replace_with_yanked

    bind --preset -M visual \~ 'commandline -f togglecase-selection end-selection repaint-mode; set fish_bind_mode default'
    bind --preset -M visual \` 'commandline -f downcase-selection end-selection repaint-mode; set fish_bind_mode default'
    bind --preset -M visual \e\` 'commandline -f upcase-selection end-selection repaint-mode; set fish_bind_mode default'

    # Indent / Unindent in visual mode
    bind --preset -M visual \> __fish_helix_indent
    bind --preset -M visual \< __fish_helix_unindent


    bind --preset -M visual u undo
    bind --preset -M visual U redo

    # Search / History in visual mode
    bind --preset -M visual / 'commandline -f end-selection repaint-mode; __fish_helix_history_search'
    bind --preset -M visual \? 'commandline -f end-selection repaint-mode; __fish_helix_history_search'
    bind --preset -M visual ctrl-r 'commandline -f end-selection repaint-mode; __fish_helix_history_search'
    bind --preset -M visual ' ',b 'commandline -f end-selection repaint-mode; __fish_helix_history_search'
    bind --preset -M visual -m default n 'commandline -f end-selection history-search-backward repaint-mode'
    bind --preset -M visual -m default N 'commandline -f end-selection history-search-forward repaint-mode'

    bind --preset -M visual ' ',y 'fish_clipboard_copy; commandline -f end-selection repaint-mode; set fish_bind_mode default'
    bind --preset -M visual ' ',p __fish_helix_replace_with_clipboard
    bind --preset -M visual ' ',P __fish_helix_replace_with_clipboard
    bind --preset -M visual ' ',R __fish_helix_replace_with_clipboard
    bind --preset -M visual ' ',e edit_command_buffer
    bind --preset -M visual ctrl-x,ctrl-e edit_command_buffer
    bind --preset -M visual ' ',\? __fish_helix_cheatsheet
    bind --preset -M visual ' ',h __fish_helix_cheatsheet
    bind --preset -M visual ' ',\" __fish_helix_show_registers
    bind --preset -M visual \# __fish_toggle_comment_commandline

    # Setup cursor shape
    fish_helix_cursor
    set -g fish_cursor_selection_mode inclusive

    function __fish_helix_key_bindings_on_mode_change --on-variable fish_bind_mode
        switch $fish_bind_mode
            case insert replace_one helix_replace_one
                set -g fish_cursor_end_mode exclusive
                set -g __fish_helix_count
            case '*'
                set -g fish_cursor_end_mode inclusive
        end
    end

    function __fish_helix_key_bindings_remove_handlers --on-variable __fish_active_key_bindings
        functions --erase __fish_helix_key_bindings_remove_handlers
        functions --erase __fish_helix_key_bindings_on_mode_change
        set -e -g fish_cursor_end_mode
        set -e -g fish_cursor_selection_mode
    end

    set fish_bind_mode $init_mode
end
