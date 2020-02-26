#ifdef __OBJC__
#import <UIKit/UIKit.h>
#else
#ifndef FOUNDATION_EXPORT
#if defined(__cplusplus)
#define FOUNDATION_EXPORT extern "C"
#else
#define FOUNDATION_EXPORT extern
#endif
#endif
#endif

#import "OSCache.h"

FOUNDATION_EXPORT double OSCacheVersionNumber;
FOUNDATION_EXPORT const unsigned char OSCacheVersionString[];

