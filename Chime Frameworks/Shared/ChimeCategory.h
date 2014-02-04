//
//  ChimeCategory.h
//  Chime Framework
//
//  Created by Andrew Pontious on 2/3/14.
//  Copyright (c) 2014 Andrew Pontious.
//  Some rights reserved: http://opensource.org/licenses/mit-license.php
//

#import <Chime/ChimeSymbol.h>

@class ChimeClass;

@interface ChimeCategory : ChimeSymbol

@property (nonatomic, weak, readonly) ChimeClass *ownerClass;

@end
