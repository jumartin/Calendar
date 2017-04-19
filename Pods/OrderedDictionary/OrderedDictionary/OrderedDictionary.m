//
//  OrderedDictionary.m
//
//  Version 1.4
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
#pragma GCC diagnostic ignored "-Wnullable-to-nonnull-conversion"
#pragma GCC diagnostic ignored "-Wdirect-ivar-access"
#pragma GCC diagnostic ignored "-Wfloat-equal"
#pragma GCC diagnostic ignored "-Wgnu"


#import <Availability.h>
#if !__has_feature(objc_arc)
#error This class requires automatic reference counting
#endif


@implementation NSThread (XMLPlist)

- (NSDateFormatter *)XMLPlistDateFormatter
{
    static NSString *const key = @"XMLPlistDateFormatter";
    NSDateFormatter *formatter = self.threadDictionary[key];
    if (!formatter)
    {
        formatter = [[NSDateFormatter alloc] init];
        formatter.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
        formatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss'Z'";
        self.threadDictionary[key] = formatter;
    }
    return formatter;
}

@end


@interface NSObject (XMLPlistWriting)

- (NSString *)XMLPlistStringWithIndent:(NSString *)indent;

@end


@interface OrderedDictionaryXMLPlistParser : NSObject<NSXMLParserDelegate>

@property (nonatomic, readonly) OrderedDictionary *root;

- (instancetype)initWithData:(NSData *)data  root:(OrderedDictionary *)root;

@end


@implementation OrderedDictionary
{
    @protected
    NSArray *_values;
    NSOrderedSet *_keys;
}

+ (instancetype)dictionaryWithContentsOfFile:(NSString *)path
{
    NSData *data = [NSData dataWithContentsOfFile:path];
    __autoreleasing id dictionary = [[self alloc] initWithPlistData:data];
    return dictionary;
}

+ (instancetype)dictionaryWithContentsOfURL:(NSURL *)url
{
    NSData *data = [NSData dataWithContentsOfURL:url];
    __autoreleasing id dictionary = [[self alloc] initWithPlistData:data];
    return dictionary;
}

- (instancetype)initWithContentsOfFile:(NSString *)path
{
    NSData *data = [NSData dataWithContentsOfFile:path];
    return [self initWithPlistData:data];
    return nil;
}

- (instancetype)initWithContentsOfURL:(NSURL *)url
{
    NSData *data = [NSData dataWithContentsOfURL:url];
    return [self initWithPlistData:data];
    return nil;
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

- (instancetype)initWithPlistData:(NSData *)data
{
    if (data)
    {
        const void *bytes = data.bytes;
        char header[7];
        memcpy(header, &bytes, 6);
        header[6] = '\0';
        
        NSAssert(strcmp(header, "bplist") != 0, @"OrderedDictionary does not support loading binary plist files. Use an XML plist file instead. Xcode automatically converts XML plist files to binary files in built apps - see documentation for tips on how to disable this.");
        return [[OrderedDictionaryXMLPlistParser alloc] initWithData:data root:[self init]].root;
    }
    return nil;
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

- (instancetype)init
{
    if ((self = [super init]) && [self class] == [OrderedDictionary class])
    {
        static OrderedDictionary *singleton;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            singleton = self;
            self->_values = @[];
            self->_keys = [[NSOrderedSet alloc] init];
        });
        return singleton;
    }
    return self;
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

+ (BOOL)supportsSecureCoding
{
    return YES;
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
    return _keys.array;
}

- (NSArray *)allValues
{
    return [_values copy];
}

- (NSUInteger)count
{
    return _keys.count;
}

- (NSUInteger)indexOfKey:(id)key
{
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

- (NSString *)descriptionWithLocale:(nullable id)locale indent:(NSUInteger)level
{
    NSMutableString *indent = [NSMutableString string];
    for (int i = 0; i < level; i++)
    {
        [indent appendString:@"    "];
    }
    NSMutableString *string = [NSMutableString string];
    [string appendString:indent];
    [string appendString:@"{\n"];
    [self enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, __unused BOOL *stop) {
        NSString *description;
        if ([obj respondsToSelector:@selector(descriptionWithLocale:indent:)]) {
            description = [obj descriptionWithLocale:locale indent:level + 1];
        } else if ([obj respondsToSelector:@selector(descriptionWithLocale:)]) {
            description = [obj descriptionWithLocale:locale];
        } else {
            description = [obj description];
        }
        [string appendString:indent];
        [string appendFormat:@"    %@ = %@;\n", key, description];
    }];
    [string appendString:indent];
    [string appendString:@"}"];
    return string;
}

- (NSString *)XMLPlistString
{
    return [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"
            "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n"
            "<plist version=\"1.0\">\n%@\n</plist>\n",
            [self XMLPlistStringWithIndent:@""]];
}

- (BOOL)writeToFile:(NSString *)path atomically:(BOOL)useAuxiliaryFile
{
    return [[self XMLPlistString] writeToFile:path atomically:useAuxiliaryFile encoding:NSUTF8StringEncoding error:NULL];
}

- (BOOL)writeToURL:(NSURL *)url atomically:(BOOL)atomically
{
    return [[self XMLPlistString] writeToURL:url atomically:atomically encoding:NSUTF8StringEncoding error:NULL];
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

- (instancetype)initWithCapacity:(NSUInteger)capacity
{
    if ((self = [super init]))
    {
        _values = [[NSMutableArray alloc] initWithCapacity:capacity];
        _keys = [[NSMutableOrderedSet alloc] initWithCapacity:capacity];
    }
    return self;
}

- (instancetype)init
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
    [_mutableKeys addObjectsFromArray:otherDictionary.allKeys];
    [_mutableValues setArray:otherDictionary.allValues];
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

- (void)setObject:(id)object forKeyedSubscript:(id)key
{
    [self setObject:object forKey:key];
}

@end


@implementation NSObject (XMLPlistWriting)

- (NSString *)XMLPlistStringWithIndent:(__unused NSString *)indent
{
    NSLog(@"%@ is not a supported property list type.", self.classForCoder);
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

@end


@implementation NSString (XMLPlistWriting)

- (NSString *)XMLEscapedString
{
    return [[[self stringByReplacingOccurrencesOfString:@"&" withString:@"&amp;"]
             stringByReplacingOccurrencesOfString:@"<" withString:@"&lt;"]
            stringByReplacingOccurrencesOfString:@">" withString:@"&gt;"];
}

- (NSString *)XMLPlistStringWithIndent:(__unused NSString *)indent
{
    return [NSString stringWithFormat:@"<string>%@</string>", [self XMLEscapedString]];
}

@end


@implementation NSNumber (XMLPlistWriting)

- (NSString *)XMLPlistStringWithIndent:(__unused NSString *)indent
{
    if ((__bridge CFBooleanRef)self == kCFBooleanTrue)
    {
        return @"<true/>";
    }
    else if ((__bridge CFBooleanRef)self == kCFBooleanFalse)
    {
        return @"<false/>";
    }
    else if (self.doubleValue != (double)self.integerValue)
    {
        return [NSString stringWithFormat:@"<real>%@</real>", self];
    }
    else
    {
        return [NSString stringWithFormat:@"<integer>%@</integer>", self];
    }
}

@end


@implementation NSDate (XMLPlistWriting)

- (NSString *)XMLPlistStringWithIndent:(__unused NSString *)indent
{
    NSDateFormatter *formatter = [[NSThread currentThread] XMLPlistDateFormatter];
    return [NSString stringWithFormat:@"<date>%@</date>", [formatter stringFromDate:self]];
}

@end


@implementation NSData (XMLPlistWriting)

- (NSString *)XMLPlistStringWithIndent:(NSString *)indent
{
    NSString *base64 = [self base64EncodedStringWithOptions:(NSDataBase64EncodingOptions)0];
    return [NSString stringWithFormat:@"<data>\n%@%@\n%@</data>", indent, base64, indent];
}

@end


@implementation NSArray (XMLPlistWriting)

- (NSString *)XMLPlistStringWithIndent:(NSString *)indent
{
    NSMutableString *xml = [NSMutableString string];
    [xml appendString:@"<array>\n"];
    NSString *subindent = [indent stringByAppendingString:@"\t"];
    for (id value in self)
    {
        [xml appendString:subindent];
        [xml appendString:[value XMLPlistStringWithIndent:subindent]];
        [xml appendString:@"\n"];
    }
    [xml appendString:indent];
    [xml appendString:@"</array>"];
    return xml;
}

@end


@implementation NSDictionary (XMLPlistWriting)

- (NSString *)XMLPlistStringWithIndent:(NSString *)indent
{
    NSMutableString *xml = [NSMutableString string];
    [xml appendString:@"<dict>\n"];
    NSString *subindent = [indent stringByAppendingString:@"\t"];
    [self enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull value, __unused BOOL *stop) {
        [xml appendString:subindent];
        [xml appendFormat:@"<key>%@</key>\n", [[key description] XMLEscapedString]];
        [xml appendString:subindent];
        [xml appendString:[value XMLPlistStringWithIndent:subindent]];
        [xml appendString:@"\n"];
    }];
    [xml appendString:indent];
    [xml appendString:@"</dict>"];
    return xml;
}

@end


@implementation OrderedDictionaryXMLPlistParser
{
    NSDateFormatter *_formatter;
    NSMutableArray *_valueStack;
    NSMutableArray *_keyStack;
    NSString *_text;
    BOOL _failed;
}

- (instancetype)initWithData:(NSData *)data root:(OrderedDictionary *)root
{
    if ((self = [super init]))
    {
        _root = [root isKindOfClass:[MutableOrderedDictionary class]] ? root : nil;
        _keyStack = [NSMutableArray array];
        NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];
        parser.delegate = self;
        [parser parse];
    }
    return self;
}

- (void)failWithError:(NSString *)error
{
    NSLog(@"OrderedDictionary XML parsing error: %@", error);
    _failed = YES;
    _root = nil;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(nonnull NSString *)elementName namespaceURI:(__unused NSString *)namespaceURI qualifiedName:(__unused NSString *)qName attributes:(__unused NSDictionary<NSString *, NSString *> *)attributeDict
{
    if ([elementName isEqualToString:@"dict"])
    {
        if (_valueStack == nil)
        {
            _valueStack = [NSMutableArray arrayWithObject:_root ?: [MutableOrderedDictionary dictionary]];
        }
        else
        {
            [_valueStack addObject:[MutableOrderedDictionary dictionary]];
        }
    }
    else if (![elementName isEqualToString:@"plist"] && _valueStack == nil)
    {
        [self failWithError:@"Root element was not a dictionary."];
        [parser abortParsing];
        return;
    }
    else if ([elementName isEqualToString:@"array"])
    {
        [_valueStack addObject:[NSMutableArray array]];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(__unused NSString *)namespaceURI qualifiedName:(__unused NSString *)qName
{
    id value = [_text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    _text = nil;
    
    if ([elementName isEqualToString:@"key"])
    {
        [_keyStack addObject:value ?: @""];
        return;
    }
    
    if ([elementName isEqualToString:@"string"])
    {
        // Do nothing
    }
    else if ([elementName isEqualToString:@"real"])
    {
        value = @([value doubleValue]);
    }
    else if ([elementName isEqualToString:@"integer"])
    {
        value = @([value integerValue]);
    }
    else if ([elementName isEqualToString:@"date"])
    {
        if (!_formatter)
        {
            _formatter = [[NSThread currentThread] XMLPlistDateFormatter];
        }
        NSString *dateString = value;
        if (!(value = [_formatter dateFromString:dateString]))
        {
            [self failWithError:[NSString stringWithFormat:@"Unabled to parse date string: %@", dateString]];
            [parser abortParsing];
            return;
        }
    }
    else if ([elementName isEqualToString:@"data"])
    {
        NSData *data = [value dataUsingEncoding:NSUTF8StringEncoding];
        if (!(value = [[NSData alloc] initWithBase64EncodedData:data options:NSDataBase64DecodingIgnoreUnknownCharacters]))
        {
            [self failWithError:@"Unabled to parse data."];
            [parser abortParsing];
            return;
        }
    }
    else if ([elementName isEqualToString:@"true"])
    {
        value = @YES;
    }
    else if ([elementName isEqualToString:@"false"])
    {
        value = @NO;
    }
    else if ([elementName isEqualToString:@"dict"] || [elementName isEqualToString:@"array"])
    {
        value = [_valueStack.lastObject copy];
        [_valueStack removeLastObject];
    }
    else if ([elementName isEqualToString:@"plist"])
    {
        return;
    }
    
    id top = _valueStack.lastObject;
    if ([top isKindOfClass:[MutableOrderedDictionary class]])
    {
        NSString *key = _keyStack.lastObject;
        ((MutableOrderedDictionary *)top)[key] = value;
        [_keyStack removeLastObject];
    }
    else if ([top isKindOfClass:[NSArray class]])
    {
        [(NSMutableArray *)top addObject:value];
    }
    else if (_root == nil && !_failed)
    {
        _root = [value copy];
    }
}

- (void)parser:(__unused NSXMLParser *)parser foundCharacters:(NSString *)string
{
    _text = [_text ?: @"" stringByAppendingString:string];
}

@end
