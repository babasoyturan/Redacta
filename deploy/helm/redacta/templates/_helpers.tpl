{{- define "redacta.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "redacta.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "redacta.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ include "redacta.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "redacta.selectorLabels" -}}
app.kubernetes.io/name: {{ include "redacta.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "redacta.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "redacta.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "redacta.componentServiceAccountName" -}}
{{- $root := .root -}}
{{- $component := .component -}}
{{- $componentName := "" -}}
{{- if $root.Values.serviceAccount.components -}}
{{- $componentName = (index $root.Values.serviceAccount.components $component | default "") -}}
{{- end -}}
{{- if $componentName -}}
{{- $componentName -}}
{{- else if $root.Values.serviceAccount.name -}}
{{- $root.Values.serviceAccount.name -}}
{{- else -}}
{{- printf "%s-%s" (include "redacta.fullname" $root) $component | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "redacta.workloadIdentityLabels" -}}
{{- if .Values.workloadIdentity.enabled }}
azure.workload.identity/use: "true"
{{- end }}
{{- end -}}

{{- define "redacta.workloadIdentityClientId" -}}
{{- $root := .root -}}
{{- $component := .component -}}
{{- $componentClientId := "" -}}
{{- if $root.Values.workloadIdentity.clientIds -}}
{{- $componentClientId = (index $root.Values.workloadIdentity.clientIds $component | default "") -}}
{{- end -}}
{{- if $componentClientId -}}
{{- $componentClientId -}}
{{- else -}}
{{- $root.Values.workloadIdentity.clientId -}}
{{- end -}}
{{- end -}}

{{- define "redacta.workloadIdentityAnnotation" -}}
{{- if .root.Values.workloadIdentity.enabled }}
{{- $clientId := include "redacta.workloadIdentityClientId" . -}}
{{- if $clientId }}
azure.workload.identity/client-id: {{ $clientId | quote }}
{{- end }}
{{- end }}
{{- end -}}

{{- define "redacta.secretProviderClassName" -}}
{{- $root := .root -}}
{{- $component := .component -}}
{{- $componentName := "" -}}
{{- if $root.Values.keyVault.csi.secretProviderClassNames -}}
{{- $componentName = (index $root.Values.keyVault.csi.secretProviderClassNames $component | default "") -}}
{{- end -}}
{{- if $componentName -}}
{{- $componentName -}}
{{- else -}}
{{- $root.Values.keyVault.csi.secretProviderClassName -}}
{{- end -}}
{{- end -}}

{{- define "redacta.componentSecretName" -}}
{{- $root := .root -}}
{{- $component := .component -}}
{{- $componentName := "" -}}
{{- if $root.Values.secrets.names -}}
{{- $componentName = (index $root.Values.secrets.names $component | default "") -}}
{{- end -}}
{{- if $componentName -}}
{{- $componentName -}}
{{- else -}}
{{- $root.Values.secrets.name -}}
{{- end -}}
{{- end -}}

{{- define "redacta.secretVolumeMounts" -}}
{{- if .Values.keyVault.csi.enabled }}
volumeMounts:
  - name: secrets-store
    mountPath: /mnt/secrets-store
    readOnly: true
{{- end }}
{{- end -}}

{{- define "redacta.secretVolumes" -}}
{{- if .root.Values.keyVault.csi.enabled }}
volumes:
  - name: secrets-store
    csi:
      driver: secrets-store.csi.k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: {{ include "redacta.secretProviderClassName" . | quote }}
{{- end }}
{{- end -}}

{{- define "redacta.defaultContainerSecurityContext" -}}
securityContext:
  runAsNonRoot: true
  allowPrivilegeEscalation: false
  capabilities:
    drop:
      - ALL
  seccompProfile:
    type: RuntimeDefault
{{- end -}}
