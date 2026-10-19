# Register support for Helix keybindings

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
            # Black hole: always empty
            return
        case '+'
            # System clipboard
            fish_clipboard_paste
        case '\*'
            # Primary selection or clipboard fallback
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
            # Default register: last yanked/deleted text
            if set -q __fish_helix_reg_default
                printf '%s' "$__fish_helix_reg_default"
            end
        case '/'
            # Last search pattern
            if set -q __fish_helix_reg_slash
                printf '%s' "$__fish_helix_reg_slash"
            end
        case ':'
            # Last executed command from history
            if test (count $history) -gt 0
                printf '%s' "$history[1]"
            end
        case '%'
            # Entire command buffer
            commandline -b
        case '*'
            # Named register (a-z, 0-9)
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

    # Always update default register unless black hole register was explicitly selected
    if test "$reg" != '_'
        set -g __fish_helix_reg_default "$text"
    end

    switch $reg
        case '_'
            # Black hole: discard, do not write
            return
        case '+'
            # System clipboard
            printf '%s' "$text" | fish_clipboard_copy
        case '\*'
            # Primary selection
            if type -q wl-copy
                printf '%s' "$text" | wl-copy --primary 2>/dev/null; or printf '%s' "$text" | fish_clipboard_copy
            else if type -q xsel
                printf '%s' "$text" | xsel -p -i 2>/dev/null; or printf '%s' "$text" | fish_clipboard_copy
            else
                printf '%s' "$text" | fish_clipboard_copy
            end
        case '"'
            # Default register already updated above
            return
        case '/'
            set -g __fish_helix_reg_slash "$text"
        case ':' '%'
            # Read-only in Helix, do not overwrite
            return
        case '*'
            # Named register
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
    # Special registers
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

    # Named registers
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
