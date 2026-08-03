from opentelemetry import trace, metrics
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.http.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
from opentelemetry.exporter.otlp.proto.http.metric_exporter import OTLPMetricExporter
import logging
from opentelemetry._logs import set_logger_provider
from opentelemetry.sdk._logs import LoggerProvider, LoggingHandler
from opentelemetry.sdk._logs.export import BatchLogRecordProcessor
from opentelemetry.exporter.otlp.proto.http._log_exporter import OTLPLogExporter

resource = Resource.create({"service.name": "test-python-http"})

# 1. TRACES (Endpoint HTTP)
tracer_provider = TracerProvider(resource=resource)
tracer_provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter(endpoint="http://localhost:4318/v1/traces")))
trace.set_tracer_provider(tracer_provider)
tracer = trace.get_tracer(__name__)

# 2. MÉTRIQUES (Endpoint HTTP)
metric_reader = PeriodicExportingMetricReader(OTLPMetricExporter(endpoint="http://localhost:4318/v1/metrics"))
meter_provider = MeterProvider(resource=resource, metric_readers=[metric_reader])
metrics.set_meter_provider(meter_provider)
meter = metrics.get_meter(__name__)
counter = meter.create_counter("http_requests_total")

# 3. LOGS (Endpoint HTTP)
logger_provider = LoggerProvider(resource=resource)
logger_provider.add_log_record_processor(BatchLogRecordProcessor(OTLPLogExporter(endpoint="http://localhost:4318/v1/logs")))
set_logger_provider(logger_provider)
handler = LoggingHandler(level=logging.NOTSET, logger_provider=logger_provider)
logger = logging.getLogger("http-logger")
logger.addHandler(handler)

# --- EXECUTION DU TEST ---
with tracer.start_as_current_span("test-span-http"):
    counter.add(1, {"env": "prod"})
    logger.warning("Ceci est un log d'avertissement envoyé via HTTP à Alloy-1")
    print("Données HTTP envoyées.")

tracer_provider.shutdown()
meter_provider.shutdown()
logger_provider.shutdown()