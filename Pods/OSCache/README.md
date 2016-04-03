[![Build Status](https://travis-ci.org/nicklockwood/OSCache.svg)](https://travis-ci.org/nicklockwood/OSCache)

Purpose
--------------

**OSCache** is an open-source re-implementation of [`NSCache`](https://developer.apple.com/library/mac/documentation/cocoa/reference/NSCache_Class/Reference/Reference.html) that behaves in a predictable, debuggable way. **OSCache** is an LRU (Least-Recently-Used) cache, meaning that objects will be discarded oldest-first based on the last time they were accessed. **OSCache** will automatically empty itself in the event of a memory warning.

**OSCache** inherits from `NSCache` for convenience (so it can be used more easily as a drop-in replacement), but does not rely on any inherited behaviour.

**OSCache** implements all of the NSCache methods, but does not currently support anything relating to `NSDiscardableContent` and will always return `NO` for `evictsObjectsWithDiscardedContent` regardless of the value you set it to.


Supported OS & SDK Versions
-----------------------------

* Supported build target - iOS 9.1 / tvOS 9.1 / Mac OS 10.11 (Xcode 7.1, Apple LLVM compiler 7.1)
* Earliest supported deployment target - iOS 7.0 / tvOS 9.0 / Mac OS 10.10
* Earliest compatible deployment target - iOS 4.3 / tvOS 9.0 / Mac OS 10.6

*NOTE:* 'Supported' means that the library has been tested with this version. 'Compatible' means that the library should work on this OS version (i.e. it doesn't rely on any unavailable SDK features) but is no longer being tested for compatibility and may require tweaking or bug fixes to run correctly.


ARC Compatibility
------------------

**OSCache** requires ARC. If you wish to use **OSCache** in a non-ARC project, just add the `-fobjc-arc` compiler flag to the `OSCache.m` class. To do this, go to the Build Phases tab in your target settings, open the Compile Sources group, double-click `OSCache.m` in the list and type `-fobjc-arc` into the popover.

If you wish to convert your whole project to ARC, comment out the `#error` line in `OSCache.m`, then run the Edit > Refactor > Convert to Objective-C ARC... tool in Xcode and make sure all files that you wish to use ARC for (including `OSCache.m`) are checked.


Installation
--------------

To install **OSCache** into your app, drag the `OSCache.h` and `.m` files into your project. Create and use `OSCache` instances exactly as you would a normal `NSCache`.


Properties & Methods
---------------------

In addition to all of the inherited NSCache methods, OSCache adds the following:

    @property (nonatomic, readonly) NSUInteger count;
    
The total number of items currently stored in the cache;
    
    @property (nonatomic, readonly) totalCost;

The total cost of all items currently stored in the cache;

    - (void)enumerateKeysAndObjectsUsingBlock:(void (^)(id key, id obj, BOOL *stop))block;
    
Enumerates the keys and values stored in the cache.


OSCacheDelegate
--------------

The **OSCache** delegate now implements the `OSCacheDelegate` protocol, which is a superset of `NSCacheDelegate`. You can declare your delegate as supporting either the `OSCacheDelegate` or `NSCacheDelegate` protocols; either will work without warnings.
 
`OSCacheDelegate` adds the following optional method:

    - (BOOL)cache:(OSCache *)cache shouldEvictObject:(id)entry;

This method is called before **OSCache** evicts an object from the cache, giving you an opportunity to veto the eviction. You can use this method to implement your own cache clearing criteria (e.g. you could decide to only empty the cache if another cache is already empty).

The method will only be called as the result of adding an item to the cache, or in the event of a memory warning; it is not called if you explicitly remove and object using `-removeObjectForKey:` or `-removeAllObjects`. Objects will always be evicted in order of least recently used.


Performance
--------------

When the cache still has space in it, reading, writing and removing entries has constant time (O(1)). When the cache is full, insertion time degrades to linear (O(n)), but reading and removal remain constant.

For this reason, you should ideally size your cache so that it will never get full, but if that isn't possible, it's better to select a smaller size, as very large sizes will degrade significantly in performance when they fill up.


Release Notes
---------------

Version 1.2.1

- Fixed bug where `enumerateKeysAndObjectsUsingBlock:` returned internal wrapper instead of cached object
- Added lightweight generics annotations

Version 1.2

- Substantially improved insertion performance when cache is full
- Fixed bug where private container objects were passed to delegate instead of cached object
- Added enumeration and subscripting access for cached objects and keys

Version 1.1.2

- Added nullability annotations
- Fixed nullability error in Xcode 7
- Fixed unit tests for Xcode 6.3 + 7

Version 1.1.1

- Fixed bug where sequence numbers would not be resequenced if an overflow happens when reading from cache

Version 1.1

- Exposed the `-count` and `-totalCost` properties
- Added `OSCacheDelegate` protocol, which is a superset of `NSCacheDelegate`
- Added optional `-cache:shouldEvictObject:` delegate method
- If cache is cleared as the result of a memory warning, `-cache:shouldEvictObject:` and `-cache:willEvictObject:` is now called for each item
- Now uses sequence numbers instead of time for sorting cache items (more reliable)
- Now uses `NSLock` instead of `dispatch_semaphore` (more appropriate)
- `OSCache` still behaves as if it inherits from `NSCache`, but no longer actually does so, avoiding possible breakage if Apple changes the `NSCache` implementation in future
- Added unit tests

Version 1.0

- First Release
