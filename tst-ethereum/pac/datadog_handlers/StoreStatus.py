from datadog_lambda.wrapper import datadog_lambda_wrapper
from storestatus import main as main_impl
main = datadog_lambda_wrapper(main_impl)