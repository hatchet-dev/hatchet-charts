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
Name for one of the stable-named install Jobs, reserving room for its suffix.

hatchet.fullname already truncates at 63, so appending a suffix to it can push the result past the
63-character limit Kubernetes applies to Job names, which become label values. A 40-character
release name yields a 52-character fullname and so a 65-character worker-token name, which the API
server rejects. Truncate the prefix by the suffix length instead of after it.

Usage: include "hatchet.suffixedName" (dict "ctx" . "suffix" "-worker-token")
*/}}
{{- define "hatchet.suffixedName" -}}
{{- $max := int (sub 63 (len .suffix)) -}}
{{- printf "%s%s" (include "hatchet.fullname" .ctx | trunc $max | trimSuffix "-") .suffix -}}
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