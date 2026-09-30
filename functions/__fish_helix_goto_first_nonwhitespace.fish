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
