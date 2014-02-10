//
//  ChimeIndex.m
//  Chime Framework
//
//  Created by Andrew Pontious on 2/1/14.
//  Copyright (c) 2014 Andrew Pontious.
//  Some rights reserved: http://opensource.org/licenses/mit-license.php
//

#import "ChimeIndex_Private.h"

#import "ChimeTranslationUnit_Private.h"
#import "ChimeSymbol_Private.h"
#import "ChimeClass_Private.h"
#import "ChimeCategory_Private.h"
#import "ChimeClassExtension.h"

#import "NSString+ChimeFramework.h"

#import <clang-c/Index.h>

@interface ChimeIndex ()

@property (nonatomic, assign) CXIndex index;

@property (nonatomic) NSMutableArray *translationUnits;

@property (nonatomic) NSMutableDictionary *symbolsForUSRs;

@end

@implementation ChimeIndex

#pragma mark Standard Methods

- (id)init {
    self = [super init];
    if (self) {
        _translationUnits = [NSMutableArray new];
        _symbolsForUSRs = [NSMutableDictionary new];
        
        // TODO: expose flags to clients?
        int excludeDeclarationsFromPCH = 0;
        int displayDiagnostics = 1;
        
        _index = clang_createIndex(excludeDeclarationsFromPCH, displayDiagnostics);
    }
    
    return self;
}

- (void)dealloc {
    // From clang-c/Index.h comments: The index must not be destroyed until all of the translation units created within that index have been destroyed.
    // Client may have strong references to translation units, so we must make sure to gut them ourselves.
    for (ChimeTranslationUnit *translationUnit in _translationUnits) {
        [translationUnit disposeClangTranslationUnit];
    }
    
    clang_disposeIndex(_index);
}

#pragma mark Public Methods

- (NSArray *)symbols {
    // TODO: cache this so we're not sorting every time we're called?
    NSArray *symbols = [self.symbolsForUSRs allValues];
    
    return [symbols sortedArrayWithOptions:0 usingComparator:^NSComparisonResult(ChimeSymbol *symbol1, ChimeSymbol *symbol2) {
        return [symbol1.fullName compare:symbol2.fullName];
    }];
}

#pragma mark Framework Only Methods

- (void)addTranslationUnit:(ChimeTranslationUnit *)translationUnit {
    // TODO: check if we've already added it?
    [self.translationUnits addObject:translationUnit];
}

- (ChimeSymbol *)symbolForUSR:(CXString)universalSymbolResolutionClangString {
    NSString *universalSymbolResolution = [NSString chime_NSStringFromCXString:universalSymbolResolutionClangString];
    
    if (universalSymbolResolution != nil) {
        return self.symbolsForUSRs[universalSymbolResolution];
    }
    
    return nil;
}

- (ChimeClass *)createClassForName:(CXString)nameClangString USR:(CXString)universalSymbolResolutionClangString superclass:(ChimeClass *)superclass {
    NSString *name = [NSString chime_NSStringFromCXString:nameClangString];
    NSString *universalSymbolResolution = [NSString chime_NSStringFromCXString:universalSymbolResolutionClangString];
    
    ChimeClass *class = [[ChimeClass alloc] initWithName:name USR:universalSymbolResolution superclass:superclass index:self];
    self.symbolsForUSRs[universalSymbolResolution] = class;
    return class;
}
- (ChimeCategory *)createCategoryForName:(CXString)nameClangString USR:(CXString)universalSymbolResolutionClangString class:(ChimeClass *)class {
    NSString *name = [NSString chime_NSStringFromCXString:nameClangString];
    NSString *universalSymbolResolution = [NSString chime_NSStringFromCXString:universalSymbolResolutionClangString];
    
    ChimeCategory *result;
    
    if ([name length] == 0) {
        result = [[ChimeClassExtension alloc] initWithName:name USR:universalSymbolResolution class:class index:self];
    } else {
        result = [[ChimeCategory alloc] initWithName:name USR:universalSymbolResolution class:class index:self];
    }
    self.symbolsForUSRs[universalSymbolResolution] = result;

    return result;
}

- (BOOL)isNameOfCocoaClassWithoutSuperclass:(CXString)nameClangString {
    BOOL result = NO;
    
    NSString *name = [NSString chime_NSStringFromCXString:nameClangString];
    
    if ([name length] > 0) {
        NSArray *names = @[@"NSObject", @"NSProxy"];
        result = [names containsObject:name];
    }
    
    return result;
}

@end
