---
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app: certbot-ocp
  name: certbot-ocp-sa
  namespace: {{ .Release.Namespace }}
