#!/usr/bin/env bash
# paper — WSL / Linux side: t, greeting, term-start, tmux, zsh theme.
# Safe to re-run: existing files are backed up as *.bak-<date>, your config and art are never overwritten.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
stamp="$(date +%Y%m%d-%H%M%S)"
c() { printf '\033[%sm%s\033[0m' "$1" "$2"; }
say() { printf '  %s %s\n' "$(c 34 '·')" "$*"; }

put() {  # put SRC DST [mode] — copy, backing up a different existing file
  local src="$here/$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [[ -e $dst ]] && ! cmp -s "$src" "$dst"; then cp "$dst" "$dst.bak-$stamp"; say "backup  $dst.bak-$stamp"; fi
  tr -d '\r' < "$src" > "$dst"
  [[ ${3:-} ]] && chmod "$3" "$dst"
  say "$(c 90 "$1") → $dst"
}

seed() {  # seed SRC DST — copy only if DST doesn't exist
  [[ -e $2 ]] && { say "keep    $2"; return; }
  mkdir -p "$(dirname "$2")"; tr -d '\r' < "$here/$1" > "$2"; say "$(c 90 "$1") → $2"
}

printf '\n%s\n\n' "$(c 1 'paper') $(c 90 '— installing')"

for dep in zsh tmux python3; do
  command -v "$dep" >/dev/null || { echo "  нужен $dep: sudo apt install $dep"; exit 1; }
done

put bin/t            "$HOME/.local/bin/t"            +x
put bin/term-start   "$HOME/.local/bin/term-start"   +x
put bin/keys         "$HOME/.local/bin/keys"         +x
put zsh/greet.zsh    "$HOME/.config/zsh/greet.zsh"
put tmux/tmux.conf   "$HOME/.tmux.conf"
seed config.example  "$HOME/.config/paper/config"
seed art/cat.txt "$HOME/.config/paper/art.txt"
[[ -d $HOME/.oh-my-zsh ]] && put zsh/mini.zsh-theme "$HOME/.oh-my-zsh/custom/themes/mini.zsh-theme"

# neovim config (plugins install themselves on first start via lazy.nvim)
for f in $(cd "$here" && find nvim -type f); do put "$f" "$HOME/.config/$f"; done
command -v nvim >/dev/null || say "nvim не найден — свежий: https://github.com/neovim/neovim/releases (nvim-linux-x86_64.tar.gz → ~/.local)"

# hook into ~/.zshrc once (marked block, easy to remove)
if ! grep -q '>>> paper >>>' "$HOME/.zshrc" 2>/dev/null; then
  cat >> "$HOME/.zshrc" <<'EOF'

# >>> paper >>>
path=("$HOME/.local/bin" $path)
(( $+commands[nvim] )) && export EDITOR=nvim VISUAL=nvim
[[ -r ~/.config/zsh/greet.zsh ]] && source ~/.config/zsh/greet.zsh
# <<< paper <<<
EOF
  say "~/.zshrc: added the paper block"
else
  say "keep    ~/.zshrc block"
fi

tmux info >/dev/null 2>&1 && tmux source-file "$HOME/.tmux.conf" && say "tmux config reloaded"

cat <<EOF

  $(c 1 'дальше')
  1. пропиши свой волт:   $(c 34 "\$EDITOR ~/.config/paper/config")
  2. проверь:             $(c 34 't config')  и  $(c 34 't help')
  3. тема промпта:        ZSH_THEME="mini" в ~/.zshrc  $(c 90 '(oh-my-zsh)')
  4. свой арт:            ~/.config/paper/art.txt  $(c 90 '— любой текст')

EOF
