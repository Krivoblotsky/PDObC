//
// PDIPage.h
//
// Copyright (c) 2014 Karl-Johan Alm (http://github.com/kallewoof)
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

#import <Foundation/Foundation.h>
#import "PDDefines.h"

@class PDInstance;
@class PDIObject;

/**
 *  Represents an instance of a page in a PDF document.
 */
@interface PDIPage : NSObject

/**
 *  The page reference of this page.
 */
@property (nonatomic, readonly) PDPageRef pageRef;

@property (nonatomic, readonly) PDIObject *pageObject;

@property (nonatomic, readonly) PDIObject *contents;

@property (nonatomic, readonly) CGRect mediaBox;

/**
 *  A single string containing all the text on the page.
 */
@property (nonatomic, readonly) NSString *text;

@end
