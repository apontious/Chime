//
//  ChimeClass.m
//  Chime Framework
//
//  Created by Andrew Pontious on 2/1/14.
//  Copyright (c) 2014 Andrew Pontious.
//  Some rights reserved: http://opensource.org/licenses/mit-license.php
//

#import "ChimeClass_Private.h"

#import "ChimeSymbol_Private.h"

@interface ChimeClass ()

@property (nonatomic, weak) ChimeClass *chimeSuperclass;

@property (nonatomic) NSPointerArray *subclassesInternal;

@end

@implementation ChimeClass

#pragma mark Public Methods

- (NSString *)userVisibleTypeString {
    return NSLocalizedStringFromTableInBundle(@"Class", @"Chime", [NSBundle bundleForClass:[self class]], @"User-visible type string for a class.");
}

- (NSArray *)subclasses {
    return [self.subclassesInternal allObjects];
}

#pragma mark Framework Only Methods

- (instancetype)initWithName:(NSString *)name USR:(NSString *)universalSymbolResolution superclass:(ChimeClass *)superclass index:(ChimeIndex *)index {
    self = [super initWithName:name USR:universalSymbolResolution index:index];
    if (self != nil) {
        _chimeSuperclass = superclass;
        
        _subclassesInternal = [NSPointerArray weakObjectsPointerArray];
        
        [superclass addSubclass:self];
    }

    return self;
}

- (void)addSubclass:(ChimeClass *)subclass {
    [self.subclassesInternal addPointer:(__bridge void *)subclass];
}

@end
