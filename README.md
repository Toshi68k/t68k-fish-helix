# Helix Keybindings for Fish Shell

[![Fish Shell](https://img.shields.io/badge/Fish%20Shell-3.4+%20%7C%204.0+-4B6584.svg?logo=fishshell&logoColor=white)](https://fishshell.com)
[![Modal](https://img.shields.io/badge/Modal-Helix-03C7D3.svg)](https://helix-editor.com)
[![Prompt Integration](https://img.shields.io/badge/Prompt-Tide%20%7C%20Starship%20%7C%20Native-00D2D3.svg)](#-visual-indicators--prompt-integration)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A modal command-line editing plugin for the **[Fish shell](https://fishshell.com)** implementing the **[Helix editor](https://helix-editor.com)**'s **selection-first paradigm** (`noun → verb`), complete with selection-oriented word motions, line extensions, jump motions, surround handling, and dynamic cursor styling.

The goal of this plugin is to provide a complete and authentic Helix editing experience on the terminal command line, without falling back to [Vim](https://www.vim.org) habits or operator-pending compromises.

- **Plugin**: `t68k-fish-helix`
- **Author**: [Thorsten Titze](https://github.com/Toshi68k)
- **Target Shell**: Fish Shell 3.4+ / 4.0+ (Rust core supported)
- **Supported Frameworks**: [Fisher](https://github.com/jorgebucaran/fisher), [Oh My Fish](https://github.com/oh-my-fish/oh-my-fish), manual sourcing

---

## ⚡ Key Features

- **Selection-First Paradigm**: In Helix, motions first create active selections, and actions operate directly on those selections (`wd` deletes word, `wc` changes word, `wy` yanks word).
- **Zero Vim Compromises**:
  - `x` selects lines and extends downward on repeat (unlike Vim where `x` deletes a character).
  - `%` selects the entire command-line buffer (unlike Vim where `%` matches brackets).
  - `u` is undo, `U` is redo (unlike Vim where redo is `Ctrl+r`).
  - `;` collapses any active selection back to a single cursor.
  - `Alt+;` flips the selection direction (head ↔ anchor).
- **Full Range of Jump Motions**:
  - `t<char>` / `f<char>` jump till / to `<char>` forward.
  - `v-t-<char>` / `v-f-<char>` extend selections to specific characters in Select mode.
  - `t<Enter>` / `f<Enter>` jump directly to the end of the line (in Normal and Select mode).
  - `T<Enter>` / `F<Enter>` jump directly to the start of the line.
- **Surround & Match Mode (`m`)**:
  - `mm` jumps to the matching bracket or quote.
  - `ms<char>` surrounds active selections (or words under the cursor) with matched pairs (`"`, `'`, `()`, `[]`, `{}`, `<>`).
  - `mr<old><new>` replaces surrounding delimiter (e.g. `mr"'` or `mrb[`).
  - `md<char>` deletes surrounding delimiter (e.g. `md"` or `md(`).
  - `mi<char>` / `ma<char>` selects inside / around textobjects (`"`, `'`, `` ` ``, `()`, `[]`, `{}`, `<>`, `w`, `W`).
- **Goto Navigation (`g`)**:
  - `gh` (line start), `gl` (line end), `gs` (first non-whitespace), `gg` (buffer start), `ge` (buffer end).
- **Terminal Visual Indicators & Cursor Morphing**:
  - **Normal** (`NOR`): Block cursor (`█`).
  - **Insert** (`INS`): Beam cursor (`|`), full readline deletion shortcuts (`Backspace`, `Ctrl+w`, `Ctrl+u`, `Ctrl+k`).
  - **Select** (`SEL`): Underline cursor (`_`), motions extend selections.
  - **Replace** (`REP`): Single-character replace (`r<char>`).
- **Modern Multi-Line Prompt Compatibility**:
  - Auto-detects multi-line prompts like **[Tide](https://github.com/IlanCosman/tide)**, **[Starship](https://starship.rs)**, and **Hydro** to prevent prompt disruption.
  - Native integration with Tide's `vi_mode` item.

---

## ⌨️ Helix Keymap Reference

### 1. Motions (Create & Replace Selections in Normal Mode)

In Helix Normal mode, movements **select/replace** the range. Pressing `d` deletes the selection, `c` changes it, and moving again replaces the selection.

| Key | Description |
|---|---|
| `w` | Select to the start of the next word (`wd` deletes word, `wc` changes word, `wy` yanks word) |
| `b` | Select backward to the start of the previous word (`bd`, `bc`, `by`) |
| `e` | Select to the end of the current/next word (`ed`, `ec`, `ey`) |
| `W` | Select to the start of the next WORD (whitespace-delimited) |
| `B` | Select backward to the start of the previous WORD |
| `E` | Select to the end of the current/next WORD |
| `f<char>` | Move to next occurrence of `<char>` (inclusive; selects range) |
| `t<char>` | Move till next occurrence of `<char>` (stops before `<char>`; selects range) |
| `F<char>` | Move to previous occurrence of `<char>` (backward, inclusive) |
| `T<char>` | Move till previous occurrence of `<char>` (backward, stops after `<char>`) |
| `f<Enter>` / `t<Enter>` | Select from cursor forward to the end of the line |
| `F<Enter>` / `T<Enter>` | Select from cursor backward to the start of the line |
| `Alt+.` | Repeat last jump motion (`repeat-jump`) |
| `Alt+,` | Repeat last jump motion in reverse (`repeat-jump-reverse`) |
| `h` / `l` | Collapse active selection and move left / right 1 character |
| `j` / `k` | History search down / up (or multi-line navigation) |
| `/` / `?` | Search command history interactively (`history-pager`) |
| `n` / `N` | Cycle backward / forward through matching history commands (`search_next`/`prev`) |
| `x` | Select current line (including newline); pressing `x` again extends to the next line (`extend_line_below`) |
| `X` | Extend selection to whole line bounds (`extend_to_line_bounds`) |
| `%` | Select entire command line buffer |
| `1`–`9`, `0` | Numeric count prefixes for repeat motions (e.g. `3w`, `2x`, `5h`) |

---

### 2. Select / Extend Mode (`v` or `visual`)

Entered with `v`, `x`, or `%`. In this mode, movements **extend** the selection from the anchor:

| Key | Action | Description |
|---|---|---|
| `w` / `b` / `e` | `extend_word_*` | Extend selection forward/backward by word |
| `W` / `B` / `E` | `extend_bigword_*` | Extend selection forward/backward by WORD |
| `h` / `j` / `k` / `l` | `extend_char_*` | Extend selection left / down / up / right |
| `t<char>` / `f<char>` | `extend_till/find` | Extend selection forward till / to `<char>` |
| `t<Enter>` / `f<Enter>` | `extend_to_eol` | **Extend selection all the way to the end of the line** |
| `T<char>` / `F<char>` | `extend_till/find_back` | Extend selection backward till / to `<char>` |
| `T<Enter>` / `F<Enter>` | `extend_to_bol` | Extend selection backward to the start of the line |
| `gh` / `gl` | `extend_line_bounds` | Extend selection to start / end of line |
| `gg` / `ge` | `extend_buffer_bounds` | Extend selection to top / end of buffer |
| `mm` | `extend_match_bracket`| Extend selection to matching bracket |
| `x` | `extend_line_below` | Extend selection down by one full line |
| `X` | `extend_to_line_bounds`| Extend selection to line boundaries |
| `;` | `collapse_selection` | Collapse selection and return to `Normal` mode |
| `Alt+;` | `flip_selections` | Swap selection anchor and cursor head |
| `v` / `Escape` | `exit_select_mode` | Exit Select mode and return to `Normal` mode |

---

### 3. Actions on Selection

Actions execute immediately on whatever is currently selected:

| Key | Description |
|---|---|
| `d` | Delete active selection (or single char under cursor) and copy to kill-ring |
| `Alt+d` | Delete active selection without touching the kill-ring (`delete_selection_noyank`) |
| `c` | Delete active selection and switch to `Insert` mode |
| `Alt+c` | Delete active selection without touching kill-ring and switch to `Insert` mode |
| `y` | Yank (copy) active selection to kill-ring |
| `p` | Paste kill-ring after cursor / selection |
| `P` | Paste kill-ring before cursor / selection |
| `R` | Replace active selection (or char under cursor) with kill-ring contents without clobbering kill-ring |
| `r<char>` | Replace selected character(s) with `<char>` and stay in `Normal` mode |
| `~` | Toggle case of selection / character |
| `` ` `` | Switch selection to lowercase (`downcase-selection`) |
| `Alt+` `` ` `` | Switch selection to uppercase (`upcase-selection`) |
| `>` / `<` | Indent / Unindent line or selection by 4 spaces |
| `u` | Undo (`undo`) |
| `U` | Redo (`redo`) |
| `#` | Toggle comment on current command line |

---

### 4. Insert Mode & Readline Shortcuts

| Key | Action | Description |
|---|---|---|
| `Escape` / `Ctrl+[` | `normal_mode` | Return to `Normal` mode (block cursor) |
| `Backspace` / `Ctrl+h` | `delete_char_backward` | Delete character backward |
| `Shift+Backspace` | `delete_char_backward` | Delete character backward |
| `Delete` | `delete_char_forward` | Delete character forward |
| `Ctrl+d` | `delete_or_exit` | Delete forward or exit shell on empty line |
| `Ctrl+w` / `Alt+Backspace`| `delete_word_backward` | Delete previous word backward (`backward-kill-word`) |
| `Ctrl+u` | `kill_to_line_start` | Delete from cursor to beginning of line |
| `Ctrl+k` | `kill_to_line_end` | Delete from cursor to end of line |
| `Ctrl+x Ctrl+e` | `edit_command_buffer` | Open command buffer in external editor (`$EDITOR` / `hx`) |
| `Tab` | `complete` | Trigger completion / autosuggestion |
| `Enter` | `execute` | Execute command line |

---

### 5. Goto Sub-Mode (`g`)

| Key | Description |
|---|---|
| `gh` | Move to line start (`beginning-of-line`) |
| `gl` | Move to line end (`end-of-line`) |
| `gs` | Move to first non-whitespace character on line |
| `gg` | Move to start of buffer / first line |
| `ge` | Move to end of buffer / last line |
| `gt` | Jump to beginning of buffer |
| `gb` | Jump to end of buffer |
| `gp` | Cycle through previous paste history (`yank-pop`) |

---

### 6. Match & Surround Sub-Mode (`m`)

| Key | Helix Command | Description |
|---|---|---|
| `mm` | `match_brackets` | Jump to matching bracket or quote |
| `ms<char>` | `surround_add` | Surround active selection (or word under cursor) with delimiter `<char>` |
| `mr<old><new>` | `surround_replace` | Replace surrounding delimiter `<old>` with `<new>` (e.g. `mr"'` or `mrb[`) |
| `md<char>` | `surround_delete` | Delete surrounding delimiter `<char>` (e.g. `md"` or `md(`) |
| `mi<char>` | `select_textobject_inner` | Select **inside** textobject into Select/Visual mode (`"`, `'`, `` ` ``, `()`, `[]`, `{}`, `<>`, `w`, `W`) |
| `ma<char>` | `select_textobject_around` | Select **around** textobject including delimiters and surrounding whitespace |

**Supported Delimiters & Textobjects:**
- **Quotes**: `"` (double quote), `'` (single quote), `` ` `` (backtick)
- **Matching Pairs & Aliases**:
  - `()` or `b`: Parentheses / Round brackets
  - `[]` or `r`: Square / Rectangular brackets
  - `{}` or `B`: Curly braces / Blocks
  - `<>`: Angle brackets
- **Words (for `mi`/`ma`)**:
  - `w`: Word (alphanumeric chunk)
  - `W`: WORD (whitespace-delimited token)
- **Arbitrary symbols**: `*`, `_`, `/`, etc.

**Common Shell Workflows:**
- `mi" c` → change the contents inside quotes (`"..."`) and enter Insert mode
- `ma" d` → delete the entire quoted token including quotes
- `md"` → strip quotes around cursor/selection (`"foo"` → `foo`)
- `mr"'` → convert double quotes to single quotes (`"foo"` → `'foo'`)
- `mrb[` → replace enclosing `(...)` with `[...]`


---

### 7. Space Sub-Mode (`<space>`)

| Key | Description |
|---|---|
| `<space>y` | Yank selection to system clipboard (`fish_clipboard_copy`) |
| `<space>p` | Paste from system clipboard after cursor (`fish_clipboard_paste`) |
| `<space>P` | Paste from system clipboard before cursor |
| `<space>R` | Replace active selection (or char under cursor) with system clipboard contents |
| `<space>e` | Open command line in external editor (`$EDITOR` / `hx` via `edit_command_buffer`) |
| `<space>f` | Search completions and files (`complete-and-search`) |
| `<space>b` | Open interactive command history pager (`history-pager`) |
| `<space>c` | Toggle comment prefix on command line (`#`) |

---

### 8. Search & History (`/`, `?`, `n`, `N`, `Ctrl-r`)

Helix search motions are routed through a dynamic history dispatcher with native **[Atuin](https://atuin.sh/)** support:

| Key | Helix Command | Description |
|---|---|---|
| `/` | `search` | Open interactive history search (Atuin TUI or native `history-pager`) |
| `?` | `rsearch` | Open interactive history search (Atuin TUI or native `history-pager`) |
| `Ctrl-r` | history search | Open interactive history search in Normal, Insert, and Visual modes |
| `<space>b` | buffer/history | Open interactive history search (Atuin TUI or native `history-pager`) |
| `n` | `search_next` | Step backward to next matching history entry (`history-search-backward`) |
| `N` | `search_prev` | Step forward to previous matching history entry (`history-search-forward`) |

> [!TIP]
> If you already have text on the command line (e.g. `git checkout`), pressing `/` or `?` automatically pre-filters the search for matching commands.

#### 🪄 Configurable Atuin Integration

If you use [Atuin](https://atuin.sh/) for shell history, `t68k-fish-helix` provides out-of-the-box, seamless integration:

- **Modal Keymap Detection**: Atuin normally falls back to Emacs bindings when an unrecognized keybinding engine is active. `t68k-fish-helix` automatically provides Atuin with the correct modal state (`vim-normal` in Normal/Visual mode, `vim-insert` in Insert mode) so modal navigation works inside Atuin's TUI.
- **Dynamic Fallback**: If Atuin is not installed or is disabled, search commands gracefully fall back to Fish's built-in interactive `history-pager`.

**Configuration Options:**

```fish
# Atuin Integration Mode ('auto' [default], true, false)
set -g fish_helix_atuin auto   # Automatically detect and use Atuin if installed
set -g fish_helix_atuin true   # Force enable Atuin
set -g fish_helix_atuin false  # Force disable Atuin (always use native Fish history-pager)

# Up Arrow / 'k' Integration (true, false [default])
set -g fish_helix_atuin_up false  # 'k' preserves pure Helix line/search navigation (default)
set -g fish_helix_atuin_up true   # 'k' (on line 1) and Up arrow invoke Atuin's shell-up search
```

---

## 🎨 Visual Indicators & Prompt Integration

### Cursor Morphing
Terminal cursors automatically reflect the active mode:
- **Normal Mode**: Block cursor (`█`)
- **Insert Mode**: Beam cursor (`|`)
- **Select Mode**: Underline cursor (`_`)
- **Replace Mode**: Underline cursor (`_`)

### Modern Prompts (Tide, Starship, Hydro)
Multi-line prompt engines like **Tide** and **Starship** manage their own line layouts. To prevent standard Fish `fish_mode_prompt` from outputting text on an awkward line above your prompt:

1. **Automatic Detection**: `t68k-fish-helix` auto-detects Tide and Starship and defaults `fish_helix_show_mode_prompt` to `false`.
2. **Manual Toggle**:
   ```fish
   set -U fish_helix_show_mode_prompt false  # Rely on cursor shapes or prompt items
   set -U fish_helix_show_mode_prompt true   # Force standalone fish_mode_prompt badge
   ```

### Recommended Setup for Tide Users
Tide natively includes a `vi_mode` item that reads Fish's `$fish_bind_mode` (which `t68k-fish-helix` keeps updated):

1. **Place the badge right before the prompt character (`❯`)**:
   ```fish
   set -U tide_left_prompt_items os pwd git newline vi_mode character
   ```
   *Result:*
   ```
   ~/Development/t68k-fish-helix   main ?5 ············· ✘ 2   colima  23:45:00
   [INS] ❯ command here...
   ```

2. **Or put it on your right-hand status bar**:
   ```fish
   set -U tide_right_prompt_items vi_mode $tide_right_prompt_items
   ```

3. **Customize Tide badges to use Helix names**:
   ```fish
   set -U tide_vi_mode_icon_default "NOR"
   set -U tide_vi_mode_icon_insert  "INS"  # Or set to "" to hide badge during insert
   set -U tide_vi_mode_icon_visual  "SEL"
   set -U tide_vi_mode_icon_replace "REP"
   ```

---

## 📦 Installation

### Using [Fisher](https://github.com/jorgebucaran/fisher) (Recommended)
```fish
fisher install Toshi68k/t68k-fish-helix
```

Or install from a local clone:
```fish
fisher install /path/to/t68k-fish-helix
```

### Manual Installation
Copy files directly into your Fish configuration:
```fish
git clone https://github.com/Toshi68k/t68k-fish-helix.git
cp conf.d/t68k_fish_helix.fish ~/.config/fish/conf.d/
cp functions/*.fish ~/.config/fish/functions/
```

---

## 🚀 Usage

Enable Helix keybindings:
```fish
# In your ~/.config/fish/config.fish or interactively:
set -g fish_key_bindings fish_helix_key_bindings
```

Or use the provided toggle helpers:
```fish
t68k_fish_helix_enable   # Switch to Helix bindings
t68k_fish_helix_disable  # Revert to default Fish bindings
```

---

## 🧪 Testing

The plugin includes a comprehensive test suite covering all Helix motions, selection behaviors, deletion semantics, and prompt configurations:

```fish
fish tests/test_helix_bindings.fish
```

---

## 📂 Project Structure

```
t68k-fish-helix/
├── .gitignore
├── README.md                                           # Comprehensive documentation & keymap guide
├── conf.d/
│   └── t68k_fish_helix.fish                           # Auto-loader, Tide/Starship auto-detection & lifecycle hooks
├── functions/
│   ├── fish_helix_key_bindings.fish                   # Self-contained core keybinding engine & motions
│   ├── fish_helix_cursor.fish                         # Dynamic cursor shape management (Block, Beam, Underline)
│   ├── fish_helix_mode_prompt.fish                    # Standalone modal status indicator
│   ├── __fish_helix_change.fish                       # Selection-first change ('c', 'Alt-c')
│   ├── __fish_helix_delete.fish                       # Selection-first delete ('d', 'Alt-d')
│   ├── __fish_helix_extend_to_line_bounds.fish        # Line boundary extension ('X')
│   ├── __fish_helix_goto_first_nonwhitespace.fish     # Jump to first non-whitespace ('gs')
│   ├── __fish_helix_indent.fish                       # Line indent / unindent ('>', '<')
│   ├── __fish_helix_replace_with_yanked.fish          # Replace selection with yanked text ('R')
│   ├── __fish_helix_run_count.fish                    # Numeric repetition count engine
│   ├── __fish_helix_select_line.fish                  # Line select & extend below ('x')
│   ├── __fish_helix_surround.fish                     # Surround add & pair matching ('ms')
│   └── __fish_helix_yank.fish                         # Selection-first yank ('y')
└── tests/
    └── test_helix_bindings.fish                       # 77 automated unit and regression tests
```

---

## 🛠️ Development & Contributing

This extension was created out of personal daily need for an authentic, reliable Helix editing experience in the Fish shell after transitioning from Vim to Helix. Pull requests, bug reports, and suggestions are welcome!

---

## 📄 License

[MIT](LICENSE) © [Thorsten Titze](https://github.com/Toshi68k)
