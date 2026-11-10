{{- define "brickie.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "brickie.labels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "brickie.selectorLabels" -}}
app.kubernetes.io/name: {{ .Chart.Name }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "brickie.sandboxNamespace" -}}
{{- .Values.sandbox.namespace | default .Release.Namespace -}}
{{- end -}}

{{- define "brickie.image" -}}
{{- $repo := .Values.image.repository | default (ternary "ghcr.io/hatchet-dev/brickie-fips" "ghcr.io/hatchet-dev/brickie" .Values.global.fipsMode) -}}
{{- printf "%s:%s" $repo (.Values.image.tag | default .Chart.AppVersion) -}}
{{- end -}}

{{- define "brickie.sandboxImage" -}}
{{- .Values.sandbox.image | default (ternary "ghcr.io/hatchet-dev/ubi-minimal-fips:9.8" "alpine:3" .Values.global.fipsMode) -}}
{{- end -}}
