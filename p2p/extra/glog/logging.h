#include <iostream>

#define CHECK(x) if (!(x)) std::cerr
#define CHECK_EQ(x,y) if ((x)!=(y)) std::cerr
#define CHECK_GE(x,y)
#define CHECK_GT(x,y)
#define CHECK_LE(x,y)
#define CHECK_LT(x,y) if ((x)>=(y)) std::cerr
#define CHECK_NE(x,y)

#define DCHECK(x) if (!(x)) std::cerr
#define DCHECK_EQ(x,y) if ((x)!=(y)) std::cerr
#define DCHECK_GE(x,y)
#define DCHECK_GT(x,y)
#define DCHECK_LE(x,y)
#define DCHECK_LT(x,y)
#define DCHECK_NE(x,y)

#define PCHECK(x) if (!(x)) std::cerr

#define LOG_WARNING std::cerr
#define LOG_ERROR std::cerr
#define LOG_FATAL std::abort(), std::cerr
#define LOG_DFATAL std::abort(), std::cerr

#define LOG(x) LOG_ ## x
#define DLOG(x) LOG_ ## x

#define LOG_IF(x,y) if ((y)) LOG_ ## x
#define LOG_FIRST_N(x,y) std::cerr

#define PLOG_IF(x,y) if ((y)) LOG_ ## x

#define VLOG(x) if ((x)>=10) std::cerr
