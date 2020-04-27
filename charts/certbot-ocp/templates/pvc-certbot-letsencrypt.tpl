---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  labels:
    app: certbot-ocp
  finalizers:
    - kubernetes.io/pvc-protection
  name: {{ .Release.Name }}-certbot-letsencrypt
  namespace: {{ .Release.Namespace }}
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: {{.Values.persistentStorageSize }}
