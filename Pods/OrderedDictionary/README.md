[![Build Status](https://travis-ci.org/nicklockwood/OrderedDictionary.svg)](https://travis-ci.org/nicklockwood/OrderedDictionary)


Purpose
--------------

The order of objects stored in an NSDictionary is undefined. Often it is useful to be able to loop through a set of key/value pairs and have the objects returned in the order in which they were inserted. This library provides two classes, OrderedDictionary and MutableOrderedDictionary that implement that behaviour.


Supported OS & SDK Versions
-----------------------------

* Supported build target - iOS 8.0 / Mac OS 10.9 (Xcode 6.0, Apple LLVM compiler 6.0)
* Earliest supported deployment target - iOS 5.0 / Mac OS 10.7
* Earliest compatible deployment target - iOS 4.3 / Mac OS 10.6

NOTE: 'Supported' means that the library has been tested with this version. 'Compatible' means that the library should work on this OS version (i.e. it doesn't rely on any unavailable SDK features) but is no longer being tested for compatibility and may require tweaking or bug fixes to run correctly.


ARC Compatibility
------------------

OrderedDictionary requires ARC. If you wish to use OrderedDictionary in a non-ARC project, just add the -fobjc-arc compiler flag to the OrderedDictionary.m class. To do this, go to the Build Phases tab in your target settings, open the Compile Sources group, double-click OrderedDictionary.m in the list and type -fobjc-arc into the popover.

If you wish to convert your whole project to ARC, comment out the #error line in OrderedDictionary.m, then run the Edit > Refactor > Convert to Objective-C ARC... tool in Xcode and make sure all files that you wish to use ARC for (including OrderedDictionary.m) are checked.


Thread Safety
--------------

Access to an OrderedDictionary is inherently thread safe because it is immutable. Access to a MutableOrderedDictionary is not thread safe unless you ensure that no thread attempts to read from the dictionary whilst another is writing to it.


Installation
--------------

To install OrderedDictionary into your app, drag the OrderedDictionary.h and .m files into your project.


Release Notes
---------------

Version 1.2

- Now supports NSCoding
- Now supports reading and writing from a property list (order and mutability preserved)
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