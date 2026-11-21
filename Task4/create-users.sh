#!/usr/bin/env bash
set -euo pipefail

out="${HOME}/.kube/propdevelopment"
mkdir -p "$out"

cluster=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')
server=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
ca_data=$(kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
if [ -n "$ca_data" ]; then
  printf '%s' "$ca_data" | base64 -d > "$out/ca.crt"
else
  ca_file=$(kubectl config view --raw --minify -o jsonpath='{.clusters[0].cluster.certificate-authority}')
  cp "$ca_file" "$out/ca.crt"
fi

create_user() {
  local user="$1"
  local group="$2"
  local csr_b64 cert i

  openssl genrsa -out "$out/${user}.key" 2048
  openssl req -new -key "$out/${user}.key" -out "$out/${user}.csr" -subj "/CN=${user}/O=${group}"
  csr_b64=$(base64 < "$out/${user}.csr" | tr -d '\n')

  kubectl delete csr "$user" --ignore-not-found
  cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${user}
spec:
  signerName: kubernetes.io/kube-apiserver-client
  request: ${csr_b64}
  usages:
  - client auth
EOF
  kubectl certificate approve "$user"

  for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
    cert=$(kubectl get csr "$user" -o jsonpath='{.status.certificate}')
    if [ -n "$cert" ]; then
      printf '%s' "$cert" | base64 -d > "$out/${user}.crt"
      break
    fi
    sleep 1
  done
  if [ ! -s "$out/${user}.crt" ]; then
    echo "Сертификат для ${user} не выпущен." >&2
    exit 1
  fi

  kubectl config set-cluster "$cluster" \
    --kubeconfig="$out/${user}.kubeconfig" \
    --server="$server" \
    --certificate-authority="$out/ca.crt" \
    --embed-certs=true
  kubectl config set-credentials "$user" \
    --kubeconfig="$out/${user}.kubeconfig" \
    --client-certificate="$out/${user}.crt" \
    --client-key="$out/${user}.key" \
    --embed-certs=true
  kubectl config set-context "$user" \
    --kubeconfig="$out/${user}.kubeconfig" \
    --cluster="$cluster" \
    --user="$user"
  kubectl config use-context "$user" --kubeconfig="$out/${user}.kubeconfig"
  echo "$user -> группа $group, kubeconfig $out/${user}.kubeconfig"
}

create_user sales-manager sales-viewers
create_user sales-devops sales-configurators
create_user zhku-manager zhku-viewers
create_user zhku-devops zhku-configurators
create_user finance-accountant finance-viewers
create_user finance-devops finance-configurators
create_user data-analyst data-viewers
create_user data-devops data-configurators
create_user security-specialist security
