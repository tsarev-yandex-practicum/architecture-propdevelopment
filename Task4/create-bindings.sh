#!/usr/bin/env bash
set -euo pipefail

bind_role() {
  local ns="$1"
  local role="$2"
  local group="$3"
  local user="$4"
  kubectl apply -f - <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ${role}
  namespace: ${ns}
subjects:
- kind: Group
  name: ${group}
  apiGroup: rbac.authorization.k8s.io
- kind: User
  name: ${user}
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: Role
  name: ${role}
  apiGroup: rbac.authorization.k8s.io
EOF
}

bind_role sales viewer sales-viewers sales-manager
bind_role sales configurator sales-configurators sales-devops
bind_role sales privileged security security-specialist

bind_role zhku viewer zhku-viewers zhku-manager
bind_role zhku configurator zhku-configurators zhku-devops
bind_role zhku privileged security security-specialist

bind_role finance viewer finance-viewers finance-accountant
bind_role finance configurator finance-configurators finance-devops
bind_role finance privileged security security-specialist

bind_role data viewer data-viewers data-analyst
bind_role data configurator data-configurators data-devops
bind_role data privileged security security-specialist
