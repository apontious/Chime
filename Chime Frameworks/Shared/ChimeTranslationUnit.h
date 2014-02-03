//
//  ChimeTranslationUnit.h
//  Chime Framework
//
//  Created by Andrew Pontious on 2/1/14.
//  Copyright (c) 2014 Andrew Pontious.
//  Some rights reserved: http://opensource.org/licenses/mit-license.php
//

#import <Foundation/Foundation.h>

@class ChimeIndex;

@interface ChimeTranslationUnit : NSObject

@property (nonatomic, copy, readonly) NSURL *fileURL;
@property (nonatomic, copy, readonly) NSArray *arguments;
@property (nonatomic, weak, readonly) ChimeIndex *index;

- (instancetype)initWithFileURL:(NSURL *)fileURL arguments:(NSArray *)arguments index:(ChimeIndex *)index;

// Parses translation unit synchronously and populates ChimeIndex with classes, categories, and class extensions from it.
// Do not call repeatedly.
- (BOOL)parse:(NSError **)error;

@end
