
// PDInstance.m
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
#import "pd_internal.h"
#import "pd_pdf_implementation.h"

#import "PDITaskBlocks.h"
#import "PDInstance.h"
#import "PDIObject.h"
#import "PDIPage.h"
#import "PDPage.h"
#import "PDCatalog.h"
#import "PDPage.h"
#import "PDIReference.h"
#import "NSObjects+PDIEntity.h"

#import "PDString.h"
#import "PDDictionary.h"
#import "PDArray.h"

@interface PDInstance () {
    PDPipeRef _pipe;
    PDIObject *_rootObject;
    PDIObject *_infoObject;
    PDIObject *_trailerObject;
    PDIObject *_metadataObject;
    PDParserRef _parser;
    PDIReference *_rootRef;
    PDIReference *_infoRef;
    NSString *_documentID;
    NSString *_documentInstanceID;
    NSMutableDictionary *_pageDict;
    BOOL _fetchedDocIDs;
}

@end

@interface PDIPage (PDInstance)

- (id)initWithPage:(PDPageRef)page inInstance:(PDInstance *)instance;

@end

@interface PDIObject (PDInstance)

- (void)markImmutable;

- (void)setInstance:(PDInstance *)instance;

@end

@implementation PDInstance

- (void)dealloc
{
    if (_pipe) PDRelease(_pipe);
    
    pd_pdf_conversion_discard();
}

- (id)initWithSourcePDFPath:(NSString *)sourcePDFPath destinationPDFPath:(NSString *)destPDFPath
{
    self = [super init];
    if (self) {
        pd_pdf_conversion_use();
        
        _sessionDict = [[NSMutableDictionary alloc] init];
        
        if ([sourcePDFPath isEqualToString:destPDFPath]) {
            [NSException raise:NSInvalidArgumentException format:@"Input source and destination source must not be the same file."];
        }
        if (nil == sourcePDFPath || nil == destPDFPath) {
            [NSException raise:NSInvalidArgumentException format:@"Source and destination must be non-nil."];
        }
        _sourcePDFPath = sourcePDFPath;
        _destPDFPath = destPDFPath;
        _pipe = PDPipeCreateWithFilePaths([sourcePDFPath cStringUsingEncoding:NSUTF8StringEncoding], 
                                          [destPDFPath cStringUsingEncoding:NSUTF8StringEncoding]);
        if (NULL == _pipe) {
            PDError("PDPipeCreateWithFilePaths() failure");
            return nil;
        }
        
        if (! PDPipePrepare(_pipe)) {
            PDError("PDPipePrepare() failure");
            return nil;
        }
        
        _parser = PDPipeGetParser(_pipe);
        
        // to avoid issues later on, we also set up the catalog here
        if ([self numberOfPages] == 0) {
            PDError("numberOfPages == 0 (this is considered a failure)");
            return nil;
        }
        
        _pageDict = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (id)initWithSourceURL:(NSURL *)sourceURL destinationPDFPath:(NSString *)destPDFPath
{
    if ([sourceURL isFileURL]) {
        return [self initWithSourcePDFPath:[sourceURL path] destinationPDFPath:destPDFPath];
    }
    /// @todo: Network stream support (Pajdeg? PDObC?)
    return nil;
}

- (BOOL)execute
{
    NSAssert(_pipe, @"-execute called more than once, or initialization failed in PDInstance");
    
    _objectSum = PDPipeExecute(_pipe);
    
    PDRelease(_pipe);
    _pipe = NULL;
    
    return _objectSum != -1;
}

- (BOOL)encrypted
{
    return true == PDParserGetEncryptionState(_parser);
}

- (PDIObject *)verifiedMetadataObject
{
    if (_metadataObject) return _metadataObject;
    PDIObject *root = [self rootObject];
    _metadataObject = [root resolvedValueForKey:@"Metadata"];
//    NSString *md = [root valueForKey:@"Metadata"];
    if (_metadataObject) {
        if ([_metadataObject isKindOfClass:[PDIReference class]]) {
            _metadataObject = [self fetchReadonlyObjectWithID:[(PDIReference *)_metadataObject objectID]];
        }
//        _metadataObject = [self fetchReadonlyObjectWithID:[PDIReference objectIDFromString:md]];
        [_metadataObject enableMutationViaMimicSchedulingWithInstance:self];
    } else {
        _metadataObject = [self appendObject];
        _metadataObject.type = PDObjectTypeDictionary; // we set the type explicitly, because the metadata object isn't always modified; if it isn't modified, Pajdeg considers it illegal to add it, as it requires that new objects have a type
        [root enableMutationViaMimicSchedulingWithInstance:self];
        [root setValue:_metadataObject forKey:@"Metadata"];
    }
    return _metadataObject;
}

- (PDIReference *)rootReference
{
    if (_rootRef == nil && _parser->rootRef) {
        _rootRef = [[PDIReference alloc] initWithReference:_parser->rootRef];
    }
    return _rootRef;
}

- (PDIReference *)infoReference
{
    if (_infoRef == nil && _parser->infoRef) {
        _infoRef = [[PDIReference alloc] initWithReference:_parser->infoRef];
    }
    return _infoRef;
}

- (PDIObject *)rootObject
{
    if (_rootObject == nil) {
        _rootObject = [[PDIObject alloc] initWithObject:PDParserGetRootObject(_parser)];
        [_rootObject setInstance:self];
    }
    return _rootObject;
}

- (PDIObject *)infoObject
{
    if (_infoObject == nil) {
        PDObjectRef infoObj = PDParserGetInfoObject(_parser);
        if (infoObj) {
            _infoObject = [[PDIObject alloc] initWithObject:infoObj];
        }
    }
    return _infoObject;
}

- (PDIObject *)trailerObject
{
    if (_trailerObject == nil) {
        PDObjectRef trailerObj = PDParserGetTrailerObject(_parser);
        _trailerObject = [[PDIObject alloc] initWithObject:trailerObj];
        [_trailerObject setInstance:self];
        [_trailerObject markMutable];
    }
    return _trailerObject;
}

- (PDIObject *)verifiedInfoObject
{
    if (_infoObject || [self infoObject]) return _infoObject;
    
    _infoObject = [self appendObject];
    _parser->infoRef = PDRetain([[_infoObject reference] PDReference]);
    
    PDObjectRef trailer = _parser->trailer;
    PDIObject *trailerOb = [[PDIObject alloc] initWithObject:trailer];
    //[trailerOb setInstance:self];
    [trailerOb setValue:_infoObject forKey:@"Info"];

    return _infoObject;
}

- (PDIObject *)createObject:(BOOL)append
{
    PDObjectRef ob = append ? PDParserCreateAppendedObject(_parser) : PDParserCreateNewObject(_parser);
    PDIObject *iob = [[PDIObject alloc] initWithObject:ob];
    [iob markMutable];
    PDRelease(ob);
    return iob;
}

- (PDIObject *)insertObject
{
    return [self createObject:NO];
}

- (PDIObject *)appendObject
{
    return [self createObject:YES];
}

- (PDIObject *)fetchReadonlyObjectWithID:(NSInteger)objectID
{
    NSAssert(objectID != 0, @"Zero is not a valid object ID");
    PDObjectRef obj = PDParserLocateAndCreateObject(_parser, objectID, true);
    //pd_stack defs = PDParserLocateAndCreateDefinitionForObject(_parser, objectID, true);
    PDIObject *object = [[PDIObject alloc] initWithObject:obj];//WithInstance:self forDefinitionStack:defs objectID:objectID generationID:0];
    PDRelease(obj);
    return object;
}

- (NSInteger)numberOfPages
{
    PDCatalogRef catalog = PDParserGetCatalog(_parser);
    return (catalog ? PDCatalogGetPageCount(catalog) : 0);
}

- (NSInteger)objectIDForPageNumber:(NSInteger)pageNumber
{
    PDCatalogRef catalog = PDParserGetCatalog(_parser);
    return PDCatalogGetObjectIDForPage(catalog, pageNumber);
}

- (PDIPage *)pageForPageNumber:(NSInteger)pageNumber
{
    if (pageNumber < 1 || pageNumber > [self numberOfPages]) {
        [NSException raise:@"PDInstanceBoundsException" format:@"The page number %ld is not within the bounds 1..%ld", (long)pageNumber, (long)[self numberOfPages]];
    }
    PDIPage *page = _pageDict[@(pageNumber)];
    if (page) return page;
    
    PDPageRef pageRef = PDPageCreateForPageWithNumber(_parser, pageNumber);
    page = [[PDIPage alloc] initWithPage:pageRef inInstance:self];
    PDRelease(pageRef);
    
    _pageDict[@(pageNumber)] = page;
    
    return page;
}

- (PDIPage *)insertPage:(PDIPage *)page atPageNumber:(NSInteger)pageNumber
{
    PDPageRef nativePage = PDPageInsertIntoPipe(page.pageRef, _pipe, pageNumber);
    PDIPage *newPage = [[PDIPage alloc] initWithPage:nativePage inInstance:self];

    NSMutableDictionary *newPageDict = [[NSMutableDictionary alloc] initWithCapacity:_pageDict.count + 1];
    for (NSNumber *n in _pageDict.allKeys) {
        NSNumber *m = (n.integerValue >= pageNumber) ? @(n.integerValue+1) : n;
        newPageDict[m] = _pageDict[n];
    }
    newPageDict[@(pageNumber)] = newPage;
    _pageDict = newPageDict;
    return newPage;
}

- (void)enqueuePropertyType:(PDPropertyType)type value:(NSInteger)value operation:(PDIObjectOperation)operation
{
    PDTaskRef filter, task;
    
    filter = PDTaskCreateFilterWithValue(type, value);
    
    __weak PDInstance *bself = self;
    
    task = PDITaskCreateBlockMutator(^PDTaskResult(PDPipeRef pipe, PDTaskRef task, PDObjectRef object) {
        PDIObject *iob = [[PDIObject alloc] initWithObject:object];
        [iob markMutable];
        [iob setInstance:bself];
        return operation(bself, iob);
    });
    
    PDTaskAppendTask(filter, task);
    PDPipeAddTask(_pipe, filter);
    
    PDRelease(task);
    PDRelease(filter);
}

- (void)forObjectWithID:(NSInteger)objectID enqueueOperation:(PDIObjectOperation)operation
{
    NSAssert(objectID != 0, @"Object ID must not be 0.");
    [self enqueuePropertyType:PDPropertyObjectId value:objectID operation:operation];
}

- (void)enqueueOperation:(PDIObjectOperation)operation
{
    __weak PDInstance *bself = self;

    PDPipeAddTask(_pipe, PDITaskCreateBlockMutator(^PDTaskResult(PDPipeRef pipe, PDTaskRef task, PDObjectRef object) {
        PDIObject *iob = [[PDIObject alloc] initWithObject:object];
        return operation(bself, iob);
    }));
}

- (void)setRootStream:(NSData *)data forKey:(NSString *)key
{
    if ([key isEqualToString:@"Metadata"]) {
        // We use the built-in verifiedMetadata method to do this; if we don't, we run the risk of double-tasking the metadata stream and overwriting requested changes.
        [self verifiedMetadataObject];
//        [_metadataObject setStreamIsEncrypted:NO];
        [_metadataObject setStreamContent:data encrypted:NO];
        return;
    }
    
    // got a Root?
    if ([self rootObject]) {
        PDIReference *ref = [_rootObject valueForKey:key];
        if (ref) {
            // got this already; we want to tweak it then
            if ([ref isKindOfClass:[PDIObject class]]) ref = [(PDIObject*)ref reference];
            [self forObjectWithID:[ref objectID] enqueueOperation:^PDTaskResult(PDInstance *instance, PDIObject *object) {
//                [object setStreamIsEncrypted:NO];
                [object setStreamContent:data encrypted:NO];
                return PDTaskDone;
            }];
        } else {
            // don't have the key; we want to add an object then
            PDIObject *ob = [self appendObject];
//            [ob setStreamIsEncrypted:NO];
            [ob setStreamContent:data encrypted:NO];
            
            [_rootObject enableMutationViaMimicSchedulingWithInstance:self];
            [_rootObject setValue:ob forKey:key];
            
            /*[self forObjectWithID:_rootObject.objectID enqueueOperation:^PDTaskResult(PDInstance *instance, PDIObject *object) {
                [object setValue:ob forKey:key];
                return PDTaskDone;
            }];*/
        }
    } else {
        // it's an easy enough thing to create a root object and stuff it into the trailer, but then again, a PDF with no root object is either misinterpreted beyond oblivion (by Pajdeg) or it's broken beyond repair (by someone) so we choose to die here; if you wish to support a PDF with no root object, some form of flag may be added in the future, but I can't see why anyone would want this
        fprintf(stderr, "I thought all pdfs had root objects...\n");
        [NSException raise:@"PDInvalidDocumentException" format:@"No root object exists in the document."];
    }
}

- (NSInteger)totalObjectCount
{
    return PDParserGetTotalObjectCount(_parser);
}

- (void)setupDocumentIDs
{
    _fetchedDocIDs = YES;
    PDDictionaryRef d = PDObjectGetDictionary(self.trailerObject.objectRef);
    void *idValue = PDDictionaryGetEntry(d, "ID");
    if (PDInstanceTypeArray == PDResolve(idValue)) {
        PDArrayRef a = idValue;
        {
            NSInteger count = PDArrayGetCount(a);
            _documentID = count > 0 ? [NSString stringWithUTF8String:PDStringHexValue(PDArrayGetElement(a, 0), false)] : nil;
            _documentInstanceID = count > 1 ? [NSString stringWithUTF8String:PDStringHexValue(PDArrayGetElement(a, 1), false)] : nil;
        }
//        pd_array_destroy(a);
    }
}

- (NSString *)documentID
{
    if (_documentID) return _documentID;
    if (! _fetchedDocIDs) [self setupDocumentIDs];
    return _documentID;
}

- (NSString *)documentInstanceID
{
    if (_documentInstanceID) return _documentInstanceID;
    if (! _fetchedDocIDs) [self setupDocumentIDs];
    return _documentInstanceID;
}

- (void)setDocumentID:(NSString *)documentID
{
    if (! _fetchedDocIDs) [self setupDocumentIDs];
    if (_documentInstanceID == nil) _documentInstanceID = documentID;
    _documentID = documentID;
    if (_documentID) [_trailerObject setValue:@[_documentID, _documentInstanceID] forKey:@"ID"];
}

- (void)setDocumentInstanceID:(NSString *)documentInstanceID
{
    if (! _fetchedDocIDs) [self setupDocumentIDs];
    if (_documentID == nil) _documentID = documentInstanceID;
    _documentInstanceID = documentInstanceID;
    if (_documentInstanceID) [_trailerObject setValue:@[_documentID, _documentInstanceID] forKey:@"ID"];
}

#ifdef PD_SUPPORT_CRYPTO

- (pd_crypto)cryptoObject
{
    return _parser->crypto;
}

#endif

@end