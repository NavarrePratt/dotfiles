# Generic Teleport helpers. Private company-specific values live in:
#   ~/.config/dotfiles/local/teleport.zsh

_dotfiles_teleport_local_config="${DOTFILES_TELEPORT_LOCAL_CONFIG:-$HOME/.config/dotfiles/local/teleport.zsh}"
[[ -r "$_dotfiles_teleport_local_config" ]] && source "$_dotfiles_teleport_local_config"
unset _dotfiles_teleport_local_config

_dotfiles_teleport_require_config() {
  local missing=0

  if (( ${#DOTFILES_TELEPORT_REGIONS[@]} == 0 )); then
    missing=1
  fi

  if (( ${#DOTFILES_TELEPORT_REQUEST_ROLES[@]} == 0 )); then
    missing=1
  fi

  local required_function
  for required_function in \
    _dotfiles_teleport_proxy_for_region \
    _dotfiles_teleport_cluster_for_region \
    _dotfiles_teleport_namespace_resource \
    _dotfiles_teleport_kube_cluster_resource; do
    if (( ! $+functions[$required_function] )); then
      missing=1
    fi
  done

  if (( missing )); then
    echo "Teleport local config is missing. Copy ~/.config/dotfiles/local/teleport.example.zsh to ~/.config/dotfiles/local/teleport.zsh and fill it in."
    return 1
  fi
}

if (( ! $+functions[_dotfiles_teleport_cluster_filter_for_region] )); then
  _dotfiles_teleport_cluster_filter_for_region() {
    echo "${DOTFILES_TELEPORT_CLUSTER_FILTER_DEFAULT:-cluster}"
  }
fi

tl() {
  if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    echo "Usage:"
    echo "  tl                     # interactive region and cluster selection"
    echo "  tl <region>            # region fixed, interactive cluster selection"
    echo "  tl <region> <cluster>  # direct login"
    return
  fi

  _dotfiles_teleport_require_config || return 1

  local selected_region
  if [ $# -eq 0 ]; then
    local region
    echo "Please select a region:"
    region=$(printf '%s\n' "${DOTFILES_TELEPORT_REGIONS[@]}" | fzf --height 20% --prompt "Select a region: ")
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

  local proxy cluster
  proxy=$(_dotfiles_teleport_proxy_for_region "$selected_region")
  cluster=$(_dotfiles_teleport_cluster_for_region "$selected_region")
  tsh login --proxy="$proxy" "$cluster" || return 1

  export KUBECONFIG="${DOTFILES_TELEPORT_KUBECONFIG:-${HOME?}/teleport-kubeconfig.yaml}"

  local filter options
  filter=$(_dotfiles_teleport_cluster_filter_for_region "$selected_region")
  if [ -n "$filter" ]; then
    options=$(tsh kube ls | grep "$filter" | awk '{print $1}')
  else
    options=$(tsh kube ls | awk 'NR > 1 {print $1}')
  fi

  if [ -z "$options" ]; then
    echo "No clusters found."
    return 1
  fi

  local selected_option
  if [ $# -ge 2 ]; then
    selected_option=$2
    if ! echo "$options" | grep -qx "$selected_option"; then
      echo "Warning: cluster '$selected_option' not in discovered list; attempting login anyway."
    fi
  else
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

tclear() {
  tsh logout
  unset TSH_REGION
  unset TSH_CLUSTER
  unset KUBECONFIG
}

trns() {
  if [ "$1" = "--help" ]; then
    echo "Usage: trns [namespace] [role] [reason]"
    return
  fi

  _dotfiles_teleport_require_config || return 1

  if [ -z "$TSH_REGION" ]; then
    echo "Not currently logged into teleport."
    if ! tl; then
      echo "Failed to login to teleport"
      return
    fi
  fi

  local selected_namespace
  if [ $# -eq 0 ]; then
    local namespaces
    namespaces=$(tsh request search --kind=namespace | sed -e :a -e '$d;N;2,5ba' -e 'P;D' | tail -n+3 | awk '{print $1}')
    selected_namespace=$(echo "$namespaces" | fzf --height 20% --prompt "Select a namespace: ")
  else
    selected_namespace=$1
  fi

  local selected_role
  if [ $# -lt 2 ]; then
    selected_role=$(printf '%s\n' "${DOTFILES_TELEPORT_REQUEST_ROLES[@]}" | fzf --height 20% --prompt "Select a role: ")
  else
    selected_role=$2
  fi

  local selected_reason
  if [ $# -lt 3 ]; then
    local reason
    vared -p 'Please provide a justification for your request: ' reason
    if [ -n "$reason" ]; then
      selected_reason=$reason
    else
      echo "Invalid input. Please try again."
      return 1
    fi
  else
    selected_reason=$3
  fi

  local resource
  resource=$(_dotfiles_teleport_namespace_resource "$TSH_REGION" "$TSH_CLUSTER" "$selected_namespace")
  tsh request create --resource "$resource" --roles="$selected_role" --reason="$selected_reason" "${@:4}"
  kubectl ns "$selected_namespace"
}

trc() {
  _dotfiles_teleport_require_config || return 1

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
      local clusters
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
    selected_role=$(printf '%s\n' "${DOTFILES_TELEPORT_REQUEST_ROLES[@]}" | fzf --height 20% --prompt "Select a role: ")
  else
    selected_role=$2
  fi

  local selected_reason
  if [ $# -lt 3 ]; then
    local reason
    vared -p 'Please provide a justification for your request: ' reason
    if [ -n "$reason" ]; then
      selected_reason=$reason
    else
      echo "Invalid input. Please try again."
      return 1
    fi
  else
    selected_reason=$3
  fi

  local resource cluster
  resource=$(_dotfiles_teleport_kube_cluster_resource "$TSH_REGION" "$selected_cluster")
  cluster=$(_dotfiles_teleport_cluster_for_region "$TSH_REGION")
  tsh request create --resource "$resource" --roles="$selected_role" --reason="$selected_reason" "${@:4}"
  tsh kube login "$selected_cluster" --cluster "$cluster"
}

tctx() {
  kctx "$@"
}

tswitch() {
  _dotfiles_teleport_require_config || return 1

  tclear
  tl || return 1

  local proxy cluster
  proxy=$(_dotfiles_teleport_proxy_for_region "$TSH_REGION")
  cluster=$(_dotfiles_teleport_cluster_for_region "$TSH_REGION")

  local request
  if [[ $# -gt 0 ]]; then
    request="$1"
  else
    request=$(tsh request ls --proxy="$proxy" --my-requests -f json \
      | jq --arg cluster "$cluster" \
        '[.[] | select(.spec.resource_ids[0].cluster==$cluster)] | .[-1].metadata.name' \
      | tr -d '"')
  fi
  [[ -z "$request" ]] && { echo "No request found."; return 1; }

  tsh login --request-id="$request" --proxy="$proxy" || return 1
  tsh kube login "$TSH_CLUSTER" \
    --cluster "$cluster" \
    --all \
    --set-context-name "${TSH_REGION}-${TSH_CLUSTER}"
}
