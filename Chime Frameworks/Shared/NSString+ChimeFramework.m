//
//  NSString+ChimeFramework.m
//  Chime Framework
//
//  Created by Andrew Pontious on 2/2/14.
//  Copyright (c) 2014 Andrew Pontious.
//  Some rights reserved: http://opensource.org/licenses/mit-license.php
//

#import "NSString+ChimeFramework.h"

@implementation NSString (ChimeFramework)

+ (NSString *)chime_NSStringFromCXString:(CXString)clangString {
    NSString *result;
    
    const char *cString = clang_getCString(clangString);
    if (cString != NULL) {
        result = [NSString stringWithUTF8String:cString];
    }
    
    return result;
}

@end
