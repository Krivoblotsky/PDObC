//
// PDIXMPTemplate.c
//
// Copyright (c) 2012 - 2014 Karl-Johan Alm (http://github.com/kallewoof)
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

#import "Pajdeg.h"
#import "PDIXMPTemplate.h"
#import "PDIXMPArchive.h"
#import "PDIXMPElement.h"
#import "NSArray+PDIXMPArchive.h"
#import "NSObjects+PDIEntity.h"

static NSArray *licenseUrls = nil;
static NSArray *licenseNames = nil;
static NSDictionary *licenseAliases = nil;
static NSArray *codedLicenses = nil;
static NSArray *licenseDefaultMajors = nil;
static BOOL ccLicense[__PDIXMPLicenseEndMarker__] = {NO, YES, YES, YES, YES, YES, YES, NO, YES, NO, NO};

@interface PDIXMPTemplate ()

@property (nonatomic, readwrite) PDIXMPLicense license;
@property (nonatomic, strong) NSString *licenseUrl;
@property (nonatomic, strong) NSString *licenseName;

@end

@implementation PDIXMPTemplate

/*
 OGL = Open Game License
 FDL = GNU Free Documentation License
 OPL = Open Publication License
 (if CC, add a CC+ field: particularly useful with NC; it's not commercial but go to this URL if you wanna buy commercial right, http://wiki.creativecommons.org/CCPlus )
 Public Domain = identified as
 CC0 = Owned by me, given as public domain
 */

NSString * const kPDIXMPLicenseCCBY = @"Attribution";
NSString * const kPDIXMPLicenseCCBYSA = @"Attribution-ShareAlike";
NSString * const kPDIXMPLicenseCCBYND = @"Attribution-NoDerivs";
NSString * const kPDIXMPLicenseCCBYNC = @"Attribution-NonCommercial";
NSString * const kPDIXMPLicenseCCBYNCSA = @"Attribution-NonCommercial-ShareAlike";
NSString * const kPDIXMPLicenseCCBYNCND = @"Attribution-NonCommercial-NoDerivs";
NSString * const kPDIXMPLicenseCC0 = @"CC0";
NSString * const kPDIXMPLicensePD = @"Public Domain";
NSString * const kPDIXMPLicenseCommercial = @"All Rights Reserved";
NSString * const kPDIXMPLicenseCustom = @"Custom";

static inline void PDIXMPTemplateSetup()
{
    licenseUrls = @[@"",
                    @"http://creativecommons.org/licenses/by/[m].0",
                    @"http://creativecommons.org/licenses/by-sa/[m].0",
                    @"http://creativecommons.org/licenses/by-nd/[m].0",
                    @"http://creativecommons.org/licenses/by-nc/[m].0",
                    @"http://creativecommons.org/licenses/by-nc-sa/[m].0",
                    @"http://creativecommons.org/licenses/by-nc-nd/[m].0",
                    @"",
                    @"http://creativecommons.org/publicdomain/zero/[m].0/legalcode",
                    @"",
                    @"",
                    ];
    
    licenseNames = @[@"Unspecified",
                     kPDIXMPLicenseCCBY,
                     kPDIXMPLicenseCCBYSA,
                     kPDIXMPLicenseCCBYND,
                     kPDIXMPLicenseCCBYNC,
                     kPDIXMPLicenseCCBYNCSA,
                     kPDIXMPLicenseCCBYNCND,
                     kPDIXMPLicenseCommercial,
                     kPDIXMPLicenseCC0,
                     kPDIXMPLicensePD,
                     kPDIXMPLicenseCustom,
                     ];
    
    licenseDefaultMajors = @[@"",
                             @"4",
                             @"4",
                             @"4",
                             @"4",
                             @"4",
                             @"4",
                             @"",
                             @"1",
                             @"",
                             @"",
                             ];
    
    licenseAliases = @{@"attribution": kPDIXMPLicenseCCBY,
                       @"attribution-sharealike": kPDIXMPLicenseCCBYSA,
                       @"attribution-noderivs": kPDIXMPLicenseCCBYND,
                       @"attribution-noncommercial": kPDIXMPLicenseCCBYNC,
                       @"attribution-noncommercial-sharealike": kPDIXMPLicenseCCBYNCSA,
                       @"attribution-noncommercial-noderivs": kPDIXMPLicenseCCBYNCND,
                       @"commercial": kPDIXMPLicenseCommercial,
                       @"public domain": kPDIXMPLicensePD,
                       @"pd": kPDIXMPLicensePD,
                       
                       @"by": kPDIXMPLicenseCCBY,
                       @"by-sa": kPDIXMPLicenseCCBYSA,
                       @"by-nd": kPDIXMPLicenseCCBYND,
                       @"by-nc": kPDIXMPLicenseCCBYNC,
                       @"by-nc-nd": kPDIXMPLicenseCCBYNCND,
                       @"by-nd-nc": kPDIXMPLicenseCCBYNCND,
                       @"by-nc-sa": kPDIXMPLicenseCCBYNCSA,
                       @"by-sa-nc": kPDIXMPLicenseCCBYNCSA,

                       @"all-rights-reserved": kPDIXMPLicenseCommercial,
                       @"cc-by-nc-nd": kPDIXMPLicenseCCBYNCND,
                       @"cc-by-nc-sa": kPDIXMPLicenseCCBYNCSA,
                       @"cc-by-nc": kPDIXMPLicenseCCBYNC,
                       @"cc-by-nd": kPDIXMPLicenseCCBYND, 
                       @"cc-by-sa": kPDIXMPLicenseCCBYSA,
                       @"cc-by": kPDIXMPLicenseCCBY,
                       @"cc-pd": kPDIXMPLicenseCC0,
                       };
    
    
    assert(licenseUrls.count==__PDIXMPLicenseEndMarker__);
    assert(licenseNames.count==__PDIXMPLicenseEndMarker__);
    assert(licenseDefaultMajors.count==__PDIXMPLicenseEndMarker__);
    
    /*
     adaptions  sharealike  commercial  code
     0          0           0           0
     1          0           0           1
     0          1           0           2       note: we consider adaptions=NO as overruling sharealike=YES
     1          1           0           3
     0          0           1           4
     1          0           1           5
     0          1           1           6       note: we consider adaptions=NO as overruling sharealike=YES
     1          1           1           7
     */
    codedLicenses = @[@(PDIXMPLicenseAttributionNonCommercialNoDerivs),
                      @(PDIXMPLicenseAttributionNonCommercial),
                      @(PDIXMPLicenseAttributionNonCommercialNoDerivs),
                      @(PDIXMPLicenseAttributionNonCommercialShareAlike),
                      @(PDIXMPLicenseAttributionNoDerivs),
                      @(PDIXMPLicenseAttribution),
                      @(PDIXMPLicenseAttributionNoDerivs),
                      @(PDIXMPLicenseAttributionShareAlike),
                      ];
}

+ (NSArray *)licenseNames
{
    if (licenseUrls == nil) PDIXMPTemplateSetup();
    return licenseNames;
}

+ (NSString *)defaultMajorVersionStringForLicense:(PDIXMPLicense)license
{
    return licenseDefaultMajors[license];
}

- (NSString *)resolvedLicenseURL
{
    return (_licenseMajorVersionString.length
            ? [_licenseUrl stringByReplacingOccurrencesOfString:@"[m]" withString:_licenseMajorVersionString]
            : [_licenseUrl stringByReplacingOccurrencesOfString:@"[m].0" withString:@""]);
}

+ (id)templateForLicense:(PDIXMPLicense)license major:(NSString *)major
{
    if (licenseUrls == nil) PDIXMPTemplateSetup();
    PDIXMPTemplate *template = [[PDIXMPTemplate alloc] init];
    template.license = license;
    template.licenseMajorVersionString = major;
    template.licenseName = licenseNames[license];
    template.licenseUrl = licenseUrls[license];
    return template;
}

+ (id)templateForLicense:(PDIXMPLicense)license
{
    return [self templateForLicense:license major:licenseDefaultMajors[license]];
}

+ (PDIXMPLicense)licenseForName:(NSString *)licenseName
{
    if (licenseUrls == nil) PDIXMPTemplateSetup();
    NSInteger index = [licenseNames indexOfObject:licenseName];
    if (index == NSNotFound) {
        // try alias
        NSString *alias = licenseAliases[licenseName.lowercaseString];
        if (alias) {
            index = [licenseNames indexOfObject:alias];
        }
    }
    return (index == NSNotFound ? PDIXMPLicenseUndefined : (PDIXMPLicense)index);
}

+ (id)templateForLicenseWithName:(NSString *)licenseName URL:(NSString *)licenseURL
{
    PDIXMPLicense license = [self licenseForName:licenseName];

    PDIXMPTemplate *template;
    if (license != PDIXMPLicenseUndefined) {
        template = [self templateForLicense:license];
    } else {
        template = [self templateForLicense:PDIXMPLicenseCustom];
        template.licenseName = licenseName;
    }
    if (licenseURL) template.licenseUrl = licenseURL;
    return template;
}

+ (id)templateWhichAllowsAdaptions:(BOOL)allowsAdaptions ifSharedAlike:(BOOL)ifSharedAlike allowsCommercialUse:(BOOL)allowsCommercialUse
{
    if (licenseUrls == nil) PDIXMPTemplateSetup();

    unsigned char code = (allowsAdaptions != 0) + ((ifSharedAlike != 0) << 1) + ((allowsCommercialUse != 0) << 2);
    /*
     adaptions  sharealike  commercial  code
     0          0           0           0
     1          0           0           1
     0          1           0           2       note: we consider adaptions=NO as overruling sharealike=YES
     1          1           0           3
     0          0           1           4
     1          0           1           5
     0          1           1           6       note: we consider adaptions=NO as overruling sharealike=YES
     1          1           1           7
     */
    return [self templateForLicense:[codedLicenses[code] intValue]];
}

+ (id)templateForXMPArchive:(PDIXMPArchive *)archive
{
    NSString *mvs, *morePerms;
    PDIXMPLicense license = [self licenseForXMPArchive:archive mvs:&mvs morePerms:&morePerms];
    if (license == PDIXMPLicenseUndefined) license = PDIXMPLicenseCommercial;
    
    PDIXMPTemplate *template = [self templateForLicense:license];
    if (mvs) template.licenseMajorVersionString = mvs;
    if (morePerms) template.morePermissions = morePerms;
    
    [archive selectRoot];
    [archive selectElement:@"x:xmpmeta"];
    [archive selectElement:@"rdf:RDF"];
    NSString *rights = [[archive findElements:@"rdf:Description"] firstAvailableElementValueForPath:@[@"dc:rights", @"rdf:Alt", @"rdf:li"]];
    if (rights) template.rights = rights;
    
    return template;
}

+ (BOOL)freeformLicense:(PDIXMPLicense)license
{
    return !ccLicense[license];
}

+ (PDIXMPLicense)licenseForXMPArchive:(PDIXMPArchive *)archive mvs:(NSString *__autoreleasing *)mvs morePerms:(NSString *__autoreleasing *)morePerms
{
    if (licenseUrls == nil) PDIXMPTemplateSetup();
    
    if (morePerms) *morePerms = nil;
    
    [archive selectRoot];
    [archive selectElement:@"x:xmpmeta"];
    [archive selectElement:@"rdf:RDF"];
    
    if ([archive selectElement:@"rdf:Description" withAttributes:@{@"xmlns:cc": @"http://creativecommons.org/ns#"}]) {
        if (morePerms && [archive selectElement:@"cc:morePermissions"]) {
            // the more permissions expression is a URL pointing to a place where permissions beyond the active license may be obtained
            *morePerms = [archive stringForAttribute:@"rdf:resource"];
            [archive selectParent];
        }
        if ([archive selectElement:@"cc:license"]) {
            // we got a CC license expression in the form of a URL
            // the URL is in the format
            //  http://creativecommons.org/licenses/LICENSE_NAME/VERSION"
            // or it is equal to
            //  http://creativecommons.org/publicdomain/zero/[m].0/legalcode
            NSString *url = [archive stringForAttribute:@"rdf:resource"];
            if (url) {
                // see which version it is
                if ([url hasSuffix:@"/legalcode"]) {
                    // latter?
                    url = [url substringToIndex:url.length - 10];
                    // -> http://creativecommons.org/publicdomain/zero/[m].0
                    // version
                    NSString *vcomp = [url lastPathComponent]; // /zero/1.0 -> 1.0
                    NSArray *mmc = [vcomp componentsSeparatedByString:@"."]; // 4.0 -> [4, 0]
                    if (mmc.count > 1) {
                        if (mvs) *mvs = mmc[0];
                    }
                    // this is CC0 if the last path comp of url (without vcomp) is "zero"
                    if ([@"zero" isEqualToString:url.stringByDeletingLastPathComponent.lastPathComponent]) {
                        return PDIXMPLicenseCC0;
                    }
                    
                }
                // get version 
                NSString *vcomp = [url lastPathComponent]; // /by/4.0 -> 4.0
                NSArray *mmc = [vcomp componentsSeparatedByString:@"."]; // 4.0 -> [4, 0]
                if (mmc.count > 1) {
                    if (mvs) *mvs = mmc[0];
                    url = [url substringToIndex:url.length - vcomp.length]; // /by/4.0 -> /by/
                    url = [url stringByAppendingString:@"[m].0"]; // /by/ -> /by/[m].0
                }
                
                // see if we have an exact match
                
                NSInteger index = [licenseUrls indexOfObject:url];
                if (index != NSNotFound) {
                    // we do; use default MVS unless one was defined above
                    if (mvs && !*mvs) *mvs = [self defaultMajorVersionStringForLicense:(PDIXMPLicense)index];
                    return (PDIXMPLicense) index;
                }
            }
            [archive selectParent];
        }
        [archive selectParent];
    }
    
    if ([archive selectElement:@"rdf:Description"]) {
        // look for a dc:rights entry
        if ([archive selectElement:@"dc:rights"] && [archive selectElement:@"rdf:Alt"] && [archive selectElement:@"rdf:li"]) {
            // <rdf:li xml:lang="x-default">Copyright © 2014, Corp. All rights reserved.</rdf:li>
            NSString *rights = [archive elementContent];
            if ([rights rangeOfString:@"all rights reserved" options:NSCaseInsensitiveSearch].location != NSNotFound) {
                if (mvs) *mvs = nil;
                return PDIXMPLicenseCommercial;
            }
        }
    }

    [archive selectRoot];
    [archive selectElement:@"x:xmpmeta"];
    [archive selectElement:@"rdf:RDF"];
    
    NSString *xmpString = [[NSString alloc] initWithData:[archive allocSubset] encoding:NSUTF8StringEncoding];
    NSRange ccRange = [xmpString rangeOfString:@"Creative Commons "];
    if (ccRange.location != NSNotFound) {
        NSString *string = [xmpString substringFromIndex:ccRange.location + ccRange.length];
        for (NSInteger i = 0; i < licenseNames.count; i++) {
            if ([string hasPrefix:licenseNames[i]]) {
                if (mvs) {
                    // use default version for license
                    *mvs = [self defaultMajorVersionStringForLicense:(PDIXMPLicense)i];
                    
                    // see if we have a version as well
                    NSInteger offset = [licenseNames[i] length] + 1;
                    if (offset + 1 < string.length) {
                        NSString *vstr = [string substringWithRange:(NSRange){offset, offset + 10 > string.length ? string.length - offset : 10}];
                        NSArray *mmc = [vstr componentsSeparatedByString:@"."];
                        if (mmc.count > 1) {
                            *mvs = mmc[0];
                        }
                    }
                }
                return (PDIXMPLicense) i;
            }
        }
    }
    
    if (mvs) *mvs = nil;
    return PDIXMPLicenseUndefined;
}

+ (NSString *)defaultRightsForLicense:(PDIXMPLicense)license major:(NSString *)major withAuthor:(NSString *)author
{
    NSInteger year = [[[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:[NSDate date]] year];
    if (major == nil || major.length == 0) major = licenseDefaultMajors[license];
    return (ccLicense[license] 
            ? [NSString stringWithFormat:@"Copyright %ld%@. Licensed to the public under Creative Commons %@ %@", (long)year, author.length > 0 ? [NSString stringWithFormat:@", %@", author] : @"", licenseNames[license], major.length ? [NSString stringWithFormat:@"%@.0", major] : @""]
            : [NSString stringWithFormat:@"Copyright %ld%@. All rights reserved.", (long)year, author.length > 0 ? [NSString stringWithFormat:@", %@", author] : @""]);
}

- (NSString *)defaultRightsWithAuthor:(NSString *)author
{
    return [PDIXMPTemplate defaultRightsForLicense:_license major:_licenseMajorVersionString withAuthor:author];
}

- (NSString *)declarationWithAuthorName:(NSString *)authorName extra:(NSDictionary *)extra
{
    if (_license == PDIXMPLicenseUndefined) return nil;
    
    NSMutableString *result = [[NSMutableString alloc] initWithCapacity:900];
    
    [result appendString:@"<?xpacket begin='' id=''?><x:xmpmeta xmlns:x='adobe:ns:meta/'>\
     <rdf:RDF xmlns:rdf='http://www.w3.org/1999/02/22-rdf-syntax-ns#'>\
     \
     "];
    
    if (_license == PDIXMPLicenseCommercial && ! extra[@"dc:rights"]) {
        NSMutableDictionary *d = extra ? extra.mutableCopy : [NSMutableDictionary dictionary];
        d[@"dc:rights"] = [PDIXMPTemplate defaultRightsForLicense:_license major:_licenseMajorVersionString withAuthor:authorName];
        extra = d;
    }
    
    if (extra) {
        [result appendString:@"<rdf:Description rdf:about=\"\"\n"];
        
        BOOL hasDC = NO; // purl.org/dc/elements/1.1/
        BOOL hasPDF = NO; // ns.adobe.com/pdf/1.3/
        BOOL hasXMP = NO; 
//        BOOL hasXMPMM = NO;
//        BOOL hasXMPRights = NO;
        BOOL hasPDFX = NO; // ns.adobe.com/pdfx/1.3/
        /*
            xmlns:dc="http://purl.org/dc/elements/1.1/"
            xmlns:pdf="http://ns.adobe.com/pdf/1.3/"
            xmlns:xmp="http://ns.adobe.com/xap/1.0/"
            xmlns:xmpMM="http://ns.adobe.com/xap/1.0/mm/"
            xmlns:xmpRights="http://ns.adobe.com/xap/1.0/rights/"
            xmlns:pdfx="http://ns.adobe.com/pdfx/1.3/">
         */
        for (NSString *k in extra.allKeys) {
            hasDC |= [k hasPrefix:@"dc:"];
            hasPDF |= [k hasPrefix:@"pdf:"];
            hasXMP |= [k hasPrefix:@"xmp:"];
            hasPDFX |= [k hasPrefix:@"pdfx:"];
        }
        if (hasDC)   [result appendString:@"xmlns:dc=\"http://purl.org/dc/elements/1.1/\"\n"];
        if (hasPDF)  [result appendString:@"xmlns:pdf=\"http://ns.adobe.com/pdf/1.3/\"\n"];
        if (hasXMP)  [result appendString:@"xmlns:xmp=\"http://ns.adobe.com/xap/1.0/\"\
                                    xmlns:xmpMM=\"http://ns.adobe.com/xap/1.0/mm/\"\
                                    xmlns:xmpRights=\"http://ns.adobe.com/xap/1.0/rights/\"\n"];
        if (hasPDFX) [result appendString:@"xmlns:pdfx=\"http://ns.adobe.com/pdfx/1.3/\""];

        [result appendString:@">\n"];
        
        NSDictionary *info;
        NSString *resource;
        for (NSString *key in extra.allKeys) {
            [result appendFormat:@"<%@>", key];
            id val = extra[key];
            if ([key hasPrefix:@"dc:"]) {
                info = nil;
                resource = nil;
                if ([val isKindOfClass:[NSDictionary class]]) {
                    // backtrack on result, removing ending >: <dc:foo> -> <dc:foo
                    [result deleteCharactersInRange:(NSRange){result.length-1,1}];
                    info = val;
                    val = info[@"value"];
                    resource = info[@"source"];
                    if (resource) [result appendFormat:@" rdf:resource=\"%@\"", resource];
                    
                    // put > back again
                    [result appendString:@">"];
                }
                
                if ([val isKindOfClass:[NSString class]]) {
                    [result appendFormat:@"<rdf:Alt><rdf:li xml:lang=\"x-default\">%@</rdf:li></rdf:Alt>", [val stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
                }
                else if ([val isKindOfClass:[NSArray class]]) {
                    [result appendString:@"<rdf:Seq>\n"];
                    for (NSString *v in val) {
                        [result appendFormat:@"<rdf:li xml:lang=\"x-default\">%@</rdf:li>\n", [v stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
                    }
                    [result appendString:@"</rdf:Seq>\n"];
                }
                else if ([val isKindOfClass:[NSSet class]]) {
                    [result appendString:@"<rdf:Bag>\n"];
                    for (NSString *v in val) {
                        [result appendFormat:@"<rdf:li xml:lang=\"x-default\">%@</rdf:li>\n", [v stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
                    }
                    [result appendString:@"</rdf:Bag>\n"];
                }
            } 
            else {
                [result appendFormat:@"%@", val];
            }
            [result appendFormat:@"</%@>\n", key];
        }
        
        [result appendString:@"</rdf:Description>\n"];
    }

    if (ccLicense[_license]) {
        [result appendString:@"<rdf:Description rdf:about=''\
                         xmlns:xapRights='http://ns.adobe.com/xap/1.0/rights/'>\
            <xapRights:Marked>True</xapRights:Marked> \
        </rdf:Description>\
        \
        <rdf:Description rdf:about=''\
                         xmlns:dc='http://purl.org/dc/elements/1.1/'>\
            <dc:rights>\
                <rdf:Alt>\
                    <rdf:li xml:lang='x-default' >"];
        [result appendString:[PDIXMPTemplate defaultRightsForLicense:_license major:_licenseMajorVersionString withAuthor:authorName]];
        [result appendString:@".</rdf:li>\
                </rdf:Alt>\
            </dc:rights>\
        </rdf:Description>\
        \
        <rdf:Description rdf:about=''\
                         xmlns:cc='http://creativecommons.org/ns#'>\
            <cc:license rdf:resource='"];
        [result appendString:[self resolvedLicenseURL]];
        if (_morePermissions) {
            [result appendString:@"'/>\
            <cc:morePermissions rdf:resource='"];
            [result appendString:_morePermissions];
        }
        [result appendString:@"'/>\
        </rdf:Description>\
        \
         "];
    }

    [result appendString:@"</rdf:RDF>\
     </x:xmpmeta><?xpacket end='r'?>"];
    
    return result;
}

- (void)removeFromArchive:(PDIXMPArchive *)archive
{
    [archive selectRoot];
    if ([archive selectElement:@"x:xmpmeta"]) {
        if ([archive selectElement:@"rdf:RDF"]) {
    
            id rdfRoot = [archive cursorReference];
            assert(rdfRoot);
    
            [[archive findElements:@"rdf:Description"] makeObjectsPerformSelector:@selector(removeFromParent)];
        }
    }
}

- (void)applyToArchive:(PDIXMPArchive *)archive withAuthorName:(NSString *)authorName extra:(NSDictionary *)extra
{
    if (_license == PDIXMPLicenseUndefined) {
        [self removeFromArchive:archive];
        return;
    }
    
    [archive selectRoot];
    BOOL okay = [archive selectElement:@"x:xmpmeta"];
    NSAssert(okay, @"No x:xmpmeta key in PDIXMPArchive!");
    okay = [archive selectElement:@"rdf:RDF"];
    NSAssert(okay, @"No rdf:RDF key in PDIXMPArchive! They should be generated automagically!");
    
    id rdfRoot = [archive cursorReference];
    assert(rdfRoot);
    
    // to avoid duplicates due to differing attribute sets, we remove all pdf:Description entries from the XMP here
    [[archive findElements:@"rdf:Description"] makeObjectsPerformSelector:@selector(removeFromParent)];
    
    if (_license != PDIXMPLicenseCommercial) {
        [archive createElement:@"rdf:Description" withAttributes:@{@"rdf:about":       @"", 
                                                                   @"xmlns:xapRights": @"http://ns.adobe.com/xap/1.0/rights/"}]; {
            [archive createElement:@"xapRights:Marked"]; {
                [archive setElementContent:@"True"];
            } [archive selectParent];
        } [archive selectParent];
    }
    
    assert([archive cursorReference] == rdfRoot);
    
    NSMutableDictionary *d = extra ? extra.mutableCopy : [NSMutableDictionary dictionary];
    //2014-06-04T08:28:14-04:00
    NSString *datetimeString = [[NSDate date] datetimeString];
    d[@"xmp:MetadataDate"] = datetimeString;

    if (! extra[@"xmp:ModifyDate"])     d[@"xmp:ModifyDate"] = datetimeString;
    if (! extra[@"dc:rights"])          d[@"dc:rights"] = _rights ? _rights : [PDIXMPTemplate defaultRightsForLicense:_license major:_licenseMajorVersionString withAuthor:authorName];
    if (! extra[@"xmp:CreatorTool"])    d[@"xmp:CreatorTool"] = [NSString stringWithFormat:@"Pajdeg Ob-C (Pajdeg v. " PAJDEG_VERSION ")"];

    extra = d;

    NSMutableDictionary *nslist = [[NSMutableDictionary alloc] init];
    nslist[@"rdf:about"] = @"";
    
    BOOL hasDC = NO; // purl.org/dc/elements/1.1/
    BOOL hasPDF = NO; // ns.adobe.com/pdf/1.3/
    BOOL hasXMP = NO; 
    BOOL hasPDFX = NO; // ns.adobe.com/pdfx/1.3/
    /*
     xmlns:dc="http://purl.org/dc/elements/1.1/"
     xmlns:pdf="http://ns.adobe.com/pdf/1.3/"
     xmlns:xapRights="http://ns.adobe.com/xap/1.0/rights/"
     xmlns:xmp="http://ns.adobe.com/xap/1.0/"
     xmlns:xmpMM="http://ns.adobe.com/xap/1.0/mm/"
     xmlns:xmpRights="http://ns.adobe.com/xap/1.0/rights/"
     xmlns:pdfx="http://ns.adobe.com/pdfx/1.3/">
     */
    for (NSString *k in extra.allKeys) {
        hasDC |= [k hasPrefix:@"dc:"];
        hasPDF |= [k hasPrefix:@"pdf:"];
        hasXMP |= [k hasPrefix:@"xmp:"];
        hasPDFX |= [k hasPrefix:@"pdfx:"];
    }
    if (hasDC)   nslist[@"xmlns:dc"] = @"http://purl.org/dc/elements/1.1/";
    if (hasPDF)  nslist[@"xmlns:pdf"] = @"http://ns.adobe.com/pdf/1.3/";
    if (hasXMP)  { 
        nslist[@"xmlns:xmp"] = @"http://ns.adobe.com/xap/1.0/";
        nslist[@"xmlns:xmpMM"] = @"http://ns.adobe.com/xap/1.0/mm/";
        nslist[@"xmlns:xmpRights"] = @"http://ns.adobe.com/xap/1.0/rights/";
    }
    if (hasPDFX) nslist[@"xmlns:pdfx"] = @"http://ns.adobe.com/pdfx/1.3/";
    
    [archive createElement:@"rdf:Description" withAttributes:nslist]; {

        NSDictionary *info;
        NSString *resource;
        
        for (NSString *key in extra.allKeys) {
            // we don't want to get duplicate entries so we remove existing values with the same key
            if ([archive selectElement:key]) 
                [archive deleteElement];
            
            [archive createElement:key]; {
                id val = extra[key];
                    // dc:format is special; it doesn't have the rdf:Alt/Seq/etc stuff so we ignore that one here
                if ([key hasPrefix:@"dc:"] && ! [key isEqualToString:@"dc:format"]) {
                    BOOL includeLang = YES;
                    
                    info = nil;
                    resource = nil;
                    if ([val isKindOfClass:[NSDictionary class]]) {
                        info = val;
                        val = info[@"value"];
                        resource = info[@"resource"];
                        if (resource) [archive setString:resource forAttribute:@"rdf:resource"];
                    }
                    
                    // specialized keys exist and require specific handling
                    if ([key isEqualToString:@"dc:creator"]) {
                        // creator requires a Seq and does not have a lang
                        [archive createElement:@"rdf:Seq"];
                        includeLang = NO;
                        if ([val isKindOfClass:[NSString class]]) val = @[val];
                    }
                    else if ([key isEqualToString:@"dc:subject"] || [key isEqualToString:@"dc:publisher"]) {
                        // subject / publisher is a bag and does not include lang
                        [archive createElement:@"rdf:Bag"];
                        includeLang = NO;
                        if ([val isKindOfClass:[NSString class]]) val = @[val];
                    }
                    else if ([val isKindOfClass:[NSString class]]) {
                        [archive createElement:@"rdf:Alt"]; 
                        val = @[val];
                    }
                    else if ([val isKindOfClass:[NSArray class]]) {
                        [archive createElement:@"rdf:Seq"];
                    }
                    else if ([val isKindOfClass:[NSSet class]]) {
                        [archive createElement:@"rdf:Bag"];
                    }
                    
                    NSDictionary *liAttr = (includeLang ? @{@"xml:lang": @"x-default"} : nil);
                    for (NSString *v in val) {
                        [archive appendElement:@"rdf:li" withAttributes:liAttr]; {
                            [archive setElementContent:[v stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
                        } [archive selectParent];
                    }
                    
                    [archive selectParent];
                } else {
                    [archive setElementContent:[NSString stringWithFormat:@"%@", val]];
                }
            } [archive selectParent];
        }
        
    } [archive selectParent];

    assert([archive cursorReference] == rdfRoot);
    
    if (ccLicense[_license]) {
        [archive createElement:@"rdf:Description" withAttributes:@{@"rdf:about":       @"",
                                                                   @"xmlns:cc":        @"http://creativecommons.org/ns#"}]; {
            [archive createElement:@"cc:license" withAttributes:@{@"rdf:resource":     [self resolvedLicenseURL]}];
            [archive selectParent];
            if (_morePermissions) {
                [archive createElement:@"cc:morePermissions" withAttributes:@{@"rdf:resource": _morePermissions}];
                [archive selectParent];
            }
        } [archive selectParent];
    }
    
}

- (void)relicense:(PDIXMPLicense)newLicense
{
    _license = newLicense;
    _licenseName = licenseNames[newLicense];
    _licenseUrl = licenseUrls[newLicense];
    _licenseMajorVersionString = licenseDefaultMajors[newLicense];
}

- (void)relicenseWithName:(NSString *)newLicenseName
{
    PDIXMPLicense newLicense = [PDIXMPTemplate licenseForName:newLicenseName];
    if (newLicense == PDIXMPLicenseUndefined) {
        [self relicense:PDIXMPLicenseCustom];
        _licenseName = newLicenseName;
    } else {
        [self relicense:newLicense];
    }
}

- (void)specifyLicenseUrl:(NSString *)licenseUrl
{
    _licenseUrl = licenseUrl.length > 0 ? licenseUrl : licenseUrls[_license];
}

@end
