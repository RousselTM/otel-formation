from opentelemetry import trace, metrics
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.metrics import MeterProvider
from opentelemetry.sdk.metrics.export import PeriodicExportingMetricReader
from opentelemetry.exporter.otlp.proto.grpc.metric_exporter import OTLPMetricExporter
import logging
from opentelemetry._logs import set_logger_provider
from opentelemetry.sdk._logs import LoggerProvider, LoggingHandler
from opentelemetry.sdk._logs.export import BatchLogRecordProcessor
from opentelemetry.exporter.otlp.proto.grpc._log_exporter import OTLPLogExporter

# Configuration de la ressource (Nom du service)
resource = Resource.create({"service.name": "test-python-grpc"})

# 1. Configuration des TRACES
tracer_provider = TracerProvider(resource=resource)
tracer_provider.add_span_processor(BatchSpanProcessor(OTLPSpanExporter(endpoint="http://localhost:4317", insecure=True)))
trace.set_tracer_provider(tracer_provider)
tracer = trace.get_tracer(__name__)

# 2. Configuration des MÉTRIQUES
metric_reader = PeriodicExportingMetricReader(OTLPMetricExporter(endpoint="http://localhost:4317", insecure=True))
meter_provider = MeterProvider(resource=resource, metric_readers=[metric_reader])
metrics.set_meter_provider(meter_provider)
meter = metrics.get_meter(__name__)
counter = meter.create_counter("grpc_requests_total", description="Nombre de requêtes gRPC")

# 3. Configuration des LOGS
logger_provider = LoggerProvider(resource=resource)
logger_provider.add_log_record_processor(BatchLogRecordProcessor(OTLPLogExporter(endpoint="http://localhost:4317", insecure=True)))
set_logger_provider(logger_provider)
handler = LoggingHandler(level=logging.NOTSET, logger_provider=logger_provider)
logger = logging.getLogger("grpc-logger")
logger.addHandler(handler)

# --- EXECUTION DU TEST ---
with tracer.start_as_current_span("test-span-grpc"):
    counter.add(1, {"env": "dev"})
    logger.error("Ceci est un log d'erreur envoyé via gRPC à Alloy-1")
    print("Données gRPC envoyées.")

# Flush pour s'assurer que tout est envoyé avant la fin du script
tracer_provider.shutdown()
meter_provider.shutdown()
logger_provider.shutdown()