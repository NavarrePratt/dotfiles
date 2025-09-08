
# >>> pyenv setup >>>
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"
# <<< pyenv setup <<<

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:$HOME/.local/bin:/usr/local/bin:$PATH

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time Oh My Zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at randomz 
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
  git
  zsh-syntax-highlighting
  zsh-autosuggestions
  kubectl
  kubectx
  kube-ps1
  fzf
  z
  eza
  helm
  macos
  pip
  zsh-interactive-cd
  colorize
  gcloud
  python
  pyenv
  uv
)

zstyle ':omz:plugins:eza' 'icons' no

export ZSH_DISABLE_COMPFIX=true

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch $(uname -m)"

# Set personal aliases, overriding those provided by Oh My Zsh libs,
# plugins, and themes. Aliases can be placed here, though Oh My Zsh
# users are encouraged to define aliases within a top-level file in
# the $ZSH_CUSTOM folder, with .zsh extension. Examples:
# - $ZSH_CUSTOM/aliases.zsh
# - $ZSH_CUSTOM/macos.zsh
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"

export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

export PATH="$PATH:/opt/go/bin"
export PATH=$PATH:${GOPATH:-$HOME/go}/bin

alias cat="ccat"
alias eza="eza --color=auto"


# kubecolor
alias k=kubecolor
alias kubectl=kubecolor
compdef kubecolor=kubectl # only needed for zsh
export KUBECOLOR_OBJ_FRESH=12h # highlight resources newer than 12h

alias decode_secret="kubectl get secret -o go-template='{{range \$k,\$v := .data}}{{printf \"%s: \" \$k}}{{if not \$v}}{{\$v}}{{else}}{{\$v | base64decode}}{{end}}{{\"\\n\"}}{{end}}'"

#alias tailscale="/Applications/Tailscale.app/Contents/MacOS/Tailscale"

#alias ssh_vdi="ssh npratt@npratt-1.tenant-coreweave-vdi.coreweave.cloud"

# nvidia's cli thing
export PATH="/opt/ngc-cli:$PATH"

# more kubectl aliases
alias kgns="kubectl get nodeset"
alias kgn="kubectl get nodes"
alias kdn="kubectl describe node"
alias kgnp="kubectl get nodepool"
alias kdnp="kubectl describe nodepool"
alias kl="kubectl logs -f --tail=20"
alias kneat="kubectl neat"

# cwic aliases
alias nodes="cwic nodes get"
alias scluster="cwic sunk cluster"
alias scd="cwic sunk cluster describe"
alias snode="cwic sunk node get"
alias snodes="cwic sunk nodes get"
alias sng="cwic sunk node get"
alias snd="cwic sunk node describe"
alias sjg="cwic sunk job get"
alias sjd="cwic sunk job describe"

kns(){
  if [ $# -eq 1 ]; then
    kubectl config set-context --current --namespace=$1
    return
  fi
  selected_namespace=$(kubectl get namespace --no-headers | fzf | awk '{ print $1 }')
  if [ -n "$selected_namespace" ]; then
    kubectl config set-context --current --namespace=$selected_namespace
  else
    echo "No namespace selected."
  fi
}
kctx(){
  # If the function is given an argument, use that as the context
  if [ $# -eq 1 ]; then
    kubectl config use-context $1
    return
  fi
  selected_context=$(kubectl config get-contexts --no-headers -oname | fzf --prompt "Select a context: ")
  if [ -n "$selected_context" ]; then
    kubectl config use-context "$selected_context"
  else
    echo "No context selected."
  fi
}

alias ht="helm template"

# ~~~~~~~~ Teleport ~~~~~~~~

# Helper – pick the right Teleport proxy for a region
#   • Any region that *starts with* "eu" → teleport.eu-south-03b.int.coreweave.com:443
#   • Everything else                  → teleport.na.int.coreweave.com
_get_teleport_proxy() {
  local region="$1"
  if [[ "${region}" == eu* ]]; then
    echo "teleport.eu-south-03b.int.coreweave.com:443"
  else
    echo "teleport.na.int.coreweave.com"
  fi
}
tl(){
  # Pre-defined array of regions
  local regions=(
    "lga1" "ord1" "las1" "rno2" "rdu1" "eu-south-03b"
    "us-east-01a" "us-east-03" "us-west-03" "us-east-02" "us-east-04"
    "us-east-08a" "us-west-04a" "us-west-06a" "us-west-08a" "us-east-06a"
    "us-west-07a" "us-west-01a"
  )

  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage:"
    echo "  tl                     # interactive region + cluster selection"
    echo "  tl <region>            # region fixed, interactive cluster selection"
    echo "  tl <region> <cluster>  # direct login (no interactive selection)"
    return
  fi
  
  # If no argument is passed, ask the user to select a region
  local selected_region
  if [ $# -eq 0 ]; then
      echo "Please select a region:"
      region=$(printf '%s\n' "${regions[@]}" | fzf --height 20% --prompt "Select a region: ")
      if [ -n "$region" ]; then
          selected_region=$region
          echo "Selected region: $selected_region"
      else
          echo "Invalid option. Please try again."
          return 1
      fi
  else
      selected_region=$1
  fi

  local proxy=$(_get_teleport_proxy "$selected_region")
  tsh login --proxy="$proxy" "teleport.${selected_region}.int.coreweave.com" || return 1

  export KUBECONFIG=${HOME?}/teleport-kubeconfig.yaml
  typeset -a options
  local options

  # Retrieve the list of Kubernetes clusters
  if [ "$selected_region" = "katalog" ]; then
    options=$(tsh kube ls | grep katalog | awk '{print $1}')
  else
    options=$(tsh kube ls | grep cluster | awk '{print $1}')
  fi

  if [ -z "$options" ]; then
      echo "No clusters found."
      return 1
  fi

  local selected_option
  if [ $# -ge 2 ]; then
    # Cluster provided explicitly
    selected_option=$2
    if ! echo "$options" | grep -qx "$selected_option"; then
      echo "Warning: cluster '$selected_option' not in discovered list; attempting login anyway."
    fi
  else
    # Interactive selection
    selected_option=$(echo "$options" | fzf --height 20% --prompt "Select a cluster: ")
    if [ -z "$selected_option" ]; then
      echo "No selection made."
      return 1
    fi
    echo "You selected: $selected_option"
  fi

  if tsh kube login "$selected_option"; then
    echo "Logged into $selected_option"
    export TSH_REGION=$selected_region
    export TSH_CLUSTER=$selected_option
  else
    echo "Failed to log into $selected_option"
    return 1
  fi
}
tclear(){
  tsh logout
  unset TSH_REGION
  unset TSH_CLUSTER
  unset KUBECONFIG
}
trns(){
  # usage instructions with the --help flag
  if [ "$1" = "--help" ]; then
    echo "Usage: trns [namespace] [role] [reason]"
    return
  fi
  if [ -z "$TSH_REGION" ]; then
    echo "Not currently logged into teleport."
    if ! tl; then
      echo "Failed to login to teleport"
      return
    fi
  fi
  local selected_namespace
  if [ $# -eq 0 ]; then
    namespaces=$(tsh request search --kind=namespace | sed -e :a -e '$d;N;2,5ba' -e 'P;D' | tail -n+3 | awk '{print $1}')
    selected_namespace=$(echo "$namespaces" | fzf --height 20% --prompt "Select a namespace: ")
  else
    selected_namespace=$1
  fi

  local selected_role
  if [ $# -lt 2 ]; then
    local roles=("k8s-admin" "k8s-super-admin" "k8s-admin-internal")
    selected_role=$(printf '%s\n' "${roles[@]}" | fzf --height 20% --prompt "Select a role: ")
  else
    selected_role=$2
  fi

   # If no argument is passed, ask the user to provide a reason
  local selected_reason
  if [ $# -lt 3 ]; then
    local reason
    vared -p 'Please provide a justification for your request: ' reason
    if [ -n "$reason" ]; then
        selected_reason=$reason
    else
        echo "Invalid input. Please try again."
    fi

  else
    selected_reason=$3
  fi
  tsh request create --resource /teleport.$TSH_REGION.int.coreweave.com/namespace/$TSH_CLUSTER/$selected_namespace --roles=$selected_role --reason="$selected_reason" ${@: 4}
  kubectl ns $selected_namespace
}

trc(){
  tclear
  if [ -z "$TSH_REGION" ]; then
    echo "Not currently logged into teleport."
    if ! tl; then
      echo "Failed to login to teleport"
      return
    fi
  fi
  local selected_cluster
  if [ -z "$TSH_CLUSTER" ]; then

    if [ $# -eq 0 ]; then
      clusters=$(tsh request search --kind=kube_cluster | head -n -5 | tail -n+3 | awk '{print $1}')
      selected_cluster=$(echo "$clusters" | fzf --height 20% --prompt "Select a cluster: ")
    else
      selected_cluster=$1
    fi
  else
    selected_cluster=$TSH_CLUSTER
  fi
  local selected_role
  if [ $# -lt 2 ]; then
    local roles=("k8s-admin" "k8s-super-admin" "k8s-admin-internal")
    selected_role=$(printf '%s\n' "${roles[@]}" | fzf --height 20% --prompt "Select a role: ")
  else
    selected_role=$2
  fi
  # If no argument is passed, ask the user to provide a reason
  local selected_reason
  if [ $# -lt 3 ]; then
    local reason
    vared -p 'Please provide a justification for your request: ' reason
    if [ -n "$reason" ]; then
        selected_reason=$reason
    else
        echo "Invalid input. Please try again."
    fi

  else
    selected_reason=$3
  fi
  tsh request create --resource /teleport.$TSH_REGION.int.coreweave.com/kube_cluster/$selected_cluster --roles=$selected_role --reason="$selected_reason" ${@: 4}
  tsh kube login $selected_cluster --cluster teleport.$TSH_REGION.int.coreweave.com
}

tctx(){
  scluster=$(printf '%s\n' "${(kubectl ctx)[@]}" | fzf --height 20% --prompt "Select a role: ")
}

tswitch() {
  tclear          # log out first
  tl              # fresh login (sets TSH_REGION / TSH_CLUSTER)

  # Work out which proxy we should be talking to now
  local proxy=$(_get_teleport_proxy "$TSH_REGION")

  local request
  if [[ $# -gt 0 ]]; then
    request="$1"
  else
    request=$(tsh request ls --proxy="$proxy" --my-requests -f json \
             | jq --arg r "$TSH_REGION" \
                 '[.[] | select(.spec.resource_ids[0].cluster=="teleport.\($r).int.coreweave.com")] | .[-1].metadata.name' \
             | tr -d '"')
  fi
  [[ -z "$request" ]] && { echo "No request found."; return 1; }

  # Accept / assume the request
  tsh login --request-id="$request" --proxy="$proxy"     || return 1
  tsh kube login "$TSH_CLUSTER" \
      --cluster "teleport.${TSH_REGION}.int.coreweave.com" \
      --all \
      --set-context-name "${TSH_REGION}-${TSH_CLUSTER}"
}


# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

. "$HOME/.local/share/../bin/env"

export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
