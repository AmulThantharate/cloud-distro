# CloudDistro default .zshrc

# Completion system
autoload -U compinit && compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/.zcompdump"

# History configuration
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE

# Keybindings for standard terminal keys
bindkey -e
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line
bindkey "^[[3~" delete-char

# Prompt styling: user@hostname:path$
autoload -U colors && colors
PROMPT='%F{green}%n@%m%f:%F{cyan}%~%f%# '

# Helpful aliases
alias ls='ls --color=auto'
alias ll='ls -la'
alias grep='grep --color=auto'
