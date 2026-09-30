# Helper to accumulate and run numeric prefixes for Helix commands
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
