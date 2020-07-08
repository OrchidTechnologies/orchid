from datadog_lambda.wrapper import datadog_lambda_wrapper
from status import main as main_impl
main = datadog_lambda_wrapper(main_impl)