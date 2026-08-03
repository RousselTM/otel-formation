#!/bin/bash

# Constantes
ENDPOINT="localhost:4317"

# Vérification de la présence de grpcurl
if ! command -v grpcurl &> /dev/null; then
    echo "Erreur : l'outil 'grpcurl' n'est pas installé."
    echo "Vous pouvez l'installer via : https://github.com/fullstorydev/grpcurl"
    exit 1
fi

# Génération de variables pour simuler l'exécution
NOW_NANO="$(date +%s)000000000"
TRACE_ID=$(openssl rand -hex 16)
SPAN_ID=$(openssl rand -hex 8)

echo "Envoi des données via gRPC (JSON -> Protobuf) vers Alloy..."

# 1. TRACES
grpcurl -plaintext -d @ "$ENDPOINT" opentelemetry.proto.collector.trace.v1.TraceService/Export <<EOF
{
  "resourceSpans": [
    {
      "resource": {
        "attributes": [
          { "key": "service.name", "value": { "stringValue": "test-bash-grpc" } }
        ]
      },
      "scopeSpans": [
        {
          "spans": [
            {
              "traceId": "${TRACE_ID}",
              "spanId": "${SPAN_ID}",
              "name": "test-span-grpc",
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
grpcurl -plaintext -d @ "$ENDPOINT" opentelemetry.proto.collector.metrics.v1.MetricsService/Export <<EOF
{
  "resourceMetrics": [
    {
      "resource": {
        "attributes": [
          { "key": "service.name", "value": { "stringValue": "test-bash-grpc" } }
        ]
      },
      "scopeMetrics": [
        {
          "metrics": [
            {
              "name": "grpc_requests_total",
              "description": "Nombre de requêtes gRPC",
              "sum": {
                "dataPoints": [
                  {
                    "attributes": [
                      { "key": "env", "value": { "stringValue": "dev" } }
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
grpcurl -plaintext -d @ "$ENDPOINT" opentelemetry.proto.collector.logs.v1.LogsService/Export <<EOF
{
  "resourceLogs": [
    {
      "resource": {
        "attributes": [
          { "key": "service.name", "value": { "stringValue": "test-bash-grpc" } }
        ]
      },
      "scopeLogs": [
        {
          "logRecords": [
            {
              "timeUnixNano": "${NOW_NANO}",
              "severityNumber": 17,
              "severityText": "ERROR",
              "body": { "stringValue": "Ceci est un log d'erreur envoyé via gRPC à Alloy-1" }
            }
          ]
        }
      ]
    }
  ]
}
EOF
echo -e "\n[OK] Logs envoyés"
echo "Données gRPC envoyées."