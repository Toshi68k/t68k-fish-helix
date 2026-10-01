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
