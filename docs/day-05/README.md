# Day 5: Identity and shell

## Objective and Definition of Done

Brand the distribution and give the OOBE-created user passworded sudo and command completion. Done means `sudo -v` prompts and succeeds; `cloud` is not baked into `/etc/shadow`.

## Steps

1. **[Linux Host]** Create the files below. The Dockerfile copies `rootfs/` only after tools are installed.

## Config files

1. **[Linux Host]**
   ```bash
   cat << 'EOF' > rootfs/etc/os-release
PRETTY_NAME="CloudDistro 0.1"
NAME="CloudDistro"
VERSION_ID="0.1"
VERSION="0.1 (Debian 13 trixie)"
ID=clouddistro
ID_LIKE=debian
HOME_URL="https://github.com/ORG/cloud-distro"
SUPPORT_URL="https://github.com/ORG/cloud-distro/issues"
BUG_REPORT_URL="https://github.com/ORG/cloud-distro/issues"
EOF
   cat << 'EOF' > rootfs/etc/issue
CloudDistro 0.1 - Debian 13 (trixie) WSL2
EOF
   cat << 'EOF' > rootfs/etc/motd
CloudDistro: use `sudo apt update && sudo apt upgrade` for Debian updates.
Cloud credentials belong in your user profile, never in this image.
EOF
   cat << 'EOF' > rootfs/etc/sudoers.d/cloud-distro
# OOBE-created members of sudo authenticate with their own password.
%sudo ALL=(ALL:ALL) ALL
Defaults use_pty
Defaults passwd_timeout=5
EOF
   chmod 0440 rootfs/etc/sudoers.d/cloud-distro

   # Daily login banner ASCII art and shell profile script
   cat << 'EOF' > rootfs/etc/godzilla.art
                                          .:::::::::.
                                         ::::::::::::::.
                                        :::::::::::::::::.
                                 ::::::`,,,,,`:::::4$e`::::
                                 ::::::::"?$$$$c,`:."".::::
         ,cc         cccccc,,.   `:::::::::?$$$$$$c`:::::::
         $$    c$PF" J$$$$$$$$$$$$c,``'::::::"$$$$$b`::::'       ,c$c
         ?$   J$F c$$"""?$$$$$$$$$$$$$$c,`':::`$$$$$$`:'       ,`?P"
       ,c`$$cc$$b,`"? 4c,`$$$$$$$$$$$$$$$$bc,`::(?$F '       ,z$>'  _.,,,
     , $$ `""' 3$$$$$c`$F $$$$$$$$$$$$$$$$F"$b.`::::...    -d$P",bcdP(???
   ;$$ ?$$$$$$$$$F'$$$P",J$$$$$$$$$$$$$$$$$, "$c `:::::::'  ?$$c `$$,
  ;$$$L_`"????$$F JF ccd$$$" .,. "?$$$$$$$$$,  "?.`''''`   ,_?$$  d$$??$$F
 J$$$$$$$cc$ ,$,zc$F ?$$$$F,d$$$$bcd$$$$$$$$$c  .        zd$$$$P,d$$F
 $$$$$$$$$$$ J$$$$$$  $$$$'$$P"   "$$$$$$$$$$$$c      ,,"??$$$$$ `"
.$$$$$$$$$$F.$$$$$$$h ?$$$$$F zc   ?$$$$$$$$$$$P     4$$$$$$$$P
`$$$$$$$$$$F.$$$$$$$$, $$$$$ z$P"   ?$$L ?$$$$P    db,.""?$$$P
 $$$$$$$$$$F.$$$$$$$$$ `$$$$$$P d$b  "?$r $$$".  z$$$$$$$bd$F
 $$$$$$$$$$F.$$$$$$$$$h 3P""$$b $$$ `  .,.?"  ; d$$$$$$$$$$F
 ?$$$$$$$$$F.$$$$$$$$$$,  ' ??$r`?$$cr $$$",L,'$$$$$$$$$$$F
  ?$$$$$$$$F.$$$$$$$$$$$ `bL  J$c,`"".J$$F `"" ?$$$$$$$$P"
   ?$$$$$$$F.$$$$$$$$$$$, ""  ,   "?$$P",zc     );"?$$$P
    "$$$$$$F $$$$$$$$$$$$ `$$$" 4$$$$F  `"      J z ."?
      "$$$$b ?$$$$$$$$$$$h $$P   "$$$$,       ,dP=,,r
        ""$$ ?$$$$$$$$$$$$,?$F .:  "?$$$$$$$F"$ = `P
           "'`$$$$$$$$$$$$h $F  `:...  """" ,d$b=-'
              ?$$$$$$$$$$$$ $$      `` d$$$$P""
              ?$$$$$$$$$$$$,?$c     ,z$$P"" ,r
              `$$$$$$$$$$$$L,$$$$cd$P" ,,c$$"
               ?$$$$$$$$$$$$$$$$P" ,c$$$b "
                $$$$$$$$$$$$$$$Lzd$$$$$$$
                `$$$$$$$$$$$$$$$$$$$$$$$F
               d ?$$$$$$$$$$$$$$$$$$$$$$
             ,d$$$$$$$$$$$$$$$$$$$$$$$$P
            c$$$$$$$$$$$$$$$$$$$$$$$$$$'
          c$$$$$$$$$$$$$$$$$$$$$$$$$$$'
        z$$$$$$$$$$$$$$$$$$$$$$$$$$$$P
      z$$$$$$$$$$$??????$$$$$$$$$$$$$'
    .$$$$$$$$$P" ,ccccc,"?$$$$$$$$$$' .,ccc,
   z$$$$$$$P" ,d$$$$$$$$b,"$$$$$$$$F J$$$$$$$,
  J$$$$$$$" c$$$$$$$$$$$$$,`$$$$$$F J$$$$$$$$$
 J$$$$$$$',$$$$$$$$$$$$$$$$ ?$$$$F J$$$$$$$$$$
,$$$$$$$',$$$$$$$$$$$$$$$$$h`$$$$'$$$$$$$$$$$F
<$$$$$$F $$$$$$$$$$$$$$$$$$$ ?$$'J$$$$$$$$$$$'
<$$$$$$'J$$$$$$$$$$$$$$$$$$$ ?$" "$$$$$$$$$$'  ,zcc
<$$$$$$,$$$$$$$$$$$$$$$$$$$F  ,cdc ?$$$$$$",c$$$$$F
`$$$$$$$$$$$$$$$$$$$$$$$$$F,d$$$$$F $$$$$$$$$$$$$"
 `$$$$$$$$$$$$$$$$$$$$$$$$u$$$$$$$ ,$$$$$$$$$$$"
   "$$$$$$$$$$$`$$$$$$$$$$$$$$$$" ,$$$$$$$$$$"
      "??$$$$$F $$$$$$$$$$$$$$$"  ?$$$$$$$P"
           `'   ?$$$$$$$$$$$$"      "???"
                 ?$$$$$$$$"
                   `""""'
EOF
   chmod 0644 rootfs/etc/godzilla.art

   mkdir -p rootfs/etc/profile.d
   cat << 'EOF' > rootfs/etc/profile.d/99-daily-banner.sh
#!/bin/sh
# Daily login banner for CloudDistro WSL2
# Displays /etc/godzilla.art once per calendar day on interactive login

[ -t 1 ] || return 0 2>/dev/null || exit 0

_ART="/etc/godzilla.art"
[ -f "$_ART" ] || return 0 2>/dev/null || exit 0

_TODAY="$(date +%Y-%m-%d 2>/dev/null)"
_CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}"
_STAMP_FILE="$_CACHE_DIR/.godzilla_login_date"

if [ ! -f "$_STAMP_FILE" ] || [ "$(cat "$_STAMP_FILE" 2>/dev/null)" != "$_TODAY" ]; then
    mkdir -p "$_CACHE_DIR" 2>/dev/null
    echo "$_TODAY" > "$_STAMP_FILE" 2>/dev/null
    printf '\033[32m'
    cat "$_ART"
    printf '\033[0m\n'
fi
EOF
   chmod 0755 rootfs/etc/profile.d/99-daily-banner.sh

   # Configure Zsh as the default shell and supply user defaults
   mkdir -p rootfs/etc/default rootfs/etc/skel rootfs/etc/zsh
   cat << 'EOF' > rootfs/etc/default/useradd
# Default settings for useradd(8) in CloudDistro
SHELL=/bin/zsh
GROUP=100
HOME=/home
INACTIVE=-1
EXPIRE=
SKEL=/etc/skel
CREATE_MAIL_SPOOL=no
EOF
   chmod 0644 rootfs/etc/default/useradd

   cat << 'EOF' > rootfs/etc/skel/.zshrc
# CloudDistro default .zshrc
autoload -U compinit && compinit -d "${XDG_CACHE_HOME:-$HOME/.cache}/.zcompdump"
HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY
setopt SHARE_HISTORY
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
bindkey -e
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line
bindkey "^[[3~" delete-char
autoload -U colors && colors
PROMPT='%F{green}%n@%m%f:%F{cyan}%~%f%# '
alias ls='ls --color=auto'
alias ll='ls -la'
alias grep='grep --color=auto'
EOF
   chmod 0644 rootfs/etc/skel/.zshrc

   cat << 'EOF' > rootfs/etc/zsh/zprofile
# /etc/zsh/zprofile: source /etc/profile so PATH and /etc/profile.d scripts execute in zsh
if [ -f /etc/profile ]; then
    . /etc/profile
fi
EOF
   chmod 0644 rootfs/etc/zsh/zprofile
   ```

## Verify

```bash
docker run --rm clouddistro:dev visudo -cf /etc/sudoers.d/cloud-distro
```
Expected: `parsed: OK`.

## Troubleshooting

| symptom | cause | fix |
|---|---|---|
| sudo needs no password | an unsafe drop-in remains | remove it; use the file above |
| completions absent | interactive zsh/bash not sourced | install `bash-completion` / `zsh`; verify `.zshrc` or `/etc/profile.d` |
| banner not displaying | shell not interactive or terminal check failed | verify `[ -t 1 ]` in an interactive shell session |

## Commit

```bash
git add rootfs && git commit -m 'feat: add CloudDistro identity, zsh default shell, and sudo policy'
```
