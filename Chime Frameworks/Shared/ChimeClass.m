//
//  ChimeClass.m
//  Chime Framework
//
//  Created by Andrew Pontious on 2/1/14.
//  Copyright (c) 2014 Andrew Pontious.
//  Some rights reserved: http://opensource.org/licenses/mit-license.php
//

#import <Chime/ChimeClass.h>

@implementation ChimeClass

#pragma mark Public Methods

- (NSString *)userVisibleTypeString {
    return NSLocalizedStringFromTableInBundle(@"Class", @"Chime", [NSBundle bundleForClass:[self class]], @"User-visible type string for a class.");
}

@end
