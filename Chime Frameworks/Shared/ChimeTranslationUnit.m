//
//  ChimeTranslationUnit.m
//  Chime Framework
//
//  Created by Andrew Pontious on 2/1/14.
//  Copyright (c) 2014 Andrew Pontious.
//  Some rights reserved: http://opensource.org/licenses/mit-license.php
//

#import "ChimeTranslationUnit_Private.h"

#import "ChimeIndex_Private.h"
#import "NSString+ChimeFramework.h"

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

#pragma mark Standard Methods

- (id)init {
    NSAssert(NO, @"Do not call init to create a %@, use %@", [ChimeTranslationUnit class], NSStringFromSelector(@selector(initWithFileURL:arguments:index:)));
    
    return nil;
}

- (void)dealloc {
    clang_disposeTranslationUnit(_translationUnit);
}

#pragma mark Public Methods

- (instancetype)initWithFileURL:(NSURL *)fileURL arguments:(NSArray *)arguments index:(ChimeIndex *)index {
    NSParameterAssert(fileURL);
    NSParameterAssert(index);
    
    self = [super init];
    
    if (self != nil) {
        _fileURL = [fileURL copy];
        _arguments = [arguments copy];
        _index = index;
        
        [_index addTranslationUnit:self];
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

#pragma mark Private Methods

static ChimeClass *extractClassForCursor(CXCursor cursor,
                                         const enum CXCursorKind desiredSymbolKind, NSString *desiredSymbolLabel,
                                         NSString *creatingClassLabel, CXString creatingClassName, CXString creatingClassUSR,
                                         ChimeIndex *index, NSString **errorLogStringPtr) {
    
    __block ChimeClass *desiredClass;
    
    __block NSString *errorLogString;
    
    clang_visitChildrenWithBlock(cursor, ^enum CXChildVisitResult(CXCursor childCursor, CXCursor parent) {
        enum CXChildVisitResult result = CXChildVisit_Break;
        
        const enum CXCursorKind childKind = clang_getCursorKind(childCursor);
        
        if (childKind != desiredSymbolKind) {
            if (childKind == CXCursor_FirstAttr) {
                result = CXChildVisit_Continue;
            } else {
                errorLogString = [NSString stringWithFormat:@"Couldn't find initial %@ reference for %@ \"%s\", USR \"%s\", found %ld instead", desiredSymbolLabel, creatingClassLabel, clang_getCString(creatingClassName), clang_getCString(creatingClassUSR), (long)childKind];
            }
        } else {
            CXString desiredName = clang_getCursorSpelling(childCursor);
            
            // Note: clang_getCursorUSR() returns a blank string here, so we must make the USR manually ourselves.
            // Currently, what we're creating *must* be a class, because this function only handles classes.
            CXString desiredUSR = clang_constructUSR_ObjCClass(clang_getCString(desiredName));
            
            desiredClass = (ChimeClass *)[index symbolForUSR:desiredUSR];
            
            if (desiredClass == nil) {
                errorLogString = [NSString stringWithFormat:@"Unable to find %@ for name \"%s\", USR \"%s\", when attempting to create %@ for name \"%s\", USR \"%s\"",
                                  // Symbol we desire
                                  desiredSymbolLabel, clang_getCString(desiredName), clang_getCString(desiredUSR),
                                  // Class we're creating
                                  creatingClassLabel, clang_getCString(creatingClassName), clang_getCString(creatingClassUSR)];
            }
            
            clang_disposeString(desiredName);
            clang_disposeString(desiredUSR);
        }
        
        return result;
    });
    
    if (errorLogStringPtr != nil) {
        *errorLogStringPtr = errorLogString;
    }
    
    return desiredClass;
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
                    NSString *errorLogString;
                    
                    ChimeClass *superclass = extractClassForCursor(topLevelDeclCursor,
                                                                   CXCursor_ObjCSuperClassRef,
                                                                   @"superclass", // Class we desire
                                                                   @"class", name, USR, // Symbol we're creating
                                                                   self.index,
                                                                   &errorLogString);
                    
                    if (superclass == nil && [self.index isNameOfCocoaClassWithoutSuperclass:name] == NO) {
                        // TODO: record error somehow
                        NSLog(@"%@", errorLogString);
                    } else {
                        class = [self.index createClassForName:name USR:USR superclass:superclass];
                        if (class == nil) {
                            // TODO: record error somehow
                            NSLog(@"Unable to create class for name \"%s\", USR \"%s\"", clang_getCString(name), clang_getCString(USR));
                        }
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
                    NSString *errorLogString;
                    
                    ChimeClass *class = extractClassForCursor(topLevelDeclCursor,
                                                              CXCursor_ObjCClassRef,
                                                              @"class", // Class we desire
                                                              @"category", name, USR, // Symbol we're creating
                                                              self.index,
                                                              &errorLogString);
                    
                    if (class == nil) {
                        // TODO: record error somehow
                        NSLog(@"%@", errorLogString);
                    } else {
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

#pragma mark Framework Only Methods

- (void)disposeClangTranslationUnit {
    clang_disposeTranslationUnit(self.translationUnit);
    self.translationUnit = nil;
}

@end
