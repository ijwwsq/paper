# greet — ASCII art + date, uptime, memory and today's open tasks from the Obsidian daily note.
# Pure zsh, reads only /proc and one note, ~30 ms. Settings: ~/.config/paper/config. Run manually: `greet`.
#
# Shows itself:
#   - outside tmux: on every new shell
#   - inside tmux:  on every new tab (window), not in splits
#   (re-opening the terminal into an existing session pops it up instead — see bin/term-start)

typeset -g PAPER_CONFIG=${PAPER_CONFIG:-$HOME/.config/paper/config}

greet() {
  emulate -L zsh
  setopt no_prompt_subst

  local VAULT DAILY_DIR="daily" ART="$HOME/.config/paper/art.txt" GREET_TASKS=3
  [[ -r $PAPER_CONFIG ]] && source "$PAPER_CONFIG"

  local -a months=(января февраля марта апреля мая июня июля августа сентября октября ноября декабря)
  local -a days=(воскресенье понедельник вторник среда четверг пятница суббота)

  # art: any text file, printed as-is (no escapes, no prompt expansion)
  local -a art; local aw=0 a
  [[ -r $ART ]] && art=("${(@f)$(<$ART)}")
  for a in $art; do (( ${#a} > aw )) && aw=${#a}; done
  (( aw && (aw += 2) ))

  zmodload -F zsh/datetime b:strftime p:EPOCHSECONDS 2>/dev/null
  local m d w hm
  strftime -s m '%m' $EPOCHSECONDS; strftime -s d '%d' $EPOCHSECONDS
  strftime -s w '%w' $EPOCHSECONDS; strftime -s hm '%H:%M' $EPOCHSECONDS

  local up; up="$(</proc/uptime)"; up=${up%%.*}
  local -A mi; local k v rest
  while read -r k v rest; do mi[${k%:}]=$v; done < /proc/meminfo
  local used=$(( (mi[MemTotal] - mi[MemAvailable]) / 1024 )) total=$(( mi[MemTotal] / 1024 ))

  # open tasks of today: [ ] todo and [/] in progress; `t` time fields are hidden, a running timer is shown
  setopt extended_glob
  local note="$VAULT/$DAILY_DIR/$(strftime '%Y-%m-%d' $EPOCHSECONDS).md" line body st sp run=""
  local -a tasks
  if [[ -n $VAULT && -r $note ]]; then
    while IFS= read -r line; do
      [[ $line =~ '^[[:space:]]*- \[[ /]\][[:space:]]*(.+)$' ]] || continue
      body=${match[1]} st="" sp=0
      [[ $body =~ '\[started:: ([0-9T:-]+)\]' ]] && st=${match[1]}
      [[ $body =~ '\[spent:: ([0-9]+)h' ]] && (( sp += match[1] * 60 ))
      [[ $body =~ '\[spent:: ([^]]*[^0-9])?([0-9]+)m' ]] && (( sp += match[2] ))
      body=${${body//\[(started|spent)::[^\]]#\]/}%% #}
      if [[ -n $st ]]; then
        local s0; strftime -r -s s0 '%Y-%m-%dT%H:%M' $st 2>/dev/null && (( sp += (EPOCHSECONDS - s0) / 60 ))
        run="%F{4}▶ ${body[1,40]} · $(( sp / 60 ))ч $(( sp % 60 ))м%f"
        run=${run/ 0ч / }
      else
        tasks+=("$body")
      fi
    done < "$note"
  fi

  local -a info=(
    "%F{0}%B${d#0} ${months[${m#0}]}, ${days[$((w + 1))]} · $hm%b%f"
    "%F{8}up $((up / 86400))d $((up % 86400 / 3600))h $((up % 3600 / 60))m · mem ${used}M / ${total}M%f"
    ""
  )
  [[ -n $run ]] && info+=("$run")
  if (( $#tasks )); then
    info+=("%F{4}сегодня:%f")
    local t; for t in "${(@)tasks[1,GREET_TASKS]}"; do info+=("%F{8}·%f ${t[1,48]}"); done
    (( $#tasks > GREET_TASKS )) && info+=("%F{8}  и ещё $(( $#tasks - GREET_TASKS )) · t%f")
  else
    info+=("%F{8}на сегодня задач нет · t add текст%f")
  fi

  print
  local i n=$(( $#art > $#info ? $#art : $#info ))
  for (( i = 1; i <= n; i++ )); do
    (( aw )) && print -rn -- $'\e[90m'"${(r:aw:)art[i]}"$'\e[0m'
    print -rP -- "${info[i]}"
  done
  print
}

if [[ -o interactive ]]; then
  if [[ -z $TMUX ]] || [[ "$(tmux display -p '#{window_panes}' 2>/dev/null)" == 1 ]]; then
    greet
  fi
fi
