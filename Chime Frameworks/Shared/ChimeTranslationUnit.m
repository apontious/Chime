//
//  ChimeTranslationUnit.m
//  Chime Framework
//
//  Created by Andrew Pontious on 2/1/14.
//  Copyright (c) 2014 Andrew Pontious.
//  Some rights reserved: http://opensource.org/licenses/mit-license.php
//

#import "ChimeTranslationUnit.h"

#import "ChimeIndex_Private.h"

#import <clang-c/Index.h>

@interface ChimeTranslationUnit ()

@property (nonatomic, copy) NSURL *fileURL;
@property (nonatomic, copy) NSArray *arguments;
@property (nonatomic, weak) ChimeIndex *index;

@property (nonatomic, assign) CXTranslationUnit translationUnit;

@end

@interface ChimeTranslationUnit ()
@end

@implementation ChimeTranslationUnit

- (id)init {
    NSAssert(NO, @"Do not call init to create a %@, use %@", [ChimeTranslationUnit class], NSStringFromSelector(@selector(initWithFileURL:arguments:index:)));
    
    return nil;
}

- (void)dealloc {
    if (_translationUnit != nil) {
        clang_disposeTranslationUnit(_translationUnit);
    }
}

#pragma mark -

- (instancetype)initWithFileURL:(NSURL *)fileURL arguments:(NSArray *)arguments index:(ChimeIndex *)index {
    NSParameterAssert(index);
    NSParameterAssert(fileURL);
    
    self = [super init];
    
    if (self != nil) {
        _fileURL = [fileURL copy];
        _arguments = [arguments copy];
        _index = index;
    }
    
    return self;
}

- (BOOL)parse:(NSError **)error {
    BOOL result = NO;
    
    // TODO: check we only do this once.
    // TODO: put in threading safeguards.
    
    //
    const char *cArguments[[self.arguments count]];
    
    for (NSInteger i = 0; i < [self.arguments count]; i++) {
        cArguments[i] = [self.arguments[i] UTF8String];
    }
    
    self.translationUnit = clang_parseTranslationUnit(self.index.index,
                                                      [self.fileURL fileSystemRepresentation],
                                                      cArguments,
                                                      [self.arguments count],
                                                      NULL, // No unsaved files
                                                      0,
                                                      CXTranslationUnit_SkipFunctionBodies);

    if (self.translationUnit == nil) {
        // TODO: fill in NSError
    } else {
        result = YES;
        
        [self iterateThroughSymbols];
    }
    
    return result;
}

- (void)iterateThroughSymbols {
    clang_visitChildrenWithBlock(clang_getTranslationUnitCursor(self.translationUnit), ^enum CXChildVisitResult(CXCursor topLevelDeclCursor, CXCursor parent) {
        enum CXChildVisitResult result = CXChildVisit_Continue;
        
        CXSourceRange topLevelDeclRange = clang_getCursorExtent(topLevelDeclCursor);
        CXSourceLocation topLevelDeclLocation = clang_getRangeStart(topLevelDeclRange);
        
        CXFile topLevelDeclFile;
        clang_getFileLocation(topLevelDeclLocation, &topLevelDeclFile, NULL, NULL, NULL);
        
        CXString topLevelDeclFilename = clang_getFileName(topLevelDeclFile);
        const char *cFilename = clang_getCString(topLevelDeclFilename);
        
        // Disallowing NULL file paths excludes system default symbols that don't come from any file.
        if (cFilename != NULL) {
            
            const enum CXCursorKind topLevelDeclKind = clang_getCursorKind(topLevelDeclCursor);
            
            if (topLevelDeclKind == CXCursor_ObjCInterfaceDecl || topLevelDeclKind == CXCursor_ObjCImplementationDecl) {
                
                // Classes
                
                CXString USR = clang_getCursorUSR(topLevelDeclCursor);
                
                ChimeClass *class = [self.index classForUSR:USR];
                if (class == nil) {
                    CXString name = clang_getCursorSpelling(topLevelDeclCursor);
                    
                    class = [self.index createClassForName:name USR:USR];
                    if (class == nil) {
                        // TODO: record error somehow
                    }
                    
                    clang_disposeString(name);
                }
                
                clang_disposeString(USR);

            } else if (topLevelDeclKind == CXCursor_ObjCCategoryDecl || topLevelDeclKind == CXCursor_ObjCCategoryImplDecl) {

                // Categories and Class Extensions - TODO
                
            }
        }
        
        clang_disposeString(topLevelDeclFilename);
        
        return result;
    });
}

@end
