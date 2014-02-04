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

#import <Chime/ChimeError.h>

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
    clang_disposeTranslationUnit(_translationUnit);
}

#pragma mark -

- (instancetype)initWithFileURL:(NSURL *)fileURL arguments:(NSArray *)arguments index:(ChimeIndex *)index {
    NSParameterAssert(fileURL);
    NSParameterAssert(index);
    
    self = [super init];
    
    if (self != nil) {
        _fileURL = [fileURL copy];
        _arguments = [arguments copy];
        _index = index;
    }
    
    return self;
}

- (BOOL)parse:(NSError **)outError {
    BOOL result = NO;
    
    // TODO: check we only do this once.
    // TODO: put in threading safeguards.
    
    const char *cArguments[[self.arguments count]]; // Using stack-based dynamic C arrays for convenience.
    
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
        // TODO: fill in more NSError keys.
        NSString *localizedDescription = [NSString stringWithFormat:NSLocalizedStringFromTableInBundle(@"The translation unit “%@” failed to parse.", @"Chime", [NSBundle bundleForClass:[self class]], @"Format string for translation unit failed to parse error descripon."), [self.fileURL lastPathComponent]];
        
        NSError *error = [NSError errorWithDomain:ChimeErrorDomain
                                             code:ChimeErrorCodeTranslationUnitParseError
                                         userInfo:@{NSLocalizedDescriptionKey : localizedDescription}];

        if (*outError != nil) {
            *outError = error;
        };
    } else {
        result = YES;
        
        [self iterateThroughSymbols];
    }
    
    return result;
}

- (void)iterateThroughSymbols {
    clang_visitChildrenWithBlock(clang_getTranslationUnitCursor(self.translationUnit), ^enum CXChildVisitResult(CXCursor topLevelDeclCursor, CXCursor parent) {
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
                
                ChimeClass *class = (ChimeClass *)[self.index symbolForUSR:USR];
                if (class == nil) {
                    CXString name = clang_getCursorSpelling(topLevelDeclCursor);
                    
                    class = [self.index createClassForName:name USR:USR];
                    if (class == nil) {
                        // TODO: record error somehow
                        NSLog(@"Unable to create class for name \"%s\", USR \"%s\"", clang_getCString(name), clang_getCString(USR));
                    }
                    
                    clang_disposeString(name);
                }
                
                clang_disposeString(USR);

            } else if (topLevelDeclKind == CXCursor_ObjCCategoryDecl || topLevelDeclKind == CXCursor_ObjCCategoryImplDecl) {

                // Categories and Class Extensions
                
                CXString USR = clang_getCursorUSR(topLevelDeclCursor);
                
                __block ChimeCategory *category = (ChimeCategory *)[self.index symbolForUSR:USR];
                if (category == nil) {
                    CXString name = clang_getCursorSpelling(topLevelDeclCursor);
                    
                    __block ChimeClass *class;
                    
                    clang_visitChildrenWithBlock(topLevelDeclCursor, ^enum CXChildVisitResult(CXCursor categoryChildCursor, CXCursor parent) {
                        const enum CXCursorKind categoryChildKind = clang_getCursorKind(categoryChildCursor);
                        
                        if (categoryChildKind != CXCursor_ObjCClassRef) {
                            // TODO: record error somehow
                            NSLog(@"Couldn't find initial class reference for category \"%s\", USR \"%s\"", clang_getCString(name), clang_getCString(USR));
                        } else {
                            CXString className = clang_getCursorSpelling(categoryChildCursor);
                            
                            // Note: clang_getCursorUSR() returns a blank string here, so we must make the USR manually ourselves.
                            CXString classUSR = clang_constructUSR_ObjCClass(clang_getCString(className));
                            
                            class = (ChimeClass *)[self.index symbolForUSR:classUSR];

                            if (class == nil) {
                                // TODO: record error somehow
                                NSLog(@"Unable to find class for name \"%s\", USR \"%s\", when attempting to create category for name \"%s\", USR \"%s\"",
                                      clang_getCString(className), clang_getCString(classUSR),
                                      clang_getCString(name), clang_getCString(USR));
                            }

                            clang_disposeString(className);
                            clang_disposeString(classUSR);
                        }
                        
                        return CXChildVisit_Break;
                    });
                    
                    if (class != nil) {
                        category = [self.index createCategoryForName:name USR:USR class:class];
                        if (category == nil) {
                            // TODO: record error somehow
                            NSLog(@"Unable to create category for name \"%s\", USR \"%s\"", clang_getCString(name), clang_getCString(USR));
                        }
                    }
                    
                    clang_disposeString(name);
                }
            }
        }
        
        clang_disposeString(topLevelDeclFilename);
        
        return CXChildVisit_Continue;
    });
}

@end
