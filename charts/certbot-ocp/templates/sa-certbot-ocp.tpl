---
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app: certbot-ocp
  name: {{ .Release.Name }}-certbot-ocp-sa
  namespace: {{ .Release.Namespace }}
