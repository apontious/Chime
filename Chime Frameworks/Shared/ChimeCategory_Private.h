//
//  ChimeCategory_Private.h
//  Chime Framework
//
//  Created by Andrew Pontious on 2/3/14.
//  Copyright (c) 2014 Andrew Pontious.
//  Some rights reserved: http://opensource.org/licenses/mit-license.php
//

#import <Chime/ChimeCategory.h>

@class ChimeIndex;

@interface ChimeCategory (Private)

- (instancetype)initWithName:(NSString *)name USR:(NSString *)universalSymbolResolution class:(ChimeClass *)class index:(ChimeIndex *)index;

@end
