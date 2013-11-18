//
// PDIReference.m
//
// Copyright (c) 2013 Karl-Johan Alm (http://github.com/kallewoof)
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

#import "PDIReference.h"
#import "pd_internal.h"

@interface PDIReference () {
    PDReferenceRef _ref;
}
@end

@implementation PDIReference

- (void)dealloc
{
    PDRelease(_ref);
}

- (id)initWithReference:(PDReferenceRef)reference
{
    self = [super init];
    if (self) {
        _ref = PDRetain(reference);
        _objectID = _ref->obid;
        _generationID = _ref->genid;
    }
    return self;
}

- (id)initWithObjectID:(NSInteger)objectID generationID:(NSInteger)generationID
{
    return [self initWithReference:PDReferenceCreate(objectID, generationID)];
}

- (id)initWithDefinitionStack:(pd_stack)stack
{
    return [self initWithReference:PDReferenceCreateFromStackDictEntry(stack)];
}

- (const char *)PDFString
{
    if (NULL == _PDFString) {
        _PDFString = strdup([[NSString stringWithFormat:@"%ld %ld R", (long)_objectID, (long)_generationID] cStringUsingEncoding:NSUTF8StringEncoding]);
    }
    return _PDFString;
}

@end
