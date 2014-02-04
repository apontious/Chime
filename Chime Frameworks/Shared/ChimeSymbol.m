//
//  ChimeSymbol.m
//  Chime Framework
//
//  Created by Andrew Pontious on 2/2/14.
//  Copyright (c) 2014 Andrew Pontious.
//  Some rights reserved: http://opensource.org/licenses/mit-license.php
//

#import "ChimeSymbol_Private.h"

@interface ChimeSymbol ()

@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSString *USR;

@property (nonatomic, weak) ChimeIndex *index;

@end

@implementation ChimeSymbol

#pragma mark Standard Methods

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p> %@ %@ [[%@]]", [self class], self, self.userVisibleTypeString, self.name, self.USR];
}

#pragma mark Framework Only Methods

- (instancetype)initWithName:(NSString *)name USR:(NSString *)universalSymbolResolution index:(ChimeIndex *)index {
    self = [self init];
    if (self != nil) {
        _name = [name copy];
        _USR = [universalSymbolResolution copy];
        
        _index = index;
    }
    
    return self;
}

#pragma mark Public Methods

- (NSString *)fullName {
    return self.name;
}
- (NSString *)userVisibleTypeString {
    return NSLocalizedStringFromTableInBundle(@"Symbol", @"Chime", [NSBundle bundleForClass:[self class]], @"User-visible type string for a symbol.");
}

@end
