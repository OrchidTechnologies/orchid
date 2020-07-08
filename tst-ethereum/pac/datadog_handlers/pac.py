from datadog_lambda.wrapper import datadog_lambda_wrapper
from handler import apple as apple_impl
apple = datadog_lambda_wrapper(apple_impl)
from handler import main as main_impl
main = datadog_lambda_wrapper(main_impl)