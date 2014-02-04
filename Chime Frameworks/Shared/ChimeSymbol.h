//
//  ChimeSymbol.h
//  Chime Framework
//
//  Created by Andrew Pontious on 2/2/14.
//  Copyright (c) 2014 Andrew Pontious.
//  Some rights reserved: http://opensource.org/licenses/mit-license.php
//

#import <Foundation/Foundation.h>

@interface ChimeSymbol : NSObject

@property (nonatomic, copy, readonly) NSString *name;

@property (nonatomic, readonly) NSString *fullName;
@property (nonatomic, readonly) NSString *userVisibleTypeString;

@end
