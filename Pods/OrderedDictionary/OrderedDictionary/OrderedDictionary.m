//
//  OrderedDictionary.m
//
//  Version 1.2
//
//  Created by Nick Lockwood on 21/09/2010.
//  Copyright 2010 Charcoal Design
//
//  Distributed under the permissive zlib license
//  Get the latest version from here:
//
//  https://github.com/nicklockwood/OrderedDictionary
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//
//  1. The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//
//  2. Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//
//  3. This notice may not be removed or altered from any source distribution.
//

#import "OrderedDictionary.h"


#pragma GCC diagnostic ignored "-Wobjc-missing-property-synthesis"
#pragma GCC diagnostic ignored "-Wdirect-ivar-access"
#pragma GCC diagnostic ignored "-Wgnu"


#import <Availability.h>
#if !__has_feature(objc_arc)
#error This class requires automatic reference counting
#endif


@implementation OrderedDictionary
{
    @protected
    NSArray *_values;
    NSOrderedSet *_keys;
}

+ (instancetype)dictionaryWithContentsOfFile:(NSString *)path
{
    return [self dictionaryWithDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
}

+ (instancetype)dictionaryWithContentsOfURL:(NSURL *)url
{
    return [self dictionaryWithDictionary:[NSDictionary dictionaryWithContentsOfURL:url]];
}

- (instancetype)initWithContentsOfFile:(NSString *)path
{
    return [self initWithDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
}

- (instancetype)initWithContentsOfURL:(NSURL *)url
{
    return [self initWithDictionary:[NSDictionary dictionaryWithContentsOfURL:url]];
}

- (instancetype)initWithObjects:(NSArray *)objects forKeys:(NSArray *)keys
{
    if ((self = [super init]))
    {
        _values = [objects copy];
        _keys = [NSOrderedSet orderedSetWithArray:keys];
        
        NSParameterAssert([_keys count] == [_values count]);
    }
    return self;
}

- (instancetype)initWithObjects:(const __unsafe_unretained id [])objects forKeys:(const __unsafe_unretained id <NSCopying> [])keys count:(NSUInteger)count
{
    if ((self = [super init]))
    {
        _values = [[NSArray alloc] initWithObjects:objects count:count];
        _keys = [[NSOrderedSet alloc] initWithObjects:keys count:count];
        
        NSParameterAssert([_values count] == count);
        NSParameterAssert([_keys count] == count);
    }
    return self;
}

- (Class)classForCoder
{
    return [self class];
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super init]))
    {
        _values = [decoder decodeObjectOfClass:[NSArray class] forKey:@"values"];
        _keys = [decoder decodeObjectOfClass:[NSOrderedSet class] forKey:@"keys"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
    [coder encodeObject:_values forKey:@"values"];
    [coder encodeObject:_keys forKey:@"keys"];
}

- (instancetype)copyWithZone:(__unused NSZone *)zone
{
    return self;
}

- (instancetype)mutableCopyWithZone:(NSZone *)zone
{
    return [[MutableOrderedDictionary allocWithZone:zone] initWithDictionary:self];
}

- (NSArray *)allKeys
{
    return [_keys array];
}

- (NSArray *)allValues
{
    return [_values copy];
}

- (NSUInteger)count
{
    return [_keys count];
}

- (NSUInteger)indexOfKey:(id)key {
    return [_keys indexOfObject:key];
}

- (id)objectForKey:(id)key
{
    NSUInteger index = [_keys indexOfObject:key];
    if (index != NSNotFound)
    {
        return _values[index];
    }
    return nil;
   
}

- (NSEnumerator *)keyEnumerator
{
    return [_keys objectEnumerator];
}

- (NSEnumerator *)reverseKeyEnumerator
{
    return [_keys reverseObjectEnumerator];
}

- (NSEnumerator *)objectEnumerator
{
    return [_values objectEnumerator];
}

- (NSEnumerator *)reverseObjectEnumerator
{
    return [_values reverseObjectEnumerator];
}

- (void)enumerateKeysAndObjectsWithIndexUsingBlock:(void (^)(id key, id obj, NSUInteger idx, BOOL *stop))block
{
    [_keys enumerateObjectsUsingBlock:^(id key, NSUInteger idx, BOOL *stop) {
        block(key, self->_values[idx], idx, stop);
    }];
}

- (id)keyAtIndex:(NSUInteger)index
{
    return _keys[index];
}

- (id)objectAtIndex:(NSUInteger)index
{
    return _values[index];
}

- (id)objectAtIndexedSubscript:(NSUInteger)index
{
  return _values[index];
}

@end


@implementation MutableOrderedDictionary

#define _mutableValues ((NSMutableArray *)_values)
#define _mutableKeys ((NSMutableOrderedSet *)_keys)

+ (instancetype)dictionaryWithCapacity:(NSUInteger)count
{
    return [(MutableOrderedDictionary *)[self alloc] initWithCapacity:count];
}

- (instancetype)initWithObjects:(const __unsafe_unretained id [])objects forKeys:(const __unsafe_unretained id <NSCopying> [])keys count:(NSUInteger)count
{
    if ((self = [super init]))
    {
        _values = [[NSMutableArray alloc] initWithObjects:objects count:count];
        _keys = [[NSMutableOrderedSet alloc] initWithObjects:keys count:count];
    }
    return self;
}

- (id)initWithCapacity:(NSUInteger)capacity
{
    if ((self = [super init]))
    {
        _values = [[NSMutableArray alloc] initWithCapacity:capacity];
        _keys = [[NSMutableOrderedSet alloc] initWithCapacity:capacity];
    }
    return self;
}

- (id)init
{
    return [self initWithCapacity:0];
}

- (instancetype)initWithCoder:(NSCoder *)decoder
{
    if ((self = [super init]))
    {
        _values = [decoder decodeObjectOfClass:[NSMutableArray class] forKey:@"values"];
        _keys = [decoder decodeObjectOfClass:[NSMutableOrderedSet class] forKey:@"keys"];
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone
{
    return [[OrderedDictionary allocWithZone:zone] initWithDictionary:self];
}

- (void)addEntriesFromDictionary:(NSDictionary *)otherDictionary
{
    [otherDictionary enumerateKeysAndObjectsUsingBlock:^(id key, id obj, __unused BOOL *stop) {
        [self setObject:obj forKey:key];
    }];
}

- (void)insertObject:(id)object forKey:(id)key atIndex:(NSUInteger)index
{
    [self removeObjectForKey:key];
    [_mutableKeys insertObject:key atIndex:index];
    [_mutableValues insertObject:object atIndex:index];
}

- (void)replaceObjectAtIndex:(NSUInteger)index withObject:(id)object
{
    _mutableValues[index] = object;
}

- (void)setObject:(id)object atIndexedSubscript:(NSUInteger)index
{
    _mutableValues[index] = object;
}

- (void)exchangeObjectAtIndex:(NSUInteger)idx1 withObjectAtIndex:(NSUInteger)idx2
{
    [_mutableKeys exchangeObjectAtIndex:idx1 withObjectAtIndex:idx2];
    [_mutableValues exchangeObjectAtIndex:idx1 withObjectAtIndex:idx2];
}

- (void)removeAllObjects
{
    [_mutableKeys removeAllObjects];
    [_mutableValues removeAllObjects];
}

- (void)removeObjectAtIndex:(NSUInteger)index
{
    [_mutableKeys removeObjectAtIndex:index];
    [_mutableValues removeObjectAtIndex:index];
}

- (void)removeObjectForKey:(id)key
{
    NSUInteger index = [self->_keys indexOfObject:key];
    if (index != NSNotFound)
    {
        [self removeObjectAtIndex:index];
    }
}

- (void)removeObjectsForKeys:(NSArray *)keyArray
{
    for (id key in [keyArray copy])
    {
        [self removeObjectForKey:key];
    }
}

- (void)setDictionary:(NSDictionary *)otherDictionary
{
    [_mutableKeys removeAllObjects];
    [_mutableKeys addObjectsFromArray:[otherDictionary allKeys]];
    [_mutableValues setArray:[otherDictionary allValues]];
}

- (void)setObject:(id)object forKey:(id)key
{
    NSUInteger index = [_keys indexOfObject:key];
    if (index != NSNotFound)
    {
        _mutableValues[index] = object;
    }
    else
    {
        [_mutableKeys addObject:key];
        [_mutableValues addObject:object];
    }
}

- (void)setValue:(id)value forKey:(NSString *)key
{
    if (value)
    {
        [self setObject:value forKey:key];
    }
    else
    {
        [self removeObjectForKey:key];
    }
}

- (void)setObject:(id)object forKeyedSubscript:(id <NSCopying>)key
{
    [self setObject:object forKey:key];
}

@end
