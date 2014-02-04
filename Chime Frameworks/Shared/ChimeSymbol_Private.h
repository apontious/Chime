//
//  ChimeSymbol_Private.h
//  Chime Framework
//
//  Created by Andrew Pontious on 2/2/14.
//  Copyright (c) 2014 Andrew Pontious.
//  Some rights reserved: http://opensource.org/licenses/mit-license.php
//

#import <Chime/ChimeSymbol.h>

@class ChimeIndex;

@interface ChimeSymbol (Private)

@property (nonatomic, copy, readonly) NSString *USR;

@property (nonatomic, weak, readonly) ChimeIndex *index;

- (instancetype)initWithName:(NSString *)name USR:(NSString *)universalSymbolResolution index:(ChimeIndex *)index;

@end
