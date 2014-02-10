//
//  ChimeClass_Private.h
//  Chime Framework
//
//  Created by Andrew Pontious on 2/9/14.
//  Copyright (c) 2014 Andrew Pontious.
//  Some rights reserved: http://opensource.org/licenses/mit-license.php
//

#import <Chime/ChimeClass.h>

@class ChimeIndex;

@interface ChimeClass (Private)

- (instancetype)initWithName:(NSString *)name USR:(NSString *)universalSymbolResolution superclass:(ChimeClass *)superclass index:(ChimeIndex *)index;

- (void)addSubclass:(ChimeClass *)subclass;

@end
