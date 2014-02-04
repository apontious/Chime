//
//  ChimeCategory_Private.h
//  Chime Framework
//
//  Created by Andrew Pontious on 2/3/14.
//  Copyright (c) 2014 Andrew Pontious. All rights reserved.
//

#import <Chime/ChimeCategory.h>

@class ChimeClass;

@interface ChimeCategory (Private)

- (instancetype)initWithName:(NSString *)name USR:(NSString *)universalSymbolResolution class:(ChimeClass *)class index:(ChimeIndex *)index;

@end
