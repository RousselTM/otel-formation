/**
 * Initialisation OpenTelemetry pour le navigateur (Frontend JS)
 */

import { WebTracerProvider } from '@opentelemetry/sdk-trace-web';
import { SimpleSpanProcessor, BatchSpanProcessor } from '@opentelemetry/sdk-trace-base';
import { OTLPTraceExporter } from '@opentelemetry/exporter-trace-otlp-http';
import { registerInstrumentations } from '@opentelemetry/instrumentation';
import { FetchInstrumentation } from '@opentelemetry/instrumentation-fetch';
import { XMLHttpRequestInstrumentation } from '@opentelemetry/instrumentation-xml-http-request';
import { Resource } from '@opentelemetry/resources';
import { SemanticResourceAttributes } from '@opentelemetry/semantic-conventions';

// 1. Configuration des paramètres principaux
const OTLP_COLLECTOR_URL = 'http://localhost:4318/v1/traces';
const SERVICE_NAME = 'meteo-app-js';

// Expression régulière des domaines backends vers lesquels propager 'traceparent'
const BACKEND_URL_PATTERNS = [
  /localhost:8090/
];

// 2. Initialisation du Provider de Traces Web
const provider = new WebTracerProvider({
  resource: new Resource({
    [SemanticResourceAttributes.SERVICE_NAME]: SERVICE_NAME,
  }),
});

// 3. Configuration de l'exportateur OTLP HTTP
const exporter = new OTLPTraceExporter({
  url: OTLP_COLLECTOR_URL,
});

// Pour le débogage, SimpleSpanProcessor envoie les spans immédiatement.
// En production, il est préférable d'utiliser BatchSpanProcessor pour optimiser les performances.
provider.addSpanProcessor(new SimpleSpanProcessor(exporter));
// provider.addSpanProcessor(new BatchSpanProcessor(exporter));
provider.register();

// 4. Auto-instrumentation de fetch() et XMLHttpRequest
registerInstrumentations({
  instrumentations: [
    new FetchInstrumentation({
      propagateTraceHeaderCorsUrls: BACKEND_URL_PATTERNS,
      clearTimingResources: true,
      // Ajout des attributs HTTP sur le span pour un meilleur contexte
      applyCustomAttributesOnSpan: (span, request, result) => {
        span.setAttributes({
          'http.url': result.url,
          'http.status_code': result.status,
          'page.url': window.location.pathname,
          'rousseltm.test': "mavaleurtest",
        });
      },
    }),
    new XMLHttpRequestInstrumentation({
      propagateTraceHeaderCorsUrls: BACKEND_URL_PATTERNS,
      // Ajout des mêmes attributs pour les requêtes XHR
      applyCustomAttributesOnSpan: (span, xhr) => {
        span.setAttributes({
          'http.url': xhr.responseURL,
          'http.status_code': xhr.status,
          'page.url': window.location.pathname,
        });
      },
    }),
  ],
});

console.log('[OpenTelemetry] Initialisation du traçage Web terminée avec succès.');

// Exposer l'API OpenTelemetry à la fenêtre globale pour pouvoir l'utiliser dans les scripts des pages
import * as opentelemetry from '@opentelemetry/api';
window.opentelemetry = opentelemetry;