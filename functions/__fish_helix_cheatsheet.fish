function __fish_helix_cheatsheet --description 'Helix: show keybindings cheatsheet (<space>? / <space>h)'
    set -l pager cat
    if test -t 1; and command -v less >/dev/null 2>&1
        set pager less -FRX
    else if command -v more >/dev/null 2>&1; and test -t 1
        set pager more
    end

    # Build cheatsheet content with syntax highlighting if terminal supports color
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
  $c_key %$c_desc            Select entire buffer$c_reset
  $c_key ;$c_desc            Collapse selection to single cursor$c_reset
  $c_key Alt-; (\e;)$c_desc  Swap selection anchor and cursor$c_reset
  $c_key Alt+: (\e:)$c_desc  Ensure selection direction is forward$c_reset
  $c_key _$c_desc            Trim leading and trailing whitespace from selection$c_reset
  $c_key J$c_desc            Join lines with space (collapsing indentation)$c_reset
  $c_key Alt+J (\eJ)$c_desc  Join lines without space$c_reset

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

$c_sec EDITING & CLIPBOARD$c_reset
  $c_key d, Alt+d$c_desc     Delete selection (d yanks, Alt+d does not yank)$c_reset
  $c_key c, Alt+c$c_desc     Change selection (c yanks, Alt+c does not yank)$c_reset
  $c_key y$c_desc            Yank (copy) selection to Helix register$c_reset
  $c_key p, P$c_desc         Paste after / before cursor from Helix register$c_reset
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
