#ifndef MOBILE_MEDIAINFO_UMBRELLA_H
#define MOBILE_MEDIAINFO_UMBRELLA_H

// MediaInfo's public C API selects its wide-character symbols with these
// definitions. Keep this local to the Clang module so SwiftPM clients do not
// need to modify their project's preprocessor settings.
#ifndef UNICODE
#define UNICODE 1
#endif
#ifndef _UNICODE
#define _UNICODE 1
#endif

#include "MediaInfoDLL/MediaInfoDLL_Static.h"

#endif
