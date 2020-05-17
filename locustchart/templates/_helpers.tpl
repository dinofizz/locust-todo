{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}

{{- define "locust.fullname" -}}
{{- printf "%s-%s" .Release.Name "locust" | trunc 63 -}}
{{- end -}}

{{- define "locust.master-service-web" -}}
{{- printf "%s-%s" .Release.Name "master-service-web" | trunc 63 -}}
{{- end -}}

{{- define "locust.master-service-comm" -}}
{{- printf "%s-%s" .Release.Name "master-service-comm" | trunc 63 -}}
{{- end -}}

{{- define "locust.master" -}}
{{- printf "%s-%s" .Release.Name "master" | trunc 63 -}}
{{- end -}}

{{- define "locust.worker" -}}
{{- printf "%s-%s" .Release.Name "worker" | trunc 63 -}}
{{- end -}}

{{- define "locust.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "locust.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "locust.labels" -}}
helm.sh/chart: {{ include "locust.chart" . }}
{{ include "locust.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "locust.selectorLabels" -}}
app.kubernetes.io/name: {{ include "locust.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "locust.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "locust.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}
