{{- define "hsm-sim.image" }}
{{ default (printf "%s%s" .Values.global.registry_host .Values.registry_name) .Values.image.registry }}{{ .Values.image.repository }}
{{- if .Values.image.tag }}:{{ .Values.image.tag }}{{ end }}
{{- if .Values.image.digest }}@{{ .Values.image.digest }}{{ end }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "hsm-sim.labels" -}}
{{ include "hsm-sim.selectorLabels" . }}
app.kubernetes.io/component: hsm-sim
app.kubernetes.io/version: "{{ .Values.image.tag }}"
{{- end }}

{{/*
Selector labels
*/}}
{{- define "hsm-sim.selectorLabels" -}}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/name: hsm-sim
{{- end }}
