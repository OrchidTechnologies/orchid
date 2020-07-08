import serverless_sdk
sdk = serverless_sdk.SDK(
    org_id='orchid',
    application_name='pac',
    app_uid='7RnFxYFRZwm7x8WZvD',
    org_uid='R51dT89pkcgqBV6QGR',
    deployment_uid='98ed1779-e9ca-420f-9737-6cd0b537c36b',
    service_name='pac',
    should_log_meta=True,
    should_compress_logs=True,
    disable_aws_spans=False,
    disable_http_spans=False,
    stage_name='prod',
    plugin_version='3.6.14',
    disable_frameworks_instrumentation=False
)
handler_wrapper_kwargs = {'function_name': 'pac-prod-UpdateStatus', 'timeout': 900}
try:
    user_handler = serverless_sdk.get_user_handler('datadog_handlers/UpdateStatus.main')
    handler = sdk.handler(user_handler, **handler_wrapper_kwargs)
except Exception as error:
    e = error
    def error_handler(event, context):
        raise e
    handler = sdk.handler(error_handler, **handler_wrapper_kwargs)
