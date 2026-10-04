#!/usr/bin/env fish
# Test suite for t68k-fish-helix

set -l script_path (status filename)
set -l test_dir (path dirname (path resolve $script_path))
set -l plugin_dir (path dirname $test_dir)

set -g passed 0
set -g failed 0

function assert_equal --argument-names actual expected message
    if test "$actual" = "$expected"
        set -g passed (math $passed + 1)
        set_color green
        echo "  ✓ PASS: $message"
        set_color normal
    else
        set -g failed (math $failed + 1)
        set_color red
        echo "  ✗ FAIL: $message"
        echo "    Expected: '$expected'"
        echo "    Actual:   '$actual'"
        set_color normal
    end
end

function assert_contains --argument-names haystack needle message
    if string match -q "*$needle*" -- "$haystack"
        set -g passed (math $passed + 1)
        set_color green
        echo "  ✓ PASS: $message"
        set_color normal
    else
        set -g failed (math $failed + 1)
        set_color red
        echo "  ✗ FAIL: $message"
        echo "    String did not contain '$needle'"
        echo "    Actual string: '$haystack'"
        set_color normal
    end
end

echo "=== Testing t68k-fish-helix Keybindings & Helix Authenticity ==="
echo

# 1. Source all plugin functions
for f in $plugin_dir/functions/*.fish
    source $f
end
source $plugin_dir/conf.d/t68k_fish_helix.fish

# 2. Activate keybindings
fish_helix_key_bindings default

# 3. Verify Helix vs Vim Differences
echo "--- Testing Core Helix Philosophy vs Vim Regressions ---"

# x MUST select line in Helix, NEVER delete character like Vim
set -l bind_x (bind -M default x | string trim)
assert_contains "$bind_x" "__fish_helix_select_line" "x in normal mode selects line (Helix), NOT delete-char (Vim)"

# % MUST select buffer in Helix, NEVER jump bracket like Vim
set -l bind_percent (bind -M default % | string trim)
assert_contains "$bind_percent" "begin-selection" "% in normal mode selects buffer (Helix), NOT jump bracket (Vim)"

# mm jumps matching bracket in Helix (Vim uses %)
set -l bind_mm (bind -M default m,m | string trim)
assert_contains "$bind_mm" "jump-to-matching-bracket" "mm in normal mode jumps matching bracket (Helix)"

# Undo / Redo: u is undo, U is redo (Helix)
set -l bind_u (bind -M default u | string trim)
assert_contains "$bind_u" "undo" "u is undo"
set -l bind_U (bind -M default U | string trim)
assert_contains "$bind_U" "redo" "U is redo (Helix), NOT vim Ctrl-r"

# Selection collapse: ; collapses selection in Helix
set -l bind_semi (bind -M default ';' | string trim)
assert_contains "$bind_semi" "end-selection" "; collapses selection (Helix)"

# Selection flip: Alt-; flips selection direction in Helix
set -l bind_alt_semi (bind -M default \e\; | string trim)
assert_contains "$bind_alt_semi" "swap-selection-start-stop" "Alt-; swaps selection head and anchor (Helix)"

# Goto mode: gh is line start, gl is line end (Helix)
set -l bind_gh (bind -M default g,h | string trim)
assert_contains "$bind_gh" "beginning-of-line" "gh goes to line start (Helix)"

set -l bind_gl (bind -M default g,l | string trim)
assert_contains "$bind_gl" "end-of-line" "gl goes to line end (Helix)"

set -l bind_gs (bind -M default g,s | string trim)
assert_contains "$bind_gs" "__fish_helix_goto_first_nonwhitespace" "gs goes to first non-whitespace (Helix)"

set -l bind_gg (bind -M default g,g | string trim)
assert_contains "$bind_gg" "beginning-of-buffer" "gg goes to start of buffer (Helix)"

set -l bind_ge (bind -M default g,e | string trim)
assert_contains "$bind_ge" "end-of-buffer" "ge goes to end of buffer (Helix)"

# Replace with yanked: R
set -l bind_R (bind -M default R | string trim)
assert_contains "$bind_R" "__fish_helix_replace_with_yanked" "R replaces with yanked text (Helix)"

# Selection-first delete (d) and change (c)
set -l bind_d (bind -M default d | string trim)
assert_contains "$bind_d" "__fish_helix_delete" "d operates on selection/char (Helix selection-first)"

set -l bind_c (bind -M default c | string trim)
assert_contains "$bind_c" "__fish_helix_change" "c changes selection/char into insert mode (Helix)"

# Space mode bindings
set -l bind_sp_y (bind -M default ' ',y | string trim)
assert_contains "$bind_sp_y" "fish_clipboard_copy" "<space>y copies to clipboard (Helix Space mode)"

set -l bind_sp_p (bind -M default ' ',p | string trim)
assert_contains "$bind_sp_p" "fish_clipboard_paste" "<space>p pastes from clipboard (Helix Space mode)"

# Search / History in Normal mode
set -l bind_slash (bind -M default / | string trim)
assert_contains "$bind_slash" "__fish_helix_history_search" "/ in normal mode invokes history search dispatcher"

set -l bind_qmark (bind -M default \? | string trim)
assert_contains "$bind_qmark" "__fish_helix_history_search" "? in normal mode invokes history search dispatcher"

set -l bind_ctrl_r (bind -M default ctrl-r | string trim)
assert_contains "$bind_ctrl_r" "__fish_helix_history_search" "Ctrl-r in normal mode invokes history search dispatcher"

set -l bind_sp_b (bind -M default ' ',b | string trim)
assert_contains "$bind_sp_b" "__fish_helix_history_search" "<space>b in normal mode invokes history search dispatcher"

set -l bind_n (bind -M default n | string trim)
assert_contains "$bind_n" "history-search-backward" "n in normal mode searches history backward (Helix search_next)"

set -l bind_N (bind -M default N | string trim)
assert_contains "$bind_N" "history-search-forward" "N in normal mode searches history forward (Helix search_prev)"

# Insert mode history search (Ctrl-r) & Up arrow
set -l bind_ins_ctrl_r (bind -M insert ctrl-r | string trim)
assert_contains "$bind_ins_ctrl_r" "__fish_helix_history_search" "Ctrl-r in insert mode invokes history search dispatcher"

set -l bind_ins_up (bind -M insert up | string trim)
assert_contains "$bind_ins_up" "__fish_helix_up" "Up in insert mode invokes up dispatcher"

# Insert mode transitions
set -l bind_i (bind -M default i | string trim)
assert_contains "$bind_i" "insert" "i enters insert mode"

set -l bind_a (bind -M default a | string trim)
assert_contains "$bind_a" "forward-char" "a appends after cursor"

set -l bind_I (bind -M default I | string trim)
assert_contains "$bind_I" "beginning-of-line" "I inserts at beginning of line"

set -l bind_A (bind -M default A | string trim)
assert_contains "$bind_A" "end-of-line" "A inserts at end of line"
assert_contains "$bind_A" "-m insert" "A transitions mode to insert"
assert_contains "$bind_A" "exclusive" "A sets fish_cursor_end_mode exclusive so it appends after last character"

set -l bind_a_check (bind -M default a | string trim)
assert_contains "$bind_a_check" "-m insert" "a transitions mode to insert"
assert_contains "$bind_a_check" "exclusive" "a sets fish_cursor_end_mode exclusive so it can advance past last character"

set -l bind_o (bind -M default o | string trim)
assert_contains "$bind_o" "insert-line-under" "o opens line below"
assert_contains "$bind_o" "exclusive" "o sets fish_cursor_end_mode exclusive"

set -l bind_O (bind -M default O | string trim)
assert_contains "$bind_O" "insert-line-over" "O opens line above"
assert_contains "$bind_O" "exclusive" "O sets fish_cursor_end_mode exclusive"

# Visual (Select) mode insert transitions
set -l bind_vis_A (bind -M visual A | string trim)
assert_contains "$bind_vis_A" "end-of-line" "Visual A moves to end of line"
assert_contains "$bind_vis_A" "-m insert" "Visual A enters insert mode"
assert_contains "$bind_vis_A" "exclusive" "Visual A sets cursor end mode exclusive"
assert_contains "$bind_vis_A" "end-selection" "Visual A collapses selection"

set -l bind_vis_I (bind -M visual I | string trim)
assert_contains "$bind_vis_I" "beginning-of-line" "Visual I moves to beginning of line"
assert_contains "$bind_vis_I" "-m insert" "Visual I enters insert mode"
assert_contains "$bind_vis_I" "end-selection" "Visual I collapses selection"

set -l bind_vis_i (bind -M visual i | string trim)
assert_contains "$bind_vis_i" "-m insert" "Visual i enters insert mode"
assert_contains "$bind_vis_i" "end-selection" "Visual i collapses selection"

set -l bind_vis_a (bind -M visual a | string trim)
assert_contains "$bind_vis_a" "forward-char" "Visual a advances after selection"
assert_contains "$bind_vis_a" "-m insert" "Visual a enters insert mode"
assert_contains "$bind_vis_a" "exclusive" "Visual a sets cursor end mode exclusive"
assert_contains "$bind_vis_a" "end-selection" "Visual a collapses selection"

# Insert mode deletion keys
set -l bind_bs (bind -M insert backspace | string trim)
assert_contains "$bind_bs" "backward-delete-char" "backspace in insert mode deletes char backward"

set -l bind_del (bind -M insert delete | string trim)
assert_contains "$bind_del" "delete-char" "delete in insert mode deletes char forward"

set -l bind_cw (bind -M insert ctrl-w | string trim)
assert_contains "$bind_cw" "backward-kill-word" "ctrl-w in insert mode deletes word backward"

set -l bind_cu (bind -M insert ctrl-u | string trim)
assert_contains "$bind_cu" "backward-kill-line" "ctrl-u in insert mode deletes line backward"

# Word motions in Normal mode (Helix: motions select/replace the range!)
set -l bind_w (bind -M default w | string trim)
assert_contains "$bind_w" "__fish_helix_normal_w" "w in normal mode selects next word (Helix)"

set -l bind_b (bind -M default b | string trim)
assert_contains "$bind_b" "__fish_helix_normal_b" "b in normal mode selects previous word (Helix)"

set -l bind_e (bind -M default e | string trim)
assert_contains "$bind_e" "__fish_helix_normal_e" "e in normal mode selects to word end (Helix)"

# Char motions in Normal mode (Helix: collapse selection and move)
set -l bind_h (bind -M default h | string trim)
assert_contains "$bind_h" "__fish_helix_normal_h" "h in normal mode collapses selection and moves left (Helix)"

set -l bind_l (bind -M default l | string trim)
assert_contains "$bind_l" "__fish_helix_normal_l" "l in normal mode collapses selection and moves right (Helix)"

set -l bind_k (bind -M default k | string trim)
assert_contains "$bind_k" "__fish_helix_normal_k" "k in normal mode collapses selection and moves up (Helix)"

set -l bind_j (bind -M default j | string trim)
assert_contains "$bind_j" "__fish_helix_normal_j" "j in normal mode collapses selection and moves down (Helix)"

# Verify k and j execution does not throw 'Unknown input function' error
set -l exec_output (fish -i --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    fish_helix_key_bindings default
    __fish_helix_normal_k
    __fish_helix_normal_j
" 2>&1)
set -l err_match (string match "*Unknown input function*" -- "$exec_output")
assert_equal "$err_match" "" "Executing normal mode k and j does not trigger Unknown input function error"

# Indent / Unindent
set -l bind_indent (bind -M default \> | string trim)
assert_contains "$bind_indent" "__fish_helix_indent" "> indents line"

set -l bind_unindent (bind -M default \< | string trim)
assert_contains "$bind_unindent" "__fish_helix_unindent" "< unindents line"

# Multi-line indent/unindent with flag-like lines
set -l multiline_indent_res (fish -i --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    commandline -r -- 'ls \\\n-l'
    commandline -C 5
    __fish_helix_indent
    commandline -b
" 2>&1 | string match "*ls*-l*" | string length)
if test -n "$multiline_indent_res" -a "$multiline_indent_res" -gt 0
    set -g passed (math $passed + 1)
    set_color green
    echo "  ✓ PASS: Indenting multi-line commands with leading flags succeeds without option errors"
    set_color normal
else
    set -g failed (math $failed + 1)
    set_color red
    echo "  ✗ FAIL: Indenting multi-line commands with leading flags failed"
    set_color normal
end

# 4. Verify Visual (Select / Extend) Mode bindings
echo
echo "--- Testing Select / Extend Mode (visual) ---"
set -l bind_vis_d (bind -M visual d | string trim)
assert_contains "$bind_vis_d" "kill-selection" "d in visual mode kills selection"

set -l bind_vis_c (bind -M visual c | string trim)
assert_contains "$bind_vis_c" "kill-selection" "c in visual mode kills selection and enters insert"

set -l bind_vis_semi (bind -M visual ';' | string trim)
assert_contains "$bind_vis_semi" "end-selection" "; in visual mode collapses selection"

set -l bind_vis_gh (bind -M visual g,h | string trim)
assert_contains "$bind_vis_gh" "beginning-of-line" "gh in visual mode extends to line start"

set -l bind_vis_gl (bind -M visual g,l | string trim)
assert_contains "$bind_vis_gl" "end-of-line" "gl in visual mode extends to line end"

# Jump motions in visual mode (v-t-<char> and v-t-enter)
set -l bind_vis_t (bind -M visual t | string trim)
assert_contains "$bind_vis_t" "forward-jump-till" "t in visual mode is forward-jump-till"

set -l bind_vis_t_enter (bind -M visual t,enter | string trim)
assert_contains "$bind_vis_t_enter" "end-of-line" "v-t-enter in visual mode extends selection to end-of-line"

set -l bind_vis_f_enter (bind -M visual f,enter | string trim)
assert_contains "$bind_vis_f_enter" "end-of-line" "v-f-enter in visual mode extends selection to end-of-line"

# Search / History in visual mode
set -l bind_vis_slash (bind -M visual / | string trim)
assert_contains "$bind_vis_slash" "__fish_helix_history_search" "/ in visual mode invokes history search dispatcher"
assert_contains "$bind_vis_slash" "end-selection" "/ in visual mode collapses selection"

set -l bind_vis_qmark (bind -M visual \? | string trim)
assert_contains "$bind_vis_qmark" "__fish_helix_history_search" "? in visual mode invokes history search dispatcher"
assert_contains "$bind_vis_qmark" "end-selection" "? in visual mode collapses selection"

set -l bind_vis_ctrl_r (bind -M visual ctrl-r | string trim)
assert_contains "$bind_vis_ctrl_r" "__fish_helix_history_search" "Ctrl-r in visual mode invokes history search dispatcher"
assert_contains "$bind_vis_ctrl_r" "end-selection" "Ctrl-r in visual mode collapses selection"

set -l bind_vis_sp_b (bind -M visual ' ',b | string trim)
assert_contains "$bind_vis_sp_b" "__fish_helix_history_search" "<space>b in visual mode invokes history search dispatcher"
assert_contains "$bind_vis_sp_b" "end-selection" "<space>b in visual mode collapses selection"

set -l bind_vis_n (bind -M visual n | string trim)
assert_contains "$bind_vis_n" "history-search-backward" "n in visual mode searches history backward"

set -l bind_vis_N (bind -M visual N | string trim)
assert_contains "$bind_vis_N" "history-search-forward" "N in visual mode searches history forward"

# 5. Verify Mode Prompt
echo
echo "--- Testing Mode Prompt ---"
set -g fish_key_bindings fish_helix_key_bindings
set -g fish_helix_show_mode_prompt true

set -g fish_bind_mode default
set -l prompt_norm (fish_helix_mode_prompt | string trim)
assert_contains "$prompt_norm" "[NOR]" "Normal mode displays [NOR]"

set -g fish_bind_mode insert
set -l prompt_ins (fish_helix_mode_prompt | string trim)
assert_contains "$prompt_ins" "[INS]" "Insert mode displays [INS]"

set -g fish_bind_mode visual
set -l prompt_sel (fish_helix_mode_prompt | string trim)
assert_contains "$prompt_sel" "[SEL]" "Select mode displays [SEL]"

set -g fish_bind_mode replace_one
set -l prompt_rep (fish_helix_mode_prompt | string trim)
assert_contains "$prompt_rep" "[REP]" "Replace mode (replace_one) displays [REP]"

set -g fish_bind_mode helix_replace_one
set -l prompt_rep_legacy (fish_helix_mode_prompt | string trim)
assert_contains "$prompt_rep_legacy" "[REP]" "Replace mode legacy (helix_replace_one) displays [REP]"

# Test disabling prompt output (e.g. for Tide / Starship)
set -g fish_helix_show_mode_prompt false
set -l prompt_disabled (fish_helix_mode_prompt | string trim)
assert_equal "$prompt_disabled" "" "Prompt output is empty when fish_helix_show_mode_prompt is false"
set -g fish_helix_show_mode_prompt true

# 6. Verify Helper Logic
echo
echo "--- Testing Helper Functions ---"
set -l pair_paren (__fish_helix_get_surround_pair '(')
assert_equal "$pair_paren[1]" "(" "Surround open paren"
assert_equal "$pair_paren[2]" ")" "Surround close paren"

set -l pair_quote (__fish_helix_get_surround_pair '"')
assert_equal "$pair_quote[1]" '"' "Surround open quote"
assert_equal "$pair_quote[2]" '"' "Surround close quote"

# Count consumption
set -g __fish_helix_count "12"
set -l consumed (__fish_helix_consume_count)
assert_equal "$consumed" "12" "Count accumulation consumed correctly"
assert_equal "$__fish_helix_count" "" "Count reset after consumption"

# 7. Verify Atuin & History Search Integration
echo
echo "--- Testing Atuin & History Search Integration ---"

# Atuin enable check
set -l orig_atuin $fish_helix_atuin
set -g fish_helix_atuin false
set -l disabled_res 0
if not __fish_helix_is_atuin_enabled
    set disabled_res 1
end
assert_equal "$disabled_res" "1" "fish_helix_atuin=false correctly disables atuin"

set -g fish_helix_atuin true
set -l enabled_res 0
if __fish_helix_is_atuin_enabled
    set enabled_res 1
end
assert_equal "$enabled_res" "1" "fish_helix_atuin=true enables atuin when binary or function present"

# Atuin keymap mode spoofing (default mode -> vim-normal, insert mode -> vim-insert)
set -l spoof_res (fish --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    set -g fish_key_bindings fish_helix_key_bindings
    set -g fish_bind_mode default
    function _atuin_search
        set -l keymap_mode
        switch \$fish_key_bindings
            case fish_vi_key_bindings fish_hybrid_key_bindings
                switch \$fish_bind_mode
                    case default
                        set keymap_mode vim-normal
                    case insert
                        set keymap_mode vim-insert
                end
            case '*'
                set keymap_mode emacs
        end
        echo \$keymap_mode
    end
    __fish_helix_atuin_search
" 2>&1 | string trim)
assert_equal "$spoof_res" "vim-normal" "Atuin search receives vim-normal mode in default mode"

set -l spoof_res_ins (fish --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    set -g fish_key_bindings fish_helix_key_bindings
    set -g fish_bind_mode insert
    function _atuin_search
        set -l keymap_mode
        switch \$fish_key_bindings
            case fish_vi_key_bindings fish_hybrid_key_bindings
                switch \$fish_bind_mode
                    case default
                        set keymap_mode vim-normal
                    case insert
                        set keymap_mode vim-insert
                end
            case '*'
                set keymap_mode emacs
        end
        echo \$keymap_mode
    end
    __fish_helix_atuin_search
" 2>&1 | string trim)
assert_equal "$spoof_res_ins" "vim-insert" "Atuin search receives vim-insert mode in insert mode"

# Restore original atuin setting
set -g fish_helix_atuin $orig_atuin

# 8. Verify Match Mode Extensions (Textobjects & Surround Delete/Replace)
echo
echo "--- Testing Match Mode Extensions (Textobjects & Surround) ---"

# Direct sequence bindings in default mode
set -l bind_mi_quote (bind -M default m,i,\" | string trim)
assert_contains "$bind_mi_quote" "__fish_helix_textobject i" "mi\" in normal mode binds to textobject inside quote"

set -l bind_ma_quote (bind -M default m,a,\" | string trim)
assert_contains "$bind_ma_quote" "__fish_helix_textobject a" "ma\" in normal mode binds to textobject around quote"

set -l bind_mi_w (bind -M default m,i,w | string trim)
assert_contains "$bind_mi_w" "__fish_helix_textobject i" "miw in normal mode binds to textobject inside word"

set -l bind_ma_w (bind -M default m,a,w | string trim)
assert_contains "$bind_ma_w" "__fish_helix_textobject a" "maw in normal mode binds to textobject around word"

set -l bind_mi_paren (bind -M default m,i,\( | string trim)
assert_contains "$bind_mi_paren" "__fish_helix_textobject i" "mi( in normal mode binds to textobject inside paren"

set -l bind_mi_b (bind -M default m,i,b | string trim)
assert_contains "$bind_mi_b" "__fish_helix_textobject i" "mib in normal mode binds to textobject inside paren alias"

set -l bind_md_quote (bind -M default m,d,\" | string trim)
assert_contains "$bind_md_quote" "__fish_helix_surround_delete" "md\" in normal mode binds to surround delete quote"

set -l bind_ms_quote (bind -M default m,s,\" | string trim)
assert_contains "$bind_ms_quote" "__fish_helix_surround_add" "ms\" in normal mode binds to surround add quote"

set -l bind_mr_quote (bind -M default m,r,\",\' | string trim)
assert_contains "$bind_mr_quote" "__fish_helix_surround_replace_direct" "mr\"' in normal mode binds to surround replace direct"

# Direct sequence bindings in visual mode
set -l bind_vis_mi (bind -M visual m,i,\" | string trim)
assert_contains "$bind_vis_mi" "__fish_helix_textobject i" "mi\" in visual mode binds to textobject inside quote"

set -l bind_vis_ma (bind -M visual m,a,\" | string trim)
assert_contains "$bind_vis_ma" "__fish_helix_textobject a" "ma\" in visual mode binds to textobject around quote"

set -l bind_vis_md (bind -M visual m,d,\" | string trim)
assert_contains "$bind_vis_md" "__fish_helix_surround_delete" "md\" in visual mode binds to surround delete quote"

set -l bind_vis_ms (bind -M visual m,s,\" | string trim)
assert_contains "$bind_vis_ms" "__fish_helix_surround_add" "ms\" in visual mode binds to surround add quote"

# Helper: __fish_helix_get_surround_pair with aliases (b, r, B)
set -l pair_b (__fish_helix_get_surround_pair 'b')
assert_equal "$pair_b[1]" "(" "b resolves to ("
assert_equal "$pair_b[2]" ")" "b resolves to )"

set -l pair_r (__fish_helix_get_surround_pair 'r')
assert_equal "$pair_r[1]" "[" "r resolves to ["
assert_equal "$pair_r[2]" "]" "r resolves to ]"

set -l pair_B (__fish_helix_get_surround_pair 'B')
assert_equal "$pair_B[1]" "{" "B resolves to {"
assert_equal "$pair_B[2]" "}" "B resolves to }"

# Helper: __fish_helix_find_pair
set -l quote_pair (__fish_helix_find_pair '"' 'git commit -m "initial commit"' 18)
assert_equal "$quote_pair[1]" "14" "find_pair double quote open index"
assert_equal "$quote_pair[2]" "29" "find_pair double quote close index"

set -l paren_nested (__fish_helix_find_pair '(' 'echo (math (expr 1 + 2))' 18)
assert_equal "$paren_nested[1]" "11" "find_pair nested paren inner open index"
assert_equal "$paren_nested[2]" "22" "find_pair nested paren inner close index"

# Helper: __fish_helix_find_word_bounds
set -l word_bounds_in (__fish_helix_find_word_bounds 'w' 'i' 'git commit -m "initial"' 6)
assert_equal "$word_bounds_in[1]" "4" "find_word_bounds commit start"
assert_equal "$word_bounds_in[2]" "10" "find_word_bounds commit end"

set -l word_bounds_ar (__fish_helix_find_word_bounds 'w' 'a' 'git commit -m "initial"' 6)
assert_equal "$word_bounds_ar[1]" "4" "find_word_bounds commit around start"
assert_equal "$word_bounds_ar[2]" "11" "find_word_bounds commit around end (with space)"

# Interactive execution tests: Surround Delete
set -l test_del_res (fish -i --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    commandline -r -- 'git commit -m \"initial commit\"'
    commandline -C 18
    __fish_helix_surround_delete '\"'
    commandline -b
" 2>&1 | tail -n 1 | string trim)
assert_equal "$test_del_res" 'git commit -m initial commit' "Surround delete removes double quotes"

set -l test_del_paren (fish -i --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    commandline -r -- 'echo (pwd)'
    commandline -C 7
    __fish_helix_surround_delete '('
    commandline -b
" 2>&1 | tail -n 1 | string trim)
assert_equal "$test_del_paren" 'echo pwd' "Surround delete removes parentheses"

# Interactive execution tests: Surround Replace
set -l test_rep_res (fish -i --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    commandline -r -- 'echo \"hello world\"'
    commandline -C 7
    set -g __fish_helix_surround_old '\"'
    __fish_helix_surround_replace \"'\"
    commandline -b
" 2>&1 | tail -n 1 | string trim)
assert_equal "$test_rep_res" "echo 'hello world'" "Surround replace converts double quotes to single quotes"

set -l test_rep_paren (fish -i --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    commandline -r -- 'echo (pwd)'
    commandline -C 7
    set -g __fish_helix_surround_old 'b'
    __fish_helix_surround_replace 'r'
    commandline -b
" 2>&1 | tail -n 1 | string trim)
assert_equal "$test_rep_paren" 'echo [pwd]' "Surround replace converts parens (b) to square brackets (r)"

# Interactive execution tests: Textobject selection
set -l test_to_mode (fish -i --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    commandline -r -- 'echo \"hello world\"'
    commandline -C 7
    __fish_helix_textobject i '\"'
    echo \$fish_bind_mode
" 2>&1 | tail -n 1 | string trim)
assert_equal "$test_to_mode" "visual" "Textobject selection sets visual mode"

# 9. Verify External Editor & Clipboard Selection Replace (Phase 2)
echo
echo "--- Testing External Editor & Clipboard Replace (Phase 2) ---"

# External editor bindings
set -l bind_sp_e_def (bind -M default ' ',e | string trim)
assert_contains "$bind_sp_e_def" "edit_command_buffer" "<space>e in normal mode opens external editor"

set -l bind_sp_e_vis (bind -M visual ' ',e | string trim)
assert_contains "$bind_sp_e_vis" "edit_command_buffer" "<space>e in visual mode opens external editor"

set -l bind_cx_ce_def (bind -M default ctrl-x,ctrl-e | string trim)
assert_contains "$bind_cx_ce_def" "edit_command_buffer" "ctrl-x ctrl-e in normal mode opens external editor"

set -l bind_cx_ce_ins (bind -M insert ctrl-x,ctrl-e | string trim)
assert_contains "$bind_cx_ce_ins" "edit_command_buffer" "ctrl-x ctrl-e in insert mode opens external editor"

# Clipboard replace bindings
set -l bind_sp_R_def (bind -M default ' ',R | string trim)
assert_contains "$bind_sp_R_def" "__fish_helix_replace_with_clipboard" "<space>R in normal mode replaces with clipboard"

set -l bind_sp_R_vis (bind -M visual ' ',R | string trim)
assert_contains "$bind_sp_R_vis" "__fish_helix_replace_with_clipboard" "<space>R in visual mode replaces with clipboard"

# Interactive execution test: Replace with clipboard on selection
set -l test_clip_sel (fish -i --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    commandline -r -- 'git checkout feature_branch'
    function commandline
        if contains -- --selection-start \$argv
            echo 13
            return 0
        else if contains -- --selection-end \$argv
            echo 27
            return 0
        else
            builtin commandline \$argv
        end
    end
    function fish_clipboard_paste; echo -n 'main'; end
    __fish_helix_replace_with_clipboard
    builtin commandline -b
" 2>&1 | tail -n 1 | string trim)
assert_equal "$test_clip_sel" "git checkout main" "Clipboard replace replaces active selection"

# Interactive execution test: Replace with clipboard on char under cursor (no selection)
set -l test_clip_char (fish -i --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    function fish_clipboard_paste; echo -n 'X'; end
    commandline -r -- 'abc'
    commandline -C 1
    __fish_helix_replace_with_clipboard
    commandline -b
" 2>&1 | tail -n 1 | string trim)
assert_equal "$test_clip_char" "aXc" "Clipboard replace replaces char under cursor when no selection"

# 10. Verify Selection Accuracy (Textobjects mi/ma & Word motions w/W/b/B)
echo
echo "--- Testing Selection Accuracy (Textobjects & Word Motions) ---"

set -l test_buf "git commit -m \"test\""
set -l w_end_0 (__fish_helix_find_next_word_end "w" "$test_buf" 0)
assert_equal "$w_end_0" "3" "find_next_word_end w from 0 stops on trailing space before commit"

set -l w_end_4 (__fish_helix_find_next_word_end "w" "$test_buf" 4)
assert_equal "$w_end_4" "10" "find_next_word_end w from 4 stops on trailing space before -m"

set -l w_end_11 (__fish_helix_find_next_word_end "w" "$test_buf" 11)
assert_equal "$w_end_11" "11" "find_next_word_end w from 11 stops on - (hyphen is its own punctuation word)"

set -l w_end_12 (__fish_helix_find_next_word_end "w" "$test_buf" 12)
assert_equal "$w_end_12" "13" "find_next_word_end w from 12 selects m and trailing space"

set -l W_end_11 (__fish_helix_find_next_word_end "W" "$test_buf" 11)
assert_equal "$W_end_11" "13" "find_next_word_end W from 11 considers hyphen part of BIGWORD -m and trailing space"

set -l b_start_3 (__fish_helix_find_prev_word_start "w" "$test_buf" 3)
assert_equal "$b_start_3" "0" "find_prev_word_start w from space 3 lands on git start"

set -l b_start_10 (__fish_helix_find_prev_word_start "w" "$test_buf" 10)
assert_equal "$b_start_10" "4" "find_prev_word_start w from space 10 lands on commit start"

set -l b_start_7 (__fish_helix_find_prev_word_start "w" "$test_buf" 7)
assert_equal "$b_start_7" "4" "find_prev_word_start w from within commit lands on commit start"

# Underscore and equals tests: FOO_BAR=baz
set -l env_buf "FOO_BAR=baz"
set -l env_w_0 (__fish_helix_find_next_word_end "w" "$env_buf" 0)
assert_equal "$env_w_0" "6" "find_next_word_end w considers underscore part of word FOO_BAR"

set -l env_w_7 (__fish_helix_find_next_word_end "w" "$env_buf" 7)
assert_equal "$env_w_7" "7" "find_next_word_end w considers = its own word"

set -l env_w_8 (__fish_helix_find_next_word_end "w" "$env_buf" 8)
assert_equal "$env_w_8" "10" "find_next_word_end w selects baz"

set -l env_W_0 (__fish_helix_find_next_word_end "W" "$env_buf" 0)
assert_equal "$env_W_0" "10" "find_next_word_end W considers = part of BIGWORD FOO_BAR=baz"

# Verify normal mode w does not switch to visual mode
set -l test_w_mode (fish -i --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    commandline -r -- 'git commit -m'
    commandline -C 0
    __fish_helix_normal_w
    echo \$fish_bind_mode
" 2>&1 | tail -n 1 | string trim)
assert_equal "$test_w_mode" "default" "Normal mode w keeps mode as default ([NOR]), not visual ([SEL])"

# Interactive textobject selection: mi" on 'ls -ltra "test"'
set -l test_mi_sel (fish -i --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    commandline -r -- 'ls -ltra \"test\"'
    commandline -C 11
    set -g recorded_C
    set -g recorded_diff 0
    function commandline
        if test (count \$argv) -ge 2; and test \"\$argv[1]\" = \"-C\"
            set -g recorded_C \$argv[2]
            builtin commandline \$argv
        else if contains -- -f \$argv
            for f in \$argv[2..-1]
                if test \"\$f\" = \"forward-char\"
                    set -g recorded_diff (math \$recorded_diff + 1)
                end
            end
            builtin commandline \$argv
        else
            builtin commandline \$argv
        end
    end
    __fish_helix_textobject i '\"'
    set -l sel_end (math \$recorded_C + \$recorded_diff)
    string sub -s (math \$recorded_C + 1) -l (math \$sel_end - \$recorded_C + 1) -- (builtin commandline -b)
" 2>&1 | tail -n 1 | string trim)
assert_equal "$test_mi_sel" "test" "mi\" selects strictly inside quotes without closing delimiter"

# Interactive textobject selection: ma" on 'ls -ltra "test"'
set -l test_ma_sel (fish -i --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    commandline -r -- 'ls -ltra \"test\"'
    commandline -C 11
    set -g recorded_C
    set -g recorded_diff 0
    function commandline
        if test (count \$argv) -ge 2; and test \"\$argv[1]\" = \"-C\"
            set -g recorded_C \$argv[2]
            builtin commandline \$argv
        else if contains -- -f \$argv
            for f in \$argv[2..-1]
                if test \"\$f\" = \"forward-char\"
                    set -g recorded_diff (math \$recorded_diff + 1)
                end
            end
            builtin commandline \$argv
        else
            builtin commandline \$argv
        end
    end
    __fish_helix_textobject a '\"'
    set -l sel_end (math \$recorded_C + \$recorded_diff)
    string sub -s (math \$recorded_C + 1) -l (math \$sel_end - \$recorded_C + 1) -- (builtin commandline -b)
" 2>&1 | tail -n 1 | string trim)
assert_equal "$test_ma_sel" '"test"' "ma\" selects around quotes including delimiters but no trailing char"

# Interactive textobject selection: mi" on empty quotes '""'
set -l test_empty_mode (fish -i --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    commandline -r -- 'ls \"\"'
    commandline -C 4
    __fish_helix_textobject i '\"'
    echo \$fish_bind_mode
" 2>&1 | tail -n 1 | string trim)
assert_equal "$test_empty_mode" "default" "mi\" on empty quotes stays in default mode without invalid selection"

# Interactive word motion: w on 'git commit -m' from 4 ('c')
set -l test_w_raw (fish -i --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    commandline -r -- 'git commit -m'
    commandline -C 4
    set -g recorded_C
    set -g recorded_diff 0
    function commandline
        if test (count \$argv) -ge 2; and test \"\$argv[1]\" = \"-C\"
            set -g recorded_C \$argv[2]
            builtin commandline \$argv
        else if contains -- -f \$argv
            for f in \$argv[2..-1]
                if test \"\$f\" = \"forward-char\"
                    set -g recorded_diff (math \$recorded_diff + 1)
                end
            end
            builtin commandline \$argv
        else
            builtin commandline \$argv
        end
    end
    __fish_helix_normal_w
    set -l sel_end (math \$recorded_C + \$recorded_diff)
    echo \"RESULT:\"(string sub -s (math \$recorded_C + 1) -l (math \$sel_end - \$recorded_C + 1) -- (builtin commandline -b))
" 2>&1)
set -l test_w_match (string match -r '^RESULT:(.*)' -- $test_w_raw)
set -l test_w_sel "$test_w_match[2]"
assert_equal "$test_w_sel" "commit " "w selects word and trailing space without capturing next word"

# Interactive word motion: b on 'git commit -m' from 4 ('c' at word start)
set -l test_b_raw (fish -i --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    commandline -r -- 'git commit -m'
    commandline -C 4
    set -g recorded_C
    set -g recorded_diff 0
    function commandline
        if test (count \$argv) -ge 2; and test \"\$argv[1]\" = \"-C\"
            set -g recorded_C \$argv[2]
            builtin commandline \$argv
        else if contains -- -f \$argv
            for f in \$argv[2..-1]
                if test \"\$f\" = \"backward-char\"
                    set -g recorded_diff (math \$recorded_diff + 1)
                end
            end
            builtin commandline \$argv
        else
            builtin commandline \$argv
        end
    end
    __fish_helix_normal_b
    set -l sel_start (math \$recorded_C - \$recorded_diff)
    echo \"RESULT:\"(string sub -s (math \$sel_start + 1) -l (math \$recorded_C - \$sel_start + 1) -- (builtin commandline -b))
" 2>&1)
set -l test_b_match (string match -r '^RESULT:(.*)' -- $test_b_raw)
set -l test_b_start_sel "$test_b_match[2]"
assert_equal "$test_b_start_sel" "git " "b from word start excludes current word first character"

# Interactive word motion: b on 'git commit -m' from 7 ('m' within word)
set -l test_b_mid_raw (fish -i --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    commandline -r -- 'git commit -m'
    commandline -C 7
    set -g recorded_C
    set -g recorded_diff 0
    function commandline
        if test (count \$argv) -ge 2; and test \"\$argv[1]\" = \"-C\"
            set -g recorded_C \$argv[2]
            builtin commandline \$argv
        else if contains -- -f \$argv
            for f in \$argv[2..-1]
                if test \"\$f\" = \"backward-char\"
                    set -g recorded_diff (math \$recorded_diff + 1)
                end
            end
            builtin commandline \$argv
        else
            builtin commandline \$argv
        end
    end
    __fish_helix_normal_b
    set -l sel_start (math \$recorded_C - \$recorded_diff)
    echo \"RESULT:\"(string sub -s (math \$sel_start + 1) -l (math \$recorded_C - \$sel_start + 1) -- (builtin commandline -b))
" 2>&1)
set -l test_b_mid_match (string match -r '^RESULT:(.*)' -- $test_b_mid_raw)
set -l test_b_mid_sel "$test_b_mid_match[2]"
assert_equal "$test_b_mid_sel" "comm" "b from within word selects back to current word start"

# Interactive consecutive normal mode w on 'ls -ltra "test"'
set -l test_consec_w_raw (fish -i --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    commandline -r -- 'ls -ltra \"test\"'
    commandline -C 0

    set -g cur_pos 0
    set -g sel_start -1
    set -g sel_end -1
    set -g in_sel 0

    function commandline
        if test (count \$argv) -ge 2; and test \"\$argv[1]\" = \"-C\"
            set -g cur_pos \$argv[2]
            if test \$in_sel -eq 0
                set -g sel_start \$cur_pos
                set -g sel_end \$cur_pos
            end
        else if contains -- -f \$argv
            for f in \$argv[2..-1]
                if test \"\$f\" = \"begin-selection\"
                    set -g in_sel 1
                    set -g sel_start \$cur_pos
                    set -g sel_end \$cur_pos
                else if test \"\$f\" = \"end-selection\"
                    set -g in_sel 0
                    set -g sel_start -1
                    set -g sel_end -1
                else if test \"\$f\" = \"forward-char\"
                    set -g cur_pos (math \$cur_pos + 1)
                    if test \$in_sel -eq 1
                        set -g sel_end \$cur_pos
                    end
                end
            end
        else if contains -- -C \$argv
            echo \$cur_pos
        else if contains -- -b \$argv
            echo 'ls -ltra \"test\"'
        else if contains -- -s \$argv
            if test \$in_sel -eq 1
                set -l min_p (math \"min(\$sel_start, \$cur_pos)\")
                set -l max_p (math \"max(\$sel_start, \$cur_pos)\")
                string sub -s (math \$min_p + 1) -l (math \$max_p - \$min_p + 1) -- 'ls -ltra \"test\"'
            end
        else if contains -- --selection-start \$argv
            if test \$in_sel -eq 1
                math \"min(\$sel_start, \$cur_pos)\"
                return 0
            end
            return 1
        else if contains -- --selection-end \$argv
            if test \$in_sel -eq 1
                math \"max(\$sel_start, \$cur_pos) + 1\"
                return 0
            end
            return 1
        end
    end

    __fish_helix_normal_w
    set -l sel1 (commandline -s)
    set -l mode1 \$fish_bind_mode

    __fish_helix_normal_w
    set -l sel2 (commandline -s)
    set -l mode2 \$fish_bind_mode

    __fish_helix_normal_w
    set -l sel3 (commandline -s)
    set -l mode3 \$fish_bind_mode

    __fish_helix_normal_w
    set -l sel4 (commandline -s)

    __fish_helix_normal_w
    set -l sel5 (commandline -s)

    __fish_helix_normal_w
    set -l sel6 (commandline -s)

    echo \"P1:\$sel1|M1:\$mode1|P2:\$sel2|M2:\$mode2|P3:\$sel3|M3:\$mode3|P4:\$sel4|P5:\$sel5|P6:\$sel6\"
" 2>&1)
set -l match_consec (string match -r 'P1:(.*)\|M1:(.*)\|P2:(.*)\|M2:(.*)\|P3:(.*)\|M3:(.*)\|P4:(.*)\|P5:(.*)\|P6:(.*)' -- $test_consec_w_raw)
assert_equal "$match_consec[2]" "ls " "Consecutive w press 1 selects 'ls '"
assert_equal "$match_consec[3]" "default" "Consecutive w press 1 keeps default mode"
assert_equal "$match_consec[4]" "-" "Consecutive w press 2 selects '-' as its own word"
assert_equal "$match_consec[5]" "default" "Consecutive w press 2 keeps default mode"
assert_equal "$match_consec[6]" "ltra " "Consecutive w press 3 selects 'ltra '"
assert_equal "$match_consec[7]" "default" "Consecutive w press 3 keeps default mode"
assert_equal "$match_consec[8]" '"' "Consecutive w press 4 selects '\"' as its own word"
assert_equal "$match_consec[9]" "test" "Consecutive w press 5 selects 'test'"
assert_equal "$match_consec[10]" '"' "Consecutive w press 6 selects '\"'"

# Interactive consecutive normal mode w on 'git commit -m "test"'
set -l test_consec_w_git_raw (fish -i --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    commandline -r -- 'git commit -m \"test\"'
    commandline -C 0

    set -g cur_pos 0
    set -g sel_start -1
    set -g sel_end -1
    set -g in_sel 0

    function commandline
        if test (count \$argv) -ge 2; and test \"\$argv[1]\" = \"-C\"
            set -g cur_pos \$argv[2]
            if test \$in_sel -eq 0
                set -g sel_start \$cur_pos
                set -g sel_end \$cur_pos
            end
        else if contains -- -f \$argv
            for f in \$argv[2..-1]
                if test \"\$f\" = \"begin-selection\"
                    set -g in_sel 1
                    set -g sel_start \$cur_pos
                    set -g sel_end \$cur_pos
                else if test \"\$f\" = \"end-selection\"
                    set -g in_sel 0
                    set -g sel_start -1
                    set -g sel_end -1
                else if test \"\$f\" = \"forward-char\"
                    set -g cur_pos (math \$cur_pos + 1)
                    if test \$in_sel -eq 1
                        set -g sel_end \$cur_pos
                    end
                end
            end
        else if contains -- -C \$argv
            echo \$cur_pos
        else if contains -- -b \$argv
            echo 'git commit -m \"test\"'
        else if contains -- -s \$argv
            if test \$in_sel -eq 1
                set -l min_p (math \"min(\$sel_start, \$cur_pos)\")
                set -l max_p (math \"max(\$sel_start, \$cur_pos)\")
                string sub -s (math \$min_p + 1) -l (math \$max_p - \$min_p + 1) -- 'git commit -m \"test\"'
            end
        else if contains -- --selection-start \$argv
            if test \$in_sel -eq 1
                math \"min(\$sel_start, \$cur_pos)\"
                return 0
            end
            return 1
        else if contains -- --selection-end \$argv
            if test \$in_sel -eq 1
                math \"max(\$sel_start, \$cur_pos) + 1\"
                return 0
            end
            return 1
        end
    end

    __fish_helix_normal_w
    set -l sel1 (commandline -s)

    __fish_helix_normal_w
    set -l sel2 (commandline -s)

    __fish_helix_normal_w
    set -l sel3 (commandline -s)

    __fish_helix_normal_w
    set -l sel4 (commandline -s)

    __fish_helix_normal_w
    set -l sel5 (commandline -s)

    __fish_helix_normal_w
    set -l sel6 (commandline -s)

    __fish_helix_normal_w
    set -l sel7 (commandline -s)

    echo \"P1:\$sel1|P2:\$sel2|P3:\$sel3|P4:\$sel4|P5:\$sel5|P6:\$sel6|P7:\$sel7\"
" 2>&1)
set -l match_consec_git (string match -r 'P1:(.*)\|P2:(.*)\|P3:(.*)\|P4:(.*)\|P5:(.*)\|P6:(.*)\|P7:(.*)' -- $test_consec_w_git_raw)
assert_equal "$match_consec_git[2]" "git " "git consecutive w press 1 selects 'git '"
assert_equal "$match_consec_git[3]" "commit " "git consecutive w press 2 selects 'commit '"
assert_equal "$match_consec_git[4]" "-" "git consecutive w press 3 selects '-' as its own word"
assert_equal "$match_consec_git[5]" "m " "git consecutive w press 4 selects 'm '"
assert_equal "$match_consec_git[6]" '"' "git consecutive w press 5 selects '\"'"
assert_equal "$match_consec_git[7]" "test" "git consecutive w press 6 selects 'test'"
assert_equal "$match_consec_git[8]" '"' "git consecutive w press 7 selects closing '\"'"

# Interactive consecutive normal mode W (BIGWORD) on 'ls -ltra "test"'
set -l test_consec_W_raw (fish -i --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    commandline -r -- 'ls -ltra \"test\"'
    commandline -C 0

    set -g cur_pos 0
    set -g sel_start -1
    set -g sel_end -1
    set -g in_sel 0

    function commandline
        if test (count \$argv) -ge 2; and test \"\$argv[1]\" = \"-C\"
            set -g cur_pos \$argv[2]
            if test \$in_sel -eq 0
                set -g sel_start \$cur_pos
                set -g sel_end \$cur_pos
            end
        else if contains -- -f \$argv
            for f in \$argv[2..-1]
                if test \"\$f\" = \"begin-selection\"
                    set -g in_sel 1
                    set -g sel_start \$cur_pos
                    set -g sel_end \$cur_pos
                else if test \"\$f\" = \"end-selection\"
                    set -g in_sel 0
                    set -g sel_start -1
                    set -g sel_end -1
                else if test \"\$f\" = \"forward-char\"
                    set -g cur_pos (math \$cur_pos + 1)
                    if test \$in_sel -eq 1
                        set -g sel_end \$cur_pos
                    end
                end
            end
        else if contains -- -C \$argv
            echo \$cur_pos
        else if contains -- -b \$argv
            echo 'ls -ltra \"test\"'
        else if contains -- -s \$argv
            if test \$in_sel -eq 1
                set -l min_p (math \"min(\$sel_start, \$cur_pos)\")
                set -l max_p (math \"max(\$sel_start, \$cur_pos)\")
                string sub -s (math \$min_p + 1) -l (math \$max_p - \$min_p + 1) -- 'ls -ltra \"test\"'
            end
        else if contains -- --selection-start \$argv
            if test \$in_sel -eq 1
                math \"min(\$sel_start, \$cur_pos)\"
                return 0
            end
            return 1
        else if contains -- --selection-end \$argv
            if test \$in_sel -eq 1
                math \"max(\$sel_start, \$cur_pos) + 1\"
                return 0
            end
            return 1
        end
    end

    __fish_helix_normal_W
    set -l sel1 (commandline -s)

    __fish_helix_normal_W
    set -l sel2 (commandline -s)

    __fish_helix_normal_W
    set -l sel3 (commandline -s)

    echo \"W1:\$sel1|W2:\$sel2|W3:\$sel3\"
" 2>&1)
set -l match_consec_W (string match -r 'W1:(.*)\|W2:(.*)\|W3:(.*)' -- $test_consec_W_raw)
assert_equal "$match_consec_W[2]" "ls " "Consecutive W press 1 selects 'ls '"
assert_equal "$match_consec_W[3]" "-ltra " "Consecutive W press 2 considers hyphen part of BIGWORD '-ltra '"
assert_equal "$match_consec_W[4]" '"test"' "Consecutive W press 3 considers quotes part of BIGWORD '\"test\"'"

# Interactive normal mode w on 'FOO_BAR=baz'
set -l test_env_w_raw (fish -i --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    commandline -r -- 'FOO_BAR=baz'
    commandline -C 0

    set -g cur_pos 0
    set -g sel_start -1
    set -g sel_end -1
    set -g in_sel 0

    function commandline
        if test (count \$argv) -ge 2; and test \"\$argv[1]\" = \"-C\"
            set -g cur_pos \$argv[2]
            if test \$in_sel -eq 0
                set -g sel_start \$cur_pos
                set -g sel_end \$cur_pos
            end
        else if contains -- -f \$argv
            for f in \$argv[2..-1]
                if test \"\$f\" = \"begin-selection\"
                    set -g in_sel 1
                    set -g sel_start \$cur_pos
                    set -g sel_end \$cur_pos
                else if test \"\$f\" = \"end-selection\"
                    set -g in_sel 0
                    set -g sel_start -1
                    set -g sel_end -1
                else if test \"\$f\" = \"forward-char\"
                    set -g cur_pos (math \$cur_pos + 1)
                    if test \$in_sel -eq 1
                        set -g sel_end \$cur_pos
                    end
                end
            end
        else if contains -- -C \$argv
            echo \$cur_pos
        else if contains -- -b \$argv
            echo 'FOO_BAR=baz'
        else if contains -- -s \$argv
            if test \$in_sel -eq 1
                set -l min_p (math \"min(\$sel_start, \$cur_pos)\")
                set -l max_p (math \"max(\$sel_start, \$cur_pos)\")
                string sub -s (math \$min_p + 1) -l (math \$max_p - \$min_p + 1) -- 'FOO_BAR=baz'
            end
        else if contains -- --selection-start \$argv
            if test \$in_sel -eq 1
                math \"min(\$sel_start, \$cur_pos)\"
                return 0
            end
            return 1
        else if contains -- --selection-end \$argv
            if test \$in_sel -eq 1
                math \"max(\$sel_start, \$cur_pos) + 1\"
                return 0
            end
            return 1
        end
    end

    __fish_helix_normal_w
    set -l sel1 (commandline -s)

    __fish_helix_normal_w
    set -l sel2 (commandline -s)

    __fish_helix_normal_w
    set -l sel3 (commandline -s)

    echo \"E1:\$sel1|E2:\$sel2|E3:\$sel3\"
" 2>&1)
set -l match_env_w (string match -r 'E1:(.*)\|E2:(.*)\|E3:(.*)' -- $test_env_w_raw)
assert_equal "$match_env_w[2]" "FOO_BAR" "w considers underscore part of word 'FOO_BAR'"
assert_equal "$match_env_w[3]" "=" "w considers '=' its own word"
assert_equal "$match_env_w[4]" "baz" "w selects 'baz'"

# Interactive visual mode w extends selection
set -l test_vis_w_raw (fish -i --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    commandline -r -- 'ls -ltra \"test\"'
    commandline -C 0

    set -g cur_pos 0
    set -g sel_start -1
    set -g sel_end -1
    set -g in_sel 0

    function commandline
        if test (count \$argv) -ge 2; and test \"\$argv[1]\" = \"-C\"
            set -g cur_pos \$argv[2]
            if test \$in_sel -eq 0
                set -g sel_start \$cur_pos
                set -g sel_end \$cur_pos
            end
        else if contains -- -f \$argv
            for f in \$argv[2..-1]
                if test \"\$f\" = \"begin-selection\"
                    set -g in_sel 1
                    set -g sel_start \$cur_pos
                    set -g sel_end \$cur_pos
                else if test \"\$f\" = \"end-selection\"
                    set -g in_sel 0
                    set -g sel_start -1
                    set -g sel_end -1
                else if test \"\$f\" = \"forward-char\"
                    set -g cur_pos (math \$cur_pos + 1)
                    if test \$in_sel -eq 1
                        set -g sel_end \$cur_pos
                    end
                end
            end
        else if contains -- -C \$argv
            echo \$cur_pos
        else if contains -- -b \$argv
            echo 'ls -ltra \"test\"'
        end
    end

    set fish_bind_mode visual
    commandline -f begin-selection
    __fish_helix_visual_w
    set -l sel1 (string sub -s (math \$sel_start + 1) -l (math \$sel_end - \$sel_start + 1) -- 'ls -ltra \"test\"')
    set -l mode1 \$fish_bind_mode

    __fish_helix_visual_w
    set -l sel2 (string sub -s (math \$sel_start + 1) -l (math \$sel_end - \$sel_start + 1) -- 'ls -ltra \"test\"')
    set -l mode2 \$fish_bind_mode

    __fish_helix_visual_w
    set -l sel3 (string sub -s (math \$sel_start + 1) -l (math \$sel_end - \$sel_start + 1) -- 'ls -ltra \"test\"')

    echo \"V1:\$sel1|M1:\$mode1|V2:\$sel2|M2:\$mode2|V3:\$sel3\"
" 2>&1)
set -l match_vis (string match -r 'V1:(.*)\|M1:(.*)\|V2:(.*)\|M2:(.*)\|V3:(.*)' -- $test_vis_w_raw)
assert_equal "$match_vis[2]" "ls " "Visual mode w press 1 selects 'ls '"
assert_equal "$match_vis[3]" "visual" "Visual mode w press 1 maintains visual mode"
assert_equal "$match_vis[4]" "ls -" "Visual mode w press 2 extends selection across hyphen 'ls -'"
assert_equal "$match_vis[5]" "visual" "Visual mode w press 2 maintains visual mode"
assert_equal "$match_vis[6]" "ls -ltra " "Visual mode w press 3 extends selection across 'ls -ltra '"

# ==============================================================================
# Phase 3 Tests: Selection Manipulation (_, J, Alt+J, Alt+:, r)
# ==============================================================================
echo "--- Testing Phase 3: Selection Manipulation & Replace ---"

# 1. Keybindings check
set -l bind_trim_def (bind -M default _ | string trim)
assert_contains "$bind_trim_def" "__fish_helix_trim_selection" "_ in default mode trims selection"

set -l bind_trim_vis (bind -M visual _ | string trim)
assert_contains "$bind_trim_vis" "__fish_helix_trim_selection" "_ in visual mode trims selection"

set -l bind_join_def (bind -M default J | string trim)
assert_contains "$bind_join_def" "__fish_helix_join_lines with_space" "J in default mode joins lines with space"

set -l bind_join_nosp_def (bind -M default \eJ | string trim)
assert_contains "$bind_join_nosp_def" "__fish_helix_join_lines no_space" "Alt+J in default mode joins lines without space"

set -l bind_join_vis (bind -M visual J | string trim)
assert_contains "$bind_join_vis" "__fish_helix_join_lines with_space" "J in visual mode joins lines with space"

set -l bind_join_nosp_vis (bind -M visual \eJ | string trim)
assert_contains "$bind_join_nosp_vis" "__fish_helix_join_lines no_space" "Alt+J in visual mode joins lines without space"

set -l bind_fwd_def (bind -M default \e: | string trim)
assert_contains "$bind_fwd_def" "__fish_helix_ensure_forward_selection" "Alt+: in default mode ensures forward selection"

set -l bind_fwd_vis (bind -M visual \e: | string trim)
assert_contains "$bind_fwd_vis" "__fish_helix_ensure_forward_selection" "Alt+: in visual mode ensures forward selection"

set -l bind_rep_def (bind -M default r | string trim)
assert_contains "$bind_rep_def" "__fish_helix_prepare_replace" "r in default mode prepares character replace"

set -l bind_rep_vis (bind -M visual r | string trim)
assert_contains "$bind_rep_vis" "__fish_helix_prepare_replace" "r in visual mode prepares character replace"

set -l bind_rep_mode_a (bind -M replace_one a | string trim)
assert_contains "$bind_rep_mode_a" "__fish_helix_execute_replace" "a in replace_one mode executes replace"

set -l bind_rep_compat_a (bind -M helix_replace_one a | string trim)
assert_contains "$bind_rep_compat_a" "__fish_helix_execute_replace" "a in helix_replace_one mode executes replace"

set -l test_prep_mode (fish -i --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    commandline -r -- 'cat'
    commandline -C 1
    __fish_helix_prepare_replace
    echo \$fish_bind_mode
" 2>&1 | tail -n 1 | string trim)
assert_equal "$test_prep_mode" "replace_one" "__fish_helix_prepare_replace sets fish_bind_mode to replace_one"

# 2. Interactive execution: _ (Trim selection)
set -l test_trim_raw (fish -i --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    commandline -r -- 'ls -ltra'
    commandline -C 0

    set -g cur_pos 2
    set -g sel_start 0
    set -g in_sel 1

    function commandline
        if test (count \$argv) -ge 2; and test \"\$argv[1]\" = \"-C\"
            set -g cur_pos \$argv[2]
            if test \$in_sel -eq 0
                set -g sel_start \$cur_pos
            end
        else if contains -- -f \$argv
            for f in \$argv[2..-1]
                if test \"\$f\" = \"begin-selection\"
                    set -g in_sel 1
                    set -g sel_start \$cur_pos
                else if test \"\$f\" = \"end-selection\"
                    set -g in_sel 0
                    set -g sel_start -1
                else if test \"\$f\" = \"forward-char\"
                    set -g cur_pos (math \$cur_pos + 1)
                end
            end
        else if contains -- -C \$argv
            echo \$cur_pos
        else if contains -- -b \$argv
            echo 'ls -ltra'
        else if contains -- -s \$argv
            if test \$in_sel -eq 1
                set -l min_p (math \"min(\$sel_start, \$cur_pos)\")
                set -l max_p (math \"max(\$sel_start, \$cur_pos)\")
                string sub -s (math \$min_p + 1) -l (math \$max_p - \$min_p + 1) -- 'ls -ltra'
            end
        else if contains -- --selection-start \$argv
            if test \$in_sel -eq 1
                math \"min(\$sel_start, \$cur_pos)\"
                return 0
            end
            return 1
        else if contains -- --selection-end \$argv
            if test \$in_sel -eq 1
                math \"max(\$sel_start, \$cur_pos) + 1\"
                return 0
            end
            return 1
        end
    end

    __fish_helix_trim_selection
    echo (commandline -s)
" 2>&1 | tail -n 1 | string trim)
assert_equal "$test_trim_raw" "ls" "_ trims trailing whitespace from selection 'ls '"

# 3. Interactive execution: J (Join lines with space) and Alt+J (without space)
set -l test_join_space (fish -i --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    commandline -r (printf '%s\n%s' 'echo hello' '    world')
    commandline -C 0
    __fish_helix_join_lines with_space
    builtin commandline -b
" 2>&1 | tail -n 1 | string trim)
assert_equal "$test_join_space" "echo hello world" "J joins multiline command with space"

set -l test_join_nospace (fish -i --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    commandline -r (printf '%s\n%s' 'git commit \\\\' '    -m test')
    commandline -C 0
    __fish_helix_join_lines no_space
    builtin commandline -b
" 2>&1 | tail -n 1 | string trim)
assert_equal "$test_join_nospace" "git commit \-m test" "Alt+J joins lines without extra space"

# Interactive execution: J on multiline selection
set -l test_join_multisel (fish -i --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    commandline -r (printf '%s\n%s\n%s' 'prefix' '  line2' 'suffix')
    function commandline
        if contains -- --selection-start \$argv
            echo 0
            return 0
        else if contains -- --selection-end \$argv
            echo 14
            return 0
        else if contains -- -s \$argv
            printf '%s\n%s\n' 'prefix' '  line2'
            return 0
        else
            builtin commandline \$argv
        end
    end
    __fish_helix_join_lines with_space
    echo (string join ';' -- (builtin commandline -b))
" 2>&1 | tail -n 1 | string trim)
assert_equal "$test_join_multisel" "prefix line2;suffix" "J joins multiline active selection with space"

# 4. Interactive execution: Alt+: (Ensure forward selection)
set -l test_fwd_sel (fish -i --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    set -g swapped 0
    function commandline
        if contains -- --selection-start \$argv
            echo 5
            return 0
        else if contains -- --selection-end \$argv
            echo 10
            return 0
        else if contains -- -C \$argv
            echo 5
            return 0
        else if contains -- -f \$argv; and contains -- swap-selection-start-stop \$argv
            set -g swapped 1
            return 0
        else
            builtin commandline \$argv
        end
    end
    __fish_helix_ensure_forward_selection
    echo \$swapped
" 2>&1 | tail -n 1 | string trim)
assert_equal "$test_fwd_sel" "1" "Alt+: swaps selection start/stop when backward"

# 5. Interactive execution: r single char replace and multi-char selection replace
set -l test_rep_single (fish -i --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    commandline -r -- 'cat'
    commandline -C 1
    __fish_helix_prepare_replace
    __fish_helix_execute_replace 'o'
    builtin commandline -b
" 2>&1 | tail -n 1 | string trim)
assert_equal "$test_rep_single" "cot" "r replaces single char under cursor ('cat' -> 'cot')"

set -l test_rep_multi (fish -i --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    commandline -r -- 'foo bar'
    function commandline
        if contains -- --selection-start \$argv
            echo 0
            return 0
        else if contains -- --selection-end \$argv
            echo 3
            return 0
        else if contains -- -s \$argv
            echo 'foo'
        else
            builtin commandline \$argv
        end
    end
    __fish_helix_prepare_replace
    __fish_helix_execute_replace '-'
    builtin commandline -b
" 2>&1 | tail -n 1 | string trim)
assert_equal "$test_rep_multi" "--- bar" "r replaces every character of active selection ('foo' -> '---')"

# 12. Verify Discovery, Navigation & Housekeeping (Phase 4)
echo
echo "--- Testing Discovery & Navigation (Phase 4) ---"

# gm (jump to matching bracket alias) bindings
set -l bind_gm_def (bind -M default g,m | string trim)
assert_contains "$bind_gm_def" "jump-to-matching-bracket" "gm in default mode jumps to matching bracket"

set -l bind_gm_vis (bind -M visual g,m | string trim)
assert_contains "$bind_gm_vis" "jump-to-matching-bracket" "gm in visual mode jumps to matching bracket"

# <space>? and <space>h cheatsheet bindings
set -l bind_sp_q_def (bind -M default ' ',? | string trim)
assert_contains "$bind_sp_q_def" "__fish_helix_cheatsheet" "<space>? in default mode opens cheatsheet"

set -l bind_sp_h_def (bind -M default ' ',h | string trim)
assert_contains "$bind_sp_h_def" "__fish_helix_cheatsheet" "<space>h in default mode opens cheatsheet"

set -l bind_sp_q_vis (bind -M visual ' ',? | string trim)
assert_contains "$bind_sp_q_vis" "__fish_helix_cheatsheet" "<space>? in visual mode opens cheatsheet"

set -l bind_sp_h_vis (bind -M visual ' ',h | string trim)
assert_contains "$bind_sp_h_vis" "__fish_helix_cheatsheet" "<space>h in visual mode opens cheatsheet"

# Interactive execution: __fish_helix_cheatsheet output
set -l test_cs_raw (fish -i --no-config -c "
    source $plugin_dir/functions/fish_helix_key_bindings.fish
    __fish_helix_cheatsheet
" 2>&1)
assert_contains "$test_cs_raw" "Helix Keybindings Cheatsheet" "Cheatsheet contains header title"
assert_contains "$test_cs_raw" "MOTIONS / SELECTIONS" "Cheatsheet contains motions section"
assert_contains "$test_cs_raw" "MATCH & SURROUND" "Cheatsheet contains match and surround section"
assert_contains "$test_cs_raw" "EDITING & CLIPBOARD" "Cheatsheet contains editing and clipboard section"


echo
echo "================================================="
echo "Results: $passed Passed, $failed Failed"
echo "================================================="

if test $failed -gt 0
    exit 1
else
    exit 0
end
