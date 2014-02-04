//
//  ChimeIndex.m
//  Chime Framework
//
//  Created by Andrew Pontious on 2/1/14.
//  Copyright (c) 2014 Andrew Pontious.
//  Some rights reserved: http://opensource.org/licenses/mit-license.php
//

#import "ChimeIndex_Private.h"

#import "ChimeClass.h"
#import "ChimeSymbol_Private.h"
#import "NSString+ChimeFramework.h"

#import <clang-c/Index.h>

@interface ChimeIndex ()

@property (nonatomic, assign) CXIndex index;

@property (nonatomic) NSMutableArray *translationUnits;
// TODO: rename to more general-purpose symbolsForUSRs.
@property (nonatomic) NSMutableDictionary *classesForUSRs;

@end

@implementation ChimeIndex

#pragma mark Standard Methods

- (id)init {
    self = [super init];
    if (self) {
        _translationUnits = [NSMutableArray new];
        _classesForUSRs = [NSMutableDictionary new];
        
        // TODO: expose flags to clients?
        int excludeDeclarationsFromPCH = 0;
        int displayDiagnostics = 1;
        
        _index = clang_createIndex(excludeDeclarationsFromPCH, displayDiagnostics);
    }
    
    return self;
}

- (void)dealloc {
    // From clang-c/Index.h comments: The index must not be destroyed until all of the translation units created within that index have been destroyed.
    clang_disposeIndex(_index);
}

#pragma mark Public Methods

- (NSArray *)classes {
    // TODO: cache this so we're not sorting every time we're called?
    NSArray *classes = [self.classesForUSRs allValues];
    
    return [classes sortedArrayWithOptions:0 usingComparator:^NSComparisonResult(ChimeClass *class1, ChimeClass *class2) {
        return [class1.name compare:class2.name];
    }];
}

#pragma mark Framework Only Methods

- (void)addTranslationUnit:(ChimeTranslationUnit *)translationUnit {
    // TODO: check if we've already added it?
    [self.translationUnits addObject:translationUnit];
}

- (ChimeClass *)classForUSR:(CXString)universalSymbolResolutionClangString {
    NSString *universalSymbolResolution = [NSString chime_NSStringFromCXString:universalSymbolResolutionClangString];
    
    if (universalSymbolResolution != nil) {
        return self.classesForUSRs[universalSymbolResolution];
    }
    
    return nil;
}
- (ChimeClass *)createClassForName:(CXString)nameClangString USR:(CXString)universalSymbolResolutionClangString {
    NSString *name = [NSString chime_NSStringFromCXString:nameClangString];
    NSString *universalSymbolResolution = [NSString chime_NSStringFromCXString:universalSymbolResolutionClangString];
    
    ChimeClass *class = [[ChimeClass alloc] initWithName:name USR:universalSymbolResolution index:self];
    self.classesForUSRs[universalSymbolResolution] = class;
    return class;
}

@end
