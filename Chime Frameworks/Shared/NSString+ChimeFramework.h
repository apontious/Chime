//
//  NSString+ChimeFramework.h
//  Chime Framework
//
//  Created by Andrew Pontious on 2/2/14.
//  Copyright (c) 2014 Andrew Pontious.
//  Some rights reserved: http://opensource.org/licenses/mit-license.php
//

#import <Foundation/Foundation.h>

#import <clang-c/CXString.h>

@interface NSString (ChimeFramework)

+ (NSString *)chime_NSStringFromCXString:(CXString)clangString;

@end
