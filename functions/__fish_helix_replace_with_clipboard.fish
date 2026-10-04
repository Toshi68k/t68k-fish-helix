function __fish_helix_replace_with_clipboard --description 'Helix: replace selection or char with clipboard content (<space>R)'
    set -l clip (fish_clipboard_paste)
    if test -z "$clip"
        return
    end

    set -l buf (commandline -b)
    set -l pos (commandline -C)
    set -l len 1

    if commandline --selection-start >/dev/null 2>&1
        set -l sel (commandline -s)
        set -l start (commandline --selection-start)
        set -l end (commandline --selection-end)
        set pos (math "min($start, $end)")
        set len (string length -- "$sel")
        if test $len -eq 0
            set len 1
        end
        commandline -f end-selection
    end

    set -l prefix ""
    if test $pos -gt 0
        set prefix (string sub -s 1 -l $pos -- "$buf")
    end
    set -l suffix (string sub -s (math $pos + $len + 1) -- "$buf")

    set -l new_buf "$prefix$clip$suffix"
    commandline -r -- "$new_buf"
    commandline -C (math $pos + (string length -- "$clip"))
    commandline -f repaint-mode
    set fish_bind_mode default
end
