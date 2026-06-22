{{- define "tw.name" -}}
{{- default .Chart.Name .Values.wiki.name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "tw.fullname" -}}
{{- if .Values.wiki.name }}
{{- .Values.wiki.name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}

{{- define "tw.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "tw.labels" -}}
helm.sh/chart: {{ include "tw.chart" . }}
{{ include "tw.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{- define "tw.selectorLabels" -}}
app.kubernetes.io/name: {{ include "tw.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
