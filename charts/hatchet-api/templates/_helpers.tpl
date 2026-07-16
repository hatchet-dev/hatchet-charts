{{/*
Expand the name of the chart.
*/}}
{{- define "hatchet.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "hatchet.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "hatchet.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "hatchet.labels" -}}
helm.sh/chart: {{ include "hatchet.chart" . }}
{{ include "hatchet.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "hatchet.selectorLabels" -}}
app.kubernetes.io/name: {{ include "hatchet.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "hatchet.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "hatchet.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Name of the service account used by the bootstrap hook Jobs. It is created and
owned by the pre-install/pre-upgrade hooks (separate from the Deployment's
service account) so the hooks have RBAC before the release's normal resources
are applied.
*/}}
{{- define "hatchet.bootstrap.serviceAccountName" -}}
{{- printf "%s-bootstrap" (include "hatchet.fullname" .) }}
{{- end }}

{{/*
Hook delete policy for bootstrap Jobs. Failed Jobs are retained for debugging
when retainFailedHooks is set.
*/}}
{{- define "hatchet.bootstrap.hookDeletePolicy" -}}
{{- if .Values.retainFailedHooks -}}
before-hook-creation,hook-succeeded
{{- else -}}
before-hook-creation,hook-succeeded,hook-failed
{{- end -}}
{{- end -}}

{{/*
env list items shared by every bootstrap Job, rendered from .Values.env.
*/}}
{{- define "hatchet.bootstrap.envItems" -}}
{{- range $key, $value := .Values.env }}
- name: "{{ $key }}"
  value: "{{ $value }}"
{{- end }}
{{- end }}

{{/*
initContainer that blocks until the database is reachable.
*/}}
{{- define "hatchet.bootstrap.checkDb" -}}
- name: check-db-connection
  image: "{{ .Values.postgresImage.repository }}:{{ required "Please set a value for .Values.postgresImage.tag" .Values.postgresImage.tag }}"
  imagePullPolicy: {{ .Values.postgresImage.pullPolicy }}
  command: ['/bin/sh','-lc']
  args:
    - |
      until pg_isready -q -t 5 -d "$DATABASE_URL"; do
        echo "waiting for database"; sleep 2
      done
      psql "$DATABASE_URL" -c "SELECT 1"
  env:
{{- include "hatchet.bootstrap.envItems" . | nindent 4 }}
  envFrom:
{{ tpl (toYaml .Values.envFrom) . | indent 4 }}
{{- end }}