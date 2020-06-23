import os

from datadog_lambda.metric import lambda_metric
from utils import configure_logging, is_true


configure_logging(level="DEBUG")


def metric(metric_name: str, value: float, timestamp=None, tags=None):
    if is_true(os.environ.get('ENABLE_MONITORING', '')):
        lambda_metric(
            metric_name=metric_name,
            value=value,
            timestamp=timestamp,
            tags=tags,
        )