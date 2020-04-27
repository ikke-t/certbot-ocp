kind: RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  labels:
    app: certbot-ocp
  name: {{ .Release.Name }}-certbot-ocp-role-binding
  namespace: {{ .Release.Namespace }}
subjects:
  - kind: ServiceAccount
    name: certbot-ocp-sa
    namespace: {{ .Release.Namespace }}
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: admin