{{/*
Expand the name of the chart.
*/}}
{{- define "fabric-rti-mcp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "fabric-rti-mcp.fullname" -}}
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
{{- define "fabric-rti-mcp.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "fabric-rti-mcp.labels" -}}
helm.sh/chart: {{ include "fabric-rti-mcp.chart" . }}
{{ include "fabric-rti-mcp.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: server
environment: {{ .Values.environment }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "fabric-rti-mcp.selectorLabels" -}}
app.kubernetes.io/name: {{ include "fabric-rti-mcp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "fabric-rti-mcp.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "fabric-rti-mcp.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Image name with tag
*/}}
{{- define "fabric-rti-mcp.image" -}}
{{- $tag := .Values.image.tag | default .Chart.AppVersion }}
{{- printf "%s:%s" .Values.image.repository $tag }}
{{- end }}

{{/*
ConfigMap name
*/}}
{{- define "fabric-rti-mcp.configMapName" -}}
{{- printf "%s-config" (include "fabric-rti-mcp.fullname" .) }}
{{- end }}

{{/*
Secret name
*/}}
{{- define "fabric-rti-mcp.secretName" -}}
{{- printf "%s-secrets" (include "fabric-rti-mcp.fullname" .) }}
{{- end }}

{{/*
Get authentication method specific environment variables
*/}}
{{- define "fabric-rti-mcp.authEnvVars" -}}
{{- if eq .Values.config.auth.method "obo" }}
USE_OBO_FLOW: "true"
{{- else if eq .Values.config.auth.method "workloadIdentity" }}
USE_OBO_FLOW: {{ .Values.config.auth.useOboFlow | quote }}
{{- else if eq .Values.config.auth.method "servicePrincipal" }}
USE_OBO_FLOW: "false"
{{- else }}
USE_OBO_FLOW: {{ .Values.config.auth.useOboFlow | quote }}
{{- end }}
{{- end }}
