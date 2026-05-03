# Copy to ~/.config/dotfiles/local/teleport.zsh and fill locally.
# This file is tracked as documentation only. Do not put private company values here.

typeset -ga DOTFILES_TELEPORT_REGIONS=(
  "example-region-1"
  "example-region-2"
)

typeset -ga DOTFILES_TELEPORT_REQUEST_ROLES=(
  "example-role"
)

export DOTFILES_TELEPORT_KUBECONFIG="${HOME}/teleport-kubeconfig.yaml"
export DOTFILES_TELEPORT_CLUSTER_FILTER_DEFAULT="cluster"

_dotfiles_teleport_proxy_for_region() {
  local region="$1"
  echo "teleport-proxy.example.com"
}

_dotfiles_teleport_cluster_for_region() {
  local region="$1"
  echo "teleport.${region}.example.com"
}

_dotfiles_teleport_cluster_filter_for_region() {
  local region="$1"
  echo "${DOTFILES_TELEPORT_CLUSTER_FILTER_DEFAULT}"
}

_dotfiles_teleport_namespace_resource() {
  local region="$1"
  local cluster="$2"
  local namespace="$3"
  echo "/teleport.${region}.example.com/namespace/${cluster}/${namespace}"
}

_dotfiles_teleport_kube_cluster_resource() {
  local region="$1"
  local cluster="$2"
  echo "/teleport.${region}.example.com/kube_cluster/${cluster}"
}
