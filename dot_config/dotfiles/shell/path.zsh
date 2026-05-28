# Managed path and language runtime setup.

export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
export PATH="$PATH:/opt/go/bin"
export PATH="$PATH:${GOPATH:-$HOME/go}/bin"
export PATH="/opt/ngc-cli:$PATH"
export PATH="$HOME/go/bin:$PATH"

if [[ -r "$HOME/.local/bin/env" ]]; then
  . "$HOME/.local/bin/env"
elif [[ -r "$HOME/.local/share/../bin/env" ]]; then
  . "$HOME/.local/share/../bin/env"
fi

if [[ -t 0 ]]; then
  export GPG_TTY
  GPG_TTY=$(tty)
fi
