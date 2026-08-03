#!/bin/bash

# Constantes
ENDPOINT_TRACES="http://localhost:4318/v1/traces"
ENDPOINT_METRICS="http://localhost:4318/v1/metrics"
ENDPOINT_LOGS="http://localhost:4318/v1/logs"

# Génération de variables pour simuler l'exécution
NOW_NANO="$(date +%s)000000000"
TRACE_ID=$(openssl rand -hex 16)
SPAN_ID=$(openssl rand -hex 8)

echo "Envoi des données via HTTP (JSON) vers Alloy..."

# 1. TRACES
curl -s -X POST "$ENDPOINT_TRACES" \
  -H "Content-Type: application/json" \
  -d @- <<EOF
{
  "resourceSpans": [
    {
      "resource": {
        "attributes": [
          { "key": "service.name", "value": { "stringValue": "test-bash-http" } }
        ]
      },
      "scopeSpans": [
        {
          "spans": [
            {
              "traceId": "${TRACE_ID}",
              "spanId": "${SPAN_ID}",
              "name": "test-span-http",
              "kind": 1,
              "startTimeUnixNano": "${NOW_NANO}",
              "endTimeUnixNano": "${NOW_NANO}"
            }
          ]
        }
      ]
    }
  ]
}
EOF
echo -e "\n[OK] Traces envoyées"

# 2. MÉTRIQUES
curl -s -X POST "$ENDPOINT_METRICS" \
  -H "Content-Type: application/json" \
  -d @- <<EOF
{
  "resourceMetrics": [
    {
      "resource": {
        "attributes": [
          { "key": "service.name", "value": { "stringValue": "test-bash-http" } }
        ]
      },
      "scopeMetrics": [
        {
          "metrics": [
            {
              "name": "http_requests_total",
              "sum": {
                "dataPoints": [
                  {
                    "attributes": [
                      { "key": "env", "value": { "stringValue": "prod" } }
                    ],
                    "asInt": "1",
                    "timeUnixNano": "${NOW_NANO}"
                  }
                ],
                "aggregationTemporality": 2,
                "isMonotonic": true
              }
            }
          ]
        }
      ]
    }
  ]
}
EOF
echo -e "\n[OK] Métriques envoyées"

# 3. LOGS
curl -s -X POST "$ENDPOINT_LOGS" \
  -H "Content-Type: application/json" \
  -d @- <<EOF
{
  "resourceLogs": [
    {
      "resource": {
        "attributes": [
          { "key": "service.name", "value": { "stringValue": "test-bash-http" } }
        ]
      },
      "scopeLogs": [
        {
          "logRecords": [
            {
              "timeUnixNano": "${NOW_NANO}",
              "severityNumber": 13,
              "severityText": "WARN",
              "body": { "stringValue": "Ceci est un log d'avertissement envoyé via HTTP à alloy-agent" }
            }
          ]
        }
      ]
    }
  ]
}
EOF
echo -e "\n[OK] Logs envoyés"
echo "Données HTTP envoyées."
