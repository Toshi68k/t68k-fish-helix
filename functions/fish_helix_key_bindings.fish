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

# Helix Normal mode movements (Selection-First):
function __fish_helix_normal_w --description 'Helix normal mode: select next word start (w)'
    set -l count (__fish_helix_consume_count)
    commandline -f end-selection begin-selection
    for i in (seq $count)
        commandline -f forward-word-vi
    end
    commandline -f repaint-mode
end

function __fish_helix_normal_b --description 'Helix normal mode: select prev word start (b)'
    set -l count (__fish_helix_consume_count)
    commandline -f end-selection begin-selection
    for i in (seq $count)
        commandline -f backward-word
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
    commandline -f end-selection begin-selection
    for i in (seq $count)
        commandline -f forward-bigword-vi
    end
    commandline -f repaint-mode
end

function __fish_helix_normal_B --description 'Helix normal mode: select prev WORD start (B)'
    set -l count (__fish_helix_consume_count)
    commandline -f end-selection begin-selection
    for i in (seq $count)
        commandline -f backward-bigword
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
    set -l is_selected 0
    if commandline --selection-start >/dev/null 2>&1
        set is_selected 1
    end

    if test $is_selected -eq 1
        commandline -f end-of-line forward-char end-of-line repaint-mode
    else
        commandline -f beginning-of-line begin-selection end-of-line repaint-mode
    end
    set fish_bind_mode visual
end

function __fish_helix_extend_to_line_bounds --description 'Helix: extend to line bounds (X)'
    if not commandline --selection-start >/dev/null 2>&1
        commandline -f begin-selection
    end
    commandline -f beginning-of-line swap-selection-start-stop end-of-line repaint-mode
    set fish_bind_mode visual
end

function __fish_helix_delete --description 'Helix: delete selection or char under cursor (d)'
    if commandline --selection-start >/dev/null 2>&1
        commandline -f kill-selection end-selection repaint-mode
    else
        commandline -f delete-char repaint-mode
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

function __fish_helix_change --description 'Helix: change selection or char under cursor (c)'
    if commandline --selection-start >/dev/null 2>&1
        commandline -f kill-selection end-selection repaint-mode
    else
        commandline -f delete-char repaint-mode
    end
    set fish_bind_mode insert
end

function __fish_helix_change_noyank --description 'Helix: change without yanking (Alt-c)'
    __fish_helix_delete_noyank
    set fish_bind_mode insert
end

function __fish_helix_yank --description 'Helix: yank selection or char under cursor (y)'
    set -g fish_cursor_end_mode exclusive
    if commandline --selection-start >/dev/null 2>&1
        commandline -f kill-selection yank end-selection repaint-mode
    else
        commandline -f begin-selection forward-char kill-selection yank backward-char end-selection repaint-mode
    end
    set -g fish_cursor_end_mode inclusive
    set fish_bind_mode default
end

function __fish_helix_replace_with_yanked --description 'Helix: replace selection or char with yanked text (R)'
    set -l is_selected 0
    set -l len 1
    set -l pos (commandline -C)

    if commandline --selection-start >/dev/null 2>&1
        set is_selected 1
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

    commandline -C $pos
    for i in (seq $len)
        commandline -f delete-char
    end
    commandline -f yank repaint-mode
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
    set -l line_no (commandline -L)
    set -l lines (commandline -b | string split \n)
    set -l cur_line "$lines[$line_no]"

    set lines[$line_no] "    $cur_line"
    set -l new_buf (string join \n -- $lines)
    commandline -r -- "$new_buf"
    commandline -f repaint-mode
    set fish_bind_mode default
end

function __fish_helix_unindent --description 'Helix: unindent line or selection (<)'
    set -l line_no (commandline -L)
    set -l lines (commandline -b | string split \n)
    set -l cur_line "$lines[$line_no]"

    set lines[$line_no] (string replace -r '^ {1,4}' '' -- "$cur_line")
    set -l new_buf (string join \n -- $lines)
    commandline -r -- "$new_buf"
    commandline -f repaint-mode
    set fish_bind_mode default
end

function __fish_helix_get_surround_pair --argument-names char
    switch $char
        case '(' ')'
            echo '('\n')'
        case '[' ']'
            echo '['\n']'
        case '{' '}'
            echo '{'\n'}'
        case '<' '>'
            echo '<'\n'>'
        case '*'
            echo "$char"\n"$char"
    end
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

        set -q fish_cursor_helix_replace_one
        or set -g fish_cursor_helix_replace_one underscore

        function __fish_helix_cursor --argument-names varname
            if not status is-interactive; and not status is-interactive-read
                return
            end
            if not set -q $varname
                switch $varname
                    case fish_cursor_insert
                        __fish_cursor_xterm line
                    case fish_cursor_visual fish_cursor_helix_replace_one
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

    # Normal mode backspace & delete
    bind --preset -M default backspace backward-char
    bind --preset -M default delete delete-char

    # Cancel commandline / clear
    bind --preset -M default ctrl-c clear-commandline repaint-mode
    bind --preset -M default :,q exit

    # Reset repeat count on escape in default mode
    bind --preset -M default escape 'set -g __fish_helix_count; commandline -f end-selection repaint-mode'
    bind --preset -M default ctrl-\[ 'set -g __fish_helix_count; commandline -f end-selection repaint-mode'

    # Digit counts for repeat motions (1-9, and 0 when count already started)
    for i in (seq 1 9)
        bind --preset -M default $i "__fish_helix_arg_digit $i"
    end
    bind --preset -M default 0 "if test -n \"\$__fish_helix_count\"; __fish_helix_arg_digit 0; end"

    # --- Normal Mode: Insert Transitions ---
    bind --preset -M default i 'set fish_bind_mode insert; commandline -f repaint-mode'
    bind --preset -M default a 'commandline -f forward-char; set fish_bind_mode insert; commandline -f repaint-mode'
    bind --preset -M default I 'commandline -f beginning-of-line; set fish_bind_mode insert; commandline -f repaint-mode'
    bind --preset -M default A 'commandline -f end-of-line; set fish_bind_mode insert; commandline -f repaint-mode'
    bind --preset -M default o 'commandline -f end-of-line; commandline -i \n; set fish_bind_mode insert; commandline -f repaint-mode'
    bind --preset -M default O 'commandline -f beginning-of-line; commandline -i \n; commandline -f backward-char; set fish_bind_mode insert; commandline -f repaint-mode'

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
    # % in Helix selects all buffer (NOT vim match bracket!)
    bind --preset -M default % 'commandline -f beginning-of-buffer begin-selection end-of-buffer repaint-mode; set fish_bind_mode visual'
    # ; collapses selection
    bind --preset -M default ';' 'commandline -f end-selection repaint-mode'
    # Alt-; flips selection direction
    bind --preset -M default \e\; 'commandline -f swap-selection-start-stop repaint-mode'

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
    bind --preset -M default p 'set -g fish_cursor_end_mode exclusive; commandline -f forward-char; set -g fish_cursor_end_mode inclusive; commandline -f yank'
    bind --preset -M default P yank

    # Replace with yanked
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

    # --- Match Sub-Mode (m) ---
    # mm jumps to matching bracket
    bind --preset -M default m,m jump-to-matching-bracket
    bind --preset -M default -m helix_surround_add m,s repaint-mode

    # --- Space Sub-Mode ( ) ---
    bind --preset -M default ' ',y fish_clipboard_copy
    bind --preset -M default ' ',p fish_clipboard_paste
    bind --preset -M default ' ',P fish_clipboard_paste
    bind --preset -M default ' ',f complete-and-search
    bind --preset -M default ' ',b history-pager
    bind --preset -M default ' ',c __fish_toggle_comment_commandline

    # --- Single Character Replace Mode (r) ---
    bind --preset -M default -m helix_replace_one r repaint-mode
    bind --preset -M helix_replace_one -m default '' 'set -g fish_cursor_end_mode exclusive; commandline -f delete-char self-insert backward-char repaint-mode; set -g fish_cursor_end_mode inclusive'
    bind --preset -M helix_replace_one -m default escape cancel repaint-mode
    bind --preset -M helix_replace_one -m default ctrl-\[ cancel repaint-mode

    # --- Surround Add Mode (ms) ---
    bind --preset -M helix_surround_add -m default '' '__fish_helix_surround_add $argv'
    bind --preset -M helix_surround_add -m default escape cancel repaint-mode
    bind --preset -M helix_surround_add -m default ctrl-\[ cancel repaint-mode

    # ==========================================
    # --- Select / Extend Mode (visual) ---
    # ==========================================
    # Movements extend selection
    bind --preset -M visual h backward-char
    bind --preset -M visual l forward-char
    bind --preset -M visual k up-line
    bind --preset -M visual j down-line
    bind --preset -M visual w forward-word-vi
    bind --preset -M visual b backward-word
    bind --preset -M visual e forward-word-end
    bind --preset -M visual W forward-bigword-vi
    bind --preset -M visual B backward-bigword
    bind --preset -M visual E forward-bigword-end

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
    bind --preset -M visual m,m jump-to-matching-bracket

    # Selection manipulation in visual mode
    bind --preset -M visual x __fish_helix_select_line
    bind --preset -M visual X __fish_helix_extend_to_line_bounds
    bind --preset -M visual % 'commandline -f beginning-of-buffer begin-selection end-of-buffer repaint-mode'
    bind --preset -M visual ';' 'commandline -f end-selection repaint-mode; set fish_bind_mode default'
    bind --preset -M visual \e\; 'commandline -f swap-selection-start-stop repaint-mode'
    bind --preset -M visual v 'commandline -f end-selection repaint-mode; set fish_bind_mode default'
    bind --preset -M visual escape 'commandline -f end-selection repaint-mode; set fish_bind_mode default'
    bind --preset -M visual ctrl-\[ 'commandline -f end-selection repaint-mode; set fish_bind_mode default'

    # Actions on selection
    bind --preset -M visual -m default d 'commandline -f kill-selection end-selection repaint-mode; set fish_bind_mode default'
    bind --preset -M visual \ed '__fish_helix_delete_noyank; set fish_bind_mode default'
    bind --preset -M visual -m insert c 'commandline -f kill-selection end-selection repaint-mode; set fish_bind_mode insert'
    bind --preset -M visual \ec '__fish_helix_change_noyank; set fish_bind_mode insert'
    bind --preset -M visual -m default y 'set -g fish_cursor_end_mode exclusive; commandline -f kill-selection yank end-selection repaint-mode; set -g fish_cursor_end_mode inclusive; set fish_bind_mode default'
    bind --preset -M visual p __fish_helix_replace_with_yanked
    bind --preset -M visual P __fish_helix_replace_with_yanked
    bind --preset -M visual R __fish_helix_replace_with_yanked

    bind --preset -M visual \~ 'commandline -f togglecase-selection end-selection repaint-mode; set fish_bind_mode default'
    bind --preset -M visual \` 'commandline -f downcase-selection end-selection repaint-mode; set fish_bind_mode default'
    bind --preset -M visual \e\` 'commandline -f upcase-selection end-selection repaint-mode; set fish_bind_mode default'

    bind --preset -M visual -m helix_surround_add m,s repaint-mode

    bind --preset -M visual u undo
    bind --preset -M visual U redo

    bind --preset -M visual ' ',y 'fish_clipboard_copy; commandline -f end-selection repaint-mode; set fish_bind_mode default'
    bind --preset -M visual ' ',p fish_clipboard_paste
    bind --preset -M visual \# __fish_toggle_comment_commandline

    # Setup cursor shape
    fish_helix_cursor
    set -g fish_cursor_selection_mode inclusive

    function __fish_helix_key_bindings_on_mode_change --on-variable fish_bind_mode
        switch $fish_bind_mode
            case insert helix_replace_one
                set -g fish_cursor_end_mode exclusive
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
