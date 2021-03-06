//
// NSObjects+PDIEntity.m
//
// Copyright (c) 2012 - 2015 Karl-Johan Alm (http://github.com/kallewoof)
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "NSObjects+PDIEntity.h"
#import "PDString.h"
#import "PDNumber.h"
#import "PDArray.h"
#import "PDDictionary.h"
#import "pd_internal.h"

@implementation NSDictionary (PDIEntity)

- (const char *)PDFString
{
    id value;
    NSMutableString *str = [NSMutableString stringWithString:@"<<"];
    for (NSString *key in [self allKeys]) {
        [str appendFormat:@"/%@ ", key];

        value = self[key];
        if ([value conformsToProtocol:@protocol(PDIEntity)]) {
            [str appendFormat:@"%s", [value PDFString]];
        } else {
            [str appendFormat:@"%@", value];
        }
    }
    [str appendFormat:@">>"];
    
    return [str cStringUsingEncoding:NSUTF8StringEncoding];
}

- (void *)PDValue
{
    PDDictionaryRef dict = PDDictionaryCreate();
    for (NSString *key in self.allKeys) {
        void *pdv;
        id value = self[key];
        if ([value conformsToProtocol:@protocol(PDIEntity)]) {
            pdv = [value PDValue];
        } else {
            pdv = [[value description] PDValue];
        }
        PDDictionarySet(dict, [key cStringUsingEncoding:NSUTF8StringEncoding], pdv);
    }
    return PDAutorelease(dict);
}

@end

@implementation NSArray (PDIEntity)

+ (NSArray *)arrayFromPDRect:(PDRect)rect
{
    return @[@(rect.a.x), @(rect.a.y), @(rect.b.x), @(rect.b.y)];
}

- (const char *)PDFString
{
    NSMutableString *str = [NSMutableString stringWithString:@"["];
    for (id value in self) {
        if ([value conformsToProtocol:@protocol(PDIEntity)]) {
            [str appendFormat:@" %s", [value PDFString]];
        } else {
            [str appendFormat:@" %@", value];
        }
    }
    [str appendFormat:@" ]"];
    
    return [str cStringUsingEncoding:NSUTF8StringEncoding];
}

- (void *)PDValue
{
    PDArrayRef array = PDArrayCreateWithCapacity(self.count);
    for (id v in self) {
        if ([v conformsToProtocol:@protocol(PDIEntity)]) {
            PDArrayAppend(array, [v PDValue]);
        } else {
            PDArrayAppend(array, [[v description] PDValue]);
        }
    }
    return PDAutorelease(array);
}

@end

static NSDateFormatter *dateTimeStringFormatter()
{
    static NSDateFormatter *df = nil;
    if (! df) {
        df = [[NSDateFormatter alloc] init];
        df.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
        [df setFormatterBehavior:NSDateFormatterBehavior10_4];
        [df setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss"];
    }
    return df;
}

static NSDateFormatter *dateTimeString2Formatter()
{
    static NSDateFormatter *df = nil;
    if (! df) {
        df = [[NSDateFormatter alloc] init];
        df.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
        [df setFormatterBehavior:NSDateFormatterBehavior10_4];
        [df setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ssZZZZZ"];
    }
    return df;
}

static NSDateFormatter *dateTimeString3Formatter()
{
    static NSDateFormatter *df = nil;
    if (! df) {
        df = [[NSDateFormatter alloc] init];
        df.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
        [df setFormatterBehavior:NSDateFormatterBehavior10_4];
        [df setDateFormat:@"'D:'yyyyMMddHHmmss"];
    }
    return df;
}

static NSDateFormatter *dateTimeString4Formatter()
{
    static NSDateFormatter *df = nil;
    if (! df) {
        df = [[NSDateFormatter alloc] init];
        df.timeZone = [NSTimeZone timeZoneWithName:@"UTC"];
        [df setFormatterBehavior:NSDateFormatterBehavior10_4];
        [df setDateFormat:@"'D:'yyyyMMddHHmmssZ"];
    }
    return df;
}

@implementation NSDate (PDIEntity)

- (const char *)PDFString
{
    NSDateFormatter *df = dateTimeString3Formatter();
    return [[NSString stringWithFormat:@"(%@)", [df stringFromDate:self]] cStringUsingEncoding:NSUTF8StringEncoding];
}

- (void *)PDValue
{
    return PDStringWithCString(strdup([self PDFString]));
}

- (NSString *)datetimeString
{
    return [dateTimeStringFormatter() stringFromDate:self];
}

@end

@implementation NSString (PDIEntity)

- (NSDate *)dateFromDatetimeString
{
    NSDate *d = [dateTimeStringFormatter() dateFromString:self];
    if (! d) d = [dateTimeString2Formatter() dateFromString:self];
    if (! d) d = [dateTimeString3Formatter() dateFromString:self];
    if (! d) d = [dateTimeString4Formatter() dateFromString:self];
    if (! d && self.length > 16) {
        // we have something weird after the date/time most likely. 
        d = [[self substringToIndex:16] dateFromDatetimeString];
    }
    return d;
}

- (NSString *)datetimeString
{
    if (! [self hasPrefix:@"D:"]) {
        PDError("datetimeString requested from non-date formatted string '%s'", self.UTF8String);
    }
    return self;
}

+ (NSString *)stringWithPDFString:(const char *)PDFString
{
    NSString *str = [[NSString alloc] initWithCString:PDFString encoding:NSUTF8StringEncoding];
    if (str == nil) {
        str = [[NSString alloc] initWithCString:PDFString encoding:NSASCIIStringEncoding];
    }
    if (str == nil) {
        [NSException raise:@"PDUnknownEncodingException" format:@"PDF string was using an unknown encoding."];
    }
    return str;
}

+ (id)objectWithPDString:(PDStringRef)PDString
{
    return (PDStringGetType(PDString) == PDStringTypeName
            ? [PDIName nameWithPDString:PDString]
            : [self stringWithPDFString:PDStringEscapedValue(PDString, false, NULL)]);
}

- (NSString *)PXUString
{
    NSString *s = [[self hasPrefix:@"<"] && [self hasSuffix:@">"] ? [self substringWithRange:(NSRange){1,self.length-2}] : self lowercaseString];
    while (s.length < 32) s = [@"0" stringByAppendingString:s];

    return [NSString stringWithFormat:@"uuid:%@-%@-%@-%@-%@", 
            [s substringWithRange:(NSRange){ 0,8}], 
            [s substringWithRange:(NSRange){ 8,4}], 
            [s substringWithRange:(NSRange){12,4}], 
            [s substringWithRange:(NSRange){16,4}], 
            [s substringWithRange:(NSRange){20,12}] 
            ];
}

- (NSString *)stringByRemovingPDFControlCharacters
{
    if (self.length > 1 && [self characterAtIndex:0] == '(' && [self characterAtIndex:self.length-1] == ')') {
        return [self substringWithRange:(NSRange){1, self.length - 2}];
    }
    return self;
}

- (NSString *)stringByAddingPDFControlCharacters
{
    return [NSString stringWithFormat:@"(%@)", self];
}

- (const char *)PDFString
{
    return [self cStringUsingEncoding:NSUTF8StringEncoding];
}

- (void *)PDValue
{
    return PDStringWithCString(strdup([self PDFString]));
}

@end

@interface PDIName () 
@property (nonatomic, copy) NSString *s;
@end

@implementation PDIName 

+ (PDIName *)nameWithPDString:(PDStringRef)PDString
{
    PDIName *p = [[PDIName alloc] init];
    p.s = [NSString stringWithPDFString:PDStringNameValue(PDString, false)];
    return p;
}

+ (PDIName *)nameWithString:(NSString *)string
{
    PDIName *p = [[PDIName alloc] init];
    p.s = string;
    return p;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"(PDIName: %p) \"%@\"", self, _s];
}

- (const char *)PDFString
{
    return [[NSString stringWithFormat:@"/%@", self] PDFString];
}

- (void *)PDValue
{
    return PDStringWithName(strdup([_s PDFString]));
}

- (BOOL)isEqualToString:(id)object
{
    return [_s isEqualToString:object];
}

- (NSString *)string
{
    return _s;
}

@end

@implementation NSNumber (PDIEntity)

- (const char *)PDFString
{
    return [[NSString stringWithFormat:@"%@", self] PDFString];
}

- (void *)PDValue
{
    NSString *d = [NSString stringWithFormat:@"%@", self];
    if ([d rangeOfString:@"."].location != NSNotFound) {
        // real
        return PDNumberWithReal(self.doubleValue);
    }
    
//    if ([d hasPrefix:@"-"]) {
        // integer
        return PDNumberWithInteger(self.integerValue);
//    }
    
//    return PDNumberWithSize(self.unsignedIntegerValue);
}

@end
