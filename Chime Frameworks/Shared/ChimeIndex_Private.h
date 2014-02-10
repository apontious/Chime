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

@class ChimeTranslationUnit, ChimeSymbol, ChimeClass, ChimeCategory;

@interface ChimeIndex (Private)

@property (nonatomic, assign, readonly) CXIndex index;

- (void)addTranslationUnit:(ChimeTranslationUnit *)translationUnit;

- (ChimeSymbol *)symbolForUSR:(CXString)universalSymbolResolution;

- (ChimeClass *)createClassForName:(CXString)name USR:(CXString)universalSymbolResolution superclass:(ChimeClass *)superclass;
- (ChimeCategory *)createCategoryForName:(CXString)name USR:(CXString)universalSymbolResolution class:(ChimeClass *)class;

- (BOOL)isNameOfCocoaClassWithoutSuperclass:(CXString)nameClangString;

@end
