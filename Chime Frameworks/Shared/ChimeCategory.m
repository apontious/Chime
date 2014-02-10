//
//  ChimeCategory.m
//  Chime Framework
//
//  Created by Andrew Pontious on 2/3/14.
//  Copyright (c) 2014 Andrew Pontious.
//  Some rights reserved: http://opensource.org/licenses/mit-license.php
//

#import "ChimeCategory_Private.h"

#import "ChimeSymbol_Private.h"
#import "ChimeClass.h"

@interface ChimeCategory ()

@property (nonatomic, weak) ChimeClass *ownerClass;

@end

@implementation ChimeCategory

#pragma mark Standard Methods

- (NSString *)description {
    // Override to display owner class name.
    return [NSString stringWithFormat:@"<%@ %p> %@ %@ [[%@]], class %@", [self class], self, self.userVisibleTypeString, self.name, self.USR, self.ownerClass.name];
}

#pragma mark Public Methods

- (NSString *)fullName {
    return [NSString stringWithFormat:@"%@ (%@)", self.ownerClass.name, self.name];
}
- (NSString *)userVisibleTypeString {
    return NSLocalizedStringFromTableInBundle(@"Category", @"Chime", [NSBundle bundleForClass:[self class]], @"User-visible type string for a category.");
}

#pragma mark Framework Only Method

- (instancetype)initWithName:(NSString *)name USR:(NSString *)universalSymbolResolution class:(ChimeClass *)class index:(ChimeIndex *)index {
    self = [self initWithName:name USR:universalSymbolResolution index:index];
    if (self != nil) {
        _ownerClass = class;
    }
    
    return self;
}

@end
