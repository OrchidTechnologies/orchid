#ifdef __MINGW32__
#define RTC_EXPORT_TEMPLATE_DECLARE(export) export
#define RTC_EXPORT_TEMPLATE_DEFINE(export)
#else
#include_next "rtc_base/system/rtc_export_template.h"
#endif
