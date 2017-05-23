[![Travis](https://img.shields.io/travis/nicklockwood/OrderedDictionary.svg?maxAge=2592000)](https://travis-ci.org/nicklockwood/OrderedDictionary)
[![License](https://img.shields.io/badge/license-zlib-lightgrey.svg?maxAge=2592000)](https://opensource.org/licenses/Zlib)
[![CocoaPods](https://img.shields.io/cocoapods/p/OrderedDictionary.svg?maxAge=2592000)](https://cocoapods.org/pods/OrderedDictionary)
[![CocoaPods](https://img.shields.io/cocoapods/metrics/doc-percent/OrderedDictionary.svg?maxAge=2592000)](http://cocoadocs.org/docsets/OrderedDictionary/)
[![Twitter](https://img.shields.io/badge/twitter-@nicklockwood-blue.svg?maxAge=2592000)](http://twitter.com/nicklockwood)


Purpose
--------------

The order of objects stored in an NSDictionary is undefined. Often it is useful to be able to loop through a set of key/value pairs and have the objects returned in the order in which they were inserted. This library provides two classes, OrderedDictionary and MutableOrderedDictionary that implement that behaviour.


Supported OS & SDK Versions
-----------------------------

* Supported build target - iOS 10.0 / Mac OS 10.11 (Xcode 8.0, Apple LLVM compiler 8.0)
* Earliest supported deployment target - iOS 7.0 / Mac OS 10.9
* Earliest compatible deployment target - iOS 4.3 / Mac OS 10.6

NOTE: 'Supported' means that the library has been tested with this version. 'Compatible' means that the library should work on this OS version (i.e. it doesn't rely on any unavailable SDK features) but is no longer being tested for compatibility and may require tweaking or bug fixes to run correctly.


ARC Compatibility
------------------

OrderedDictionary requires ARC. If you wish to use OrderedDictionary in a non-ARC project, just add the -fobjc-arc compiler flag to the OrderedDictionary.m class. To do this, go to the Build Phases tab in your target settings, open the Compile Sources group, double-click OrderedDictionary.m in the list and type -fobjc-arc into the popover.

If you wish to convert your whole project to ARC, comment out the #error line in OrderedDictionary.m, then run the Edit > Refactor > Convert to Objective-C ARC... tool in Xcode and make sure all files that you wish to use ARC for (including OrderedDictionary.m) are checked.


Thread Safety
--------------

Access to an OrderedDictionary is inherently thread-safe because it is immutable. Access to a MutableOrderedDictionary is not thread-safe unless you ensure that no thread attempts to read from the dictionary whilst another is writing to it.


Installation
--------------

You can install OrderedDictionary via CocoaPods, or manually by dragging the OrderedDictionary.h and .m files into your project.


Note on Reading/Writing Property Lists
---------------------------------------

NSDictionary has a handy pair of methods `initWithContentsOfFile:` and `writeToFile:` to read/write from a plist. It's impossible to support the native implementations of these because Apple's property list parser returns an NSDictionary with the order already mangled.

As of version 1.4, however, OrderedDictionary now supports reading and writing to/from XML plist files, using a custom parser implementation. Binary and ASCII plist files are not supported.

**WARNING:** When you include an XML plist in your project, it will be compiled to a binary plist in release mode, which means that even if you are using OrderedDictionary to load such files successfully in debug mode, this may break in the final app. There are two ways to solve this:

1. Change the `Property List Output Encoding` from `binary` to `XML` or `same-as-input` in your project Build Settings, or
2. Rename your ".plist" file extension to ".xml" (or any other name of your choosing)

The second approach has the advantage that if doesn't affect other plist files besides the ones you are using with OrderedDictionary, but may make editing the file more inconvenient since Xcode won't recognise it as a property list.


Release Notes
---------------

Version 1.4

- Added support for loading/saving OrderedDictionary from an XML property list file (binary files are not supported)

Version 1.3

- Removed the ability to read and write from a property list, as this did *not* in fact preserve the order (see note above)
- Fixed some bugs with empty OrderedDictionary
- Added support for Lightweight Generics
- Properly support NSSecureCoding
- Fixed warnings on latest Xcode

Version 1.2

- Now supports NSCoding
- Added keyAtIndex: method
- Added replaceObjectAtIndex:withObject: and setObject:atIndexedSubscript: methods
- Added exchangeObjectAtIndex:withObjectAtIndex: method
- setObject:forKeyedSubscript: now works with non-string keys
- Now uses NSOrderedSet internally, for better performance
- Added unit tests

Version 1.1.1

- Added enumerateKeysAndObjectsWithIndexUsingBlock: method
- Now conforms to -Weverything warning level

Version 1.1

- Now requires ARC
- Updated to remove warnings in latest iOS
- Removed OrderedMutableDictionary variant
- Now complies to -Wextra warning level
- Added podspec

Version 1.0

- Initial release