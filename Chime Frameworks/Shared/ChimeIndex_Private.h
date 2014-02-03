//
//  ChimeIndex_Private.h
//  Chime Framework
//
//  Created by Andrew Pontious on 2/1/14.
//  Copyright (c) 2014 Andrew Pontious.
//  Some rights reserved: http://opensource.org/licenses/mit-license.php
//

#import <Chime/ChimeIndex.h>

#import <clang-c/Index.h>

@class ChimeTranslationUnit, ChimeClass;

@interface ChimeIndex (Private)

@property (nonatomic, assign, readonly) CXIndex index;

- (void)addTranslationUnit:(ChimeTranslationUnit *)translationUnit;

- (ChimeClass *)classForUSR:(CXString)universalSymbolResolution;
- (ChimeClass *)createClassForName:(CXString)name USR:(CXString)universalSymbolResolution;

@end
