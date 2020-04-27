---
apiVersion: v1
kind: Pod
metadata:
  labels:
    app: certbot-ocp
    name: {{ .Release.Name }}-certbot-ocp
  name: {{ .Release.Name }}-certbot-ocp
  namespace: {{ .Release.Namespace }}
spec:
  containers:
    - env:
      - name: EMAIL
        value: {{ .Values.letsencyrptEmail }}
      - name: CERTBOT_EXTRA_OPTS
        value: {{ .Values.letsencyrptExtraOpts }}
      image: {{ .Values.image.repository}}:{{ .Chart.Version }}
      imagePullPolicy: IfNotPresent
      name: certbot-ocp
      ports:
        - containerPort: 8080
          protocol: TCP
      resources:
        limits:
          memory: 128Mi
          cpu: 100m
        requests:
          memory: 128Mi
          cpu: 100m
      terminationMessagePath: /dev/termination-log
      terminationMessagePolicy: File
      volumeMounts:
        - mountPath: /etc/letsencrypt
          name: letsencrypt
  dnsPolicy: ClusterFirst
  restartPolicy: Never
  serviceAccount: certbot-ocp-sa
  serviceAccountName: certbot-ocp-sa
  terminationGracePeriodSeconds: 10
  volumes:
    - name: letsencrypt
      persistentVolumeClaim:
        claimName: {{ .Release.Name }}-certbot-letsencrypt
