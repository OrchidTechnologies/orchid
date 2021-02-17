#include_next "rtc_base/system/no_unique_address.h"
#if !__has_attribute(no_unique_address)
#undef RTC_NO_UNIQUE_ADDRESS
#define RTC_NO_UNIQUE_ADDRESS
#endif
