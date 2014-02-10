//
//  ChimeClassExtension.m
//  Chime Framework
//
//  Created by Andrew Pontious on 2/3/14.
//  Copyright (c) 2014 Andrew Pontious.
//  Some rights reserved: http://opensource.org/licenses/mit-license.php
//

#import <Chime/ChimeClassExtension.h>

#import "ChimeSymbol_Private.h"
#import "ChimeClass.h"

@implementation ChimeClassExtension

#pragma mark Standard Methods

- (NSString *)description {
    // Override to not print name.
    return [NSString stringWithFormat:@"<%@ %p> %@ [[%@]], class %@", [self class], self, self.userVisibleTypeString, self.USR, self.ownerClass.name];
}

#pragma mark Public Methods

- (NSString *)fullName {
    return [NSString stringWithFormat:@"%@ ()", self.ownerClass.name];
}
- (NSString *)userVisibleTypeString {
    return NSLocalizedStringFromTableInBundle(@"Class Extension", @"Chime", [NSBundle bundleForClass:[self class]], @"User-visible type string for a class extension.");
}

@end
