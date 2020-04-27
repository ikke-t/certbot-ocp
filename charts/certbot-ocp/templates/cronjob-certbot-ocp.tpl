---
apiVersion: batch/v1beta1
kind: CronJob
metadata:
  labels:
    app: certbot-ocp
  name: {{ .Release.Name }}-certbot-ocp
  namespace: {{ .Release.Namespace }}
spec:
  concurrencyPolicy: Forbid
  failedJobsHistoryLimit: 1
  jobTemplate:
    metadata:
      creationTimestamp: null
    spec:
      template:
        metadata:
          creationTimestamp: null
          labels:
            parent: certbot-ocp
            name: {{ .Release.Name }}-certbot-ocp
            app: certbot-ocp
        spec:
          containers:
            - env:
                - name: EMAIL
                  value: {{ .Values.letsencyrptEmail }}
                - name: CERTBOT_EXTRA_OPTS
                  value: {{ .Values.letsencyrptExtraOpts}}
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
          schedulerName: default-scheduler
          securityContext: {}
          serviceAccount: certbot-ocp-sa
          serviceAccountName: certbot-ocp-sa
          terminationGracePeriodSeconds: 10
          volumes:
            - name: letsencrypt
              persistentVolumeClaim:
                claimName: {{ .Release.Name }}-certbot-letsencrypt
  schedule: '{{ .Values.cronjobSchedule }}'
  successfulJobsHistoryLimit: 1
  suspend: false
