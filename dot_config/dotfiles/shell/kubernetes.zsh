# Kubernetes, Helm, and cwic helpers.

alias k=kubecolor
alias kubectl=kubecolor
(( $+functions[compdef] )) && compdef _kubectl kubecolor
export KUBECOLOR_OBJ_FRESH=12h

alias decode_secret="kubectl get secret -o go-template='{{range \$k,\$v := .data}}{{printf \"%s: \" \$k}}{{if not \$v}}{{\$v}}{{else}}{{\$v | base64decode}}{{end}}{{\"\\n\"}}{{end}}'"

alias kgns="kubectl get nodeset"
alias kgn="kubectl get nodes"
alias kdn="kubectl describe node"
alias kgnp="kubectl get nodepool"
alias kdnp="kubectl describe nodepool"
unalias kl 2>/dev/null || true
kl() {
  kubectl wait --for=condition=ContainersReady "pod/$1" --timeout=120s >/dev/null 2>&1 || true
  kubectl logs -f --tail=20 "$@"
}
alias kneat="kubectl neat"

alias nodes="cwic nodes get"
alias scluster="cwic sunk cluster"
alias scd="cwic sunk cluster describe"
alias snode="cwic sunk node get"
alias snodes="cwic sunk nodes get"
alias sng="cwic sunk node get"
alias snd="cwic sunk node describe"
alias sjg="cwic sunk job get"
alias sjd="cwic sunk job describe"

kns() {
  if [ $# -eq 1 ]; then
    kubectl config set-context --current --namespace="$1"
    return
  fi

  local selected_namespace
  selected_namespace=$(kubectl get namespace --no-headers | fzf | awk '{ print $1 }')
  if [ -n "$selected_namespace" ]; then
    kubectl config set-context --current --namespace="$selected_namespace"
  else
    echo "No namespace selected."
  fi
}

kctx() {
  if [ $# -eq 1 ]; then
    kubectl config use-context "$1"
    return
  fi

  local selected_context
  selected_context=$(kubectl config get-contexts --no-headers -oname | fzf --prompt "Select a context: ")
  if [ -n "$selected_context" ]; then
    kubectl config use-context "$selected_context"
  else
    echo "No context selected."
  fi
}

alias ht="helm template"
