//
//  ChimeClass.h
//  Chime Framework
//
//  Created by Andrew Pontious on 2/1/14.
//  Copyright (c) 2014 Andrew Pontious.
//  Some rights reserved: http://opensource.org/licenses/mit-license.php
//

#import <Chime/ChimeSymbol.h>

@interface ChimeClass : ChimeSymbol

// Not called "superclass" because there's already a method named that in NSObject, returns Class.
@property (nonatomic, weak, readonly) ChimeClass *chimeSuperclass;
// This returns a copy. Internal reference is weak.
@property (nonatomic, strong, readonly) NSArray *subclasses;

@end
