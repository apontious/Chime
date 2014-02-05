//
//  Document.m
//  Chime Project Indexer
//
//  Created by Andrew Pontious on 1/30/14.
//  Copyright (c) 2014 Andrew Pontious.
//  Some rights reserved: http://opensource.org/licenses/mit-license.php
//

#import "IndexDocument.h"

#import "ChooseSchemeEtcSheetController.h"
#import "XcodeBuildTask.h"

#import <Chime/Chime.h>

@interface IndexDocument () <NSTableViewDataSource>

@property (nonatomic) NSURL *projectOrWorkspaceFileURL;

@property (nonatomic) XcodebuildTask *xcodebuildTask;

// Shared: schemes

@property (nonatomic) NSArray *schemeNames;

@property (nonatomic) NSString *chosenSchemeName;

// Project-only: targets and configurations

@property (nonatomic) NSArray *projectTargetNames;
@property (nonatomic) NSArray *projectConfigurationNames;

@property (nonatomic) NSString *chosenProjectTargetName;
@property (nonatomic) NSString *chosenProjectConfigurationName;

@property (nonatomic) NSArray *compilationUnitURLs;

@property (nonatomic) ChooseSchemeEtcSheetController *chooseSchemeEtcSheetController;

@property (nonatomic) ChimeIndex *index;

@property (nonatomic) NSArray *translationUnits;

@property (nonatomic, weak) IBOutlet NSTableView *tableView;

@end

@implementation IndexDocument

- (id)init
{
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
    }
    return self;
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"IndexDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)controller
{
    [super windowControllerDidLoadNib:controller];

    // Yes, using performSelector is a code smell.
    // But this is the most convenient accessor method for when a document first opens, and if you call it synchronously, the Open panel won't be a sheet on the window, but will open modally, even tough self.window is available.
    [self performSelectorOnMainThread:@selector(handleStage1_choosingProjectOrWorkspaceFileURL) withObject:nil waitUntilDone:NO];
}
 
+ (BOOL)autosavesInPlace
{
    return YES;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    NSData *data = [@"foo" dataUsingEncoding:NSUTF8StringEncoding];
    
    return data;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    return YES;
}

#pragma mark -

- (BOOL)isWorkspace {
    return ([[self.projectOrWorkspaceFileURL pathExtension] isEqualToString:@"xcworkspace"] == YES);
}
- (BOOL)isProject {
    return (self.isWorkspace == NO);
}

- (void)handleStage1_choosingProjectOrWorkspaceFileURL {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowedFileTypes:@[@"xcworkspace", @"xcodeproj"]];
    [openPanel setPrompt:NSLocalizedString(@"Choose Project or Workspace", @"Title of default button in file window's initial sheet to choose a project or workspace")];
    
    NSWindow *window = [self windowForSheet];
    
    __weak typeof(self) weakSelf = self;
    
    [openPanel beginSheetModalForWindow:window completionHandler:^(NSInteger result) {
        typeof(self) strongSelf = weakSelf;
        if (strongSelf != nil) {
            if (result == NSFileHandlingPanelCancelButton || [[openPanel URLs] count] == 0) {
                // TODO: close document
                NSLog(@"User canceled project/workspace choice.");
            } else if (result == NSFileHandlingPanelOKButton) {
                strongSelf.projectOrWorkspaceFileURL = [openPanel URLs][0];

                [strongSelf handleStage2_determiningSchemesOrProjectTargetsAndConfigurations];
            }
        }
    }];
}

- (void)handleStage2_determiningSchemesOrProjectTargetsAndConfigurations {
    const BOOL needToDetermineWorkspace = (self.isWorkspace == YES && self.schemeNames == nil);
    
    self.xcodebuildTask = [[XcodebuildTask alloc] initWithProjectOrWorkspaceFileURL:self.projectOrWorkspaceFileURL];
    
    NSArray *arguments = @[@"-list",
                           (needToDetermineWorkspace ? @"-workspace" : @"-project"),
                           [self.projectOrWorkspaceFileURL lastPathComponent]];
    
    __weak typeof(self) weakSelf = self;
    
    [self.xcodebuildTask launchWithArguments:arguments completionHandler:^(NSString *output) {
        typeof(self) strongSelf = weakSelf;
        if (strongSelf != nil) {
            NSError *error;
            
            if ([output length] == 0) {
                // TODO: set error
                // "Output of xcodebuild, called with ‘-lists’ option, is blank, so project/workspace "X" cannot be indexed."
                NSLog(@"Output of xcodebuild, called with ‘-lists’ option, is blank, so project/workspace \"%@\" cannot be indexed.", [strongSelf.projectOrWorkspaceFileURL lastPathComponent]);
            } else {
                strongSelf.schemeNames = namesInStringForTitle(output, @"Schemes");
                
                if (strongSelf.isWorkspace) {
                    if (strongSelf.schemeNames == nil) {
                        // TODO: set error
                        // "Workspace "X" has no schemes and so cannot be indexed."
                        NSLog(@"Workspace \"%@\" has no schemes and so cannot be indexed.", [strongSelf.projectOrWorkspaceFileURL lastPathComponent]);
                    }
                } else if (strongSelf.isProject) {
                    strongSelf.projectTargetNames = namesInStringForTitle(output, @"Targets");
                    strongSelf.projectConfigurationNames = namesInStringForTitle(output, @"Build Configurations");
                    
                    if ([strongSelf.projectTargetNames count] == 0) {
                        // TODO: set error
                        // "Project "X" has no targets and so cannot be indexed."
                        NSLog(@"Project \"%@\" has no targets and so cannot be indexed.", [strongSelf.projectOrWorkspaceFileURL lastPathComponent]);
                    } else if ([strongSelf.projectConfigurationNames count] == 0) {
                        // TODO: set error
                        // "Project "X" has no build configurations and so cannot be indexed."
                        NSLog(@"Project \"%@\" has no build configurations and so cannot be indexed.", [strongSelf.projectOrWorkspaceFileURL lastPathComponent]);
                    }
                }
            }

            if (error) {
                // TODO: tell user there was a problem, close document
                NSLog(@"There was a problem: %@", error);
            } else {
                [strongSelf handleStage3_choosingSchemeOrProjectTargetAndConfiguration];
            }
        }
    }];

}

// nil result means parsing error.
static NSArray *namesInStringForTitle(NSString *string, NSString *title) {
    NSArray *result;
    
    // TODO: Use NSRegularExpression instead of relying on exact number of spaces in output format.
    // There is *FAR* too much exact matching going on here.
    // *HOWEVER*, you can't just trim all whitespace from names before and after, because if a name starts or ends with, say, a space, it is *NOT* put in quotes. You can only tell the whitespace by counting the expected indent spaces and *ONLY* removing those.

    NSString *titlePlus = [NSString stringWithFormat:@"\n    %@:\n        ", title];
    
    const NSRange preRange = [string rangeOfString:titlePlus];
    if (preRange.length > 0) {
        NSRange postRange = [string rangeOfString:@"\n\n" options:0 range:NSMakeRange(NSMaxRange(preRange), [string length] - NSMaxRange(preRange))];
        if (postRange.length == 0) {
            postRange = NSMakeRange([string length] - 1, 1);
        }
        if (postRange.length > 0) {
            NSString *substring = [string substringWithRange:NSMakeRange(NSMaxRange(preRange), postRange.location - NSMaxRange(preRange))];
            result = [substring componentsSeparatedByString:@"\n        "];
        }
    }

    return result;
}

- (void)handleStage3_choosingSchemeOrProjectTargetAndConfiguration {
    self.chooseSchemeEtcSheetController = [[ChooseSchemeEtcSheetController alloc] init];
    
    __weak typeof(self) weakSelf = self;
    
    [self.chooseSchemeEtcSheetController chooseFromSchemeNames:self.schemeNames
                                                   targetNames:self.projectTargetNames
                                            configurationNames:self.projectConfigurationNames
                                                   forDocument:self
                                             completionHandler:^(BOOL didChoose, NSString *chosenSchemeName, NSString *chosenTargetName, NSString *chosenConfigurationName) {
        typeof(self) strongSelf = weakSelf;
        if (strongSelf != nil) {
            if (didChoose == NO) {
                // TODO: close document
                NSLog(@"User canceled scheme/target+build configuration choice.");
            } else {
                strongSelf.chosenSchemeName = chosenSchemeName;
                strongSelf.chosenProjectTargetName = chosenTargetName;
                strongSelf.chosenProjectConfigurationName = chosenConfigurationName;
                
                [strongSelf handleStage4_determiningCompilationUnitURLS];
            }
        }
    }];
}

- (NSArray *)standardXcodebuildArguments {
    NSMutableArray *result = [NSMutableArray array];

    NSString *fileName = [self.projectOrWorkspaceFileURL lastPathComponent];
    
    if (self.isProject) {
        [result addObjectsFromArray:@[@"-project", fileName]];
        
        if (self.chosenProjectTargetName != nil) {
            [result addObjectsFromArray:@[@"-target", self.chosenProjectTargetName, @"-configuration", self.chosenProjectConfigurationName]];
        } else {
            [result addObjectsFromArray:@[@"-scheme", self.chosenSchemeName]];
        }
    } else {
        [result addObjectsFromArray:@[@"-workspace", fileName, @"-scheme", self.chosenSchemeName]];
    }
    
    return result;
}

- (void)handleStage4_determiningCompilationUnitURLS {

    // TODO: put up spinner in document while this is going on? Put labels? "Cleaning…", "Building…" "Indexing…". Geeks will like that.
    
    // Clean first so everything will be outputted when we build.
    NSMutableArray *arguments = [NSMutableArray array];
    
    [arguments addObjectsFromArray:[self standardXcodebuildArguments]];
    [arguments addObject:@"clean"];
    
    __weak typeof(self) weakSelf = self;
    
    [self.xcodebuildTask launchWithArguments:arguments completionHandler:^(NSString *output) {
        typeof(self) strongSelf = weakSelf;
        if (strongSelf != nil) {
            if ([output rangeOfString:@"** CLEAN SUCCEEDED **"].length == 0) {
                // TODO: tell user there was a problem, close document
                NSLog(@"Clean did not succeed.\n%@", output);
            } else {
                
                // Now build and capture the output.
                NSMutableArray *arguments = [NSMutableArray array];
                
                [arguments addObjectsFromArray:[strongSelf standardXcodebuildArguments]];
                [arguments addObjectsFromArray:@[@"build", @"-dry-run"]];
                
                [strongSelf.xcodebuildTask launchWithArguments:arguments completionHandler:^(NSString *output) {
                    typeof(self) strongSelf = weakSelf;
                    if (strongSelf != nil) {
                        if ([output rangeOfString:@"** BUILD SUCCEEDED **" options:NSBackwardsSearch].length == 0) {
                            // TODO: tell user there was a problem, close document
                            NSLog(@"Build did not succeed.\n%@", output);
                        } else {
                            strongSelf.index = [[ChimeIndex alloc] init];
                            
                            strongSelf.translationUnits = [strongSelf translationUnitsFromCompilationOutput:output];
                            if (strongSelf.translationUnits == nil) {
                                // TODO: tell user there was a problem, close document
                                NSLog(@"No translation units were found from build output.");
                            } else {
                                [strongSelf handleStage5_parsingTranslationUnits];
                            }
                        }
                    }
                }];
            }
        }
    }];
}

static NSMutableArray *argumentsFromSingleString(NSString *singleString) {
    NSArray *strings = [singleString componentsSeparatedByString:@" "];
    
    NSMutableArray *result = [NSMutableArray arrayWithCapacity:[strings count]];
    
    for (NSInteger i = 0; i < [strings count]; i++) {
        NSString *string = strings[i];
        
        while ([string hasSuffix:@"\\"] == YES && [string hasSuffix:@"\\\\"] == NO) {
            string = [NSString stringWithFormat:@"%@ %@", [string substringToIndex:[string length] - 1], strings[i+1]];
            i++;
        }
        
        [result addObject:string];
    }
    
    return result;
}

- (NSArray *)translationUnitsFromCompilationOutput:(NSString *)compilationOutput {
    NSMutableArray *result = [NSMutableArray new];
    
    NSInteger location = 0;
    
    while (location != NSNotFound) {
        NSRange compileCRange = [compilationOutput rangeOfString:@"CompileC " options:0 range:NSMakeRange(location, [compilationOutput length] - location)];
        
        if (compileCRange.length == 0) {
            // No more compilation lines, stop
            location = NSNotFound;
        } else {
            NSRange doubleReturnRange = [compilationOutput rangeOfString:@"\n\n" options:0 range:NSMakeRange(NSMaxRange(compileCRange), [compilationOutput length] - NSMaxRange(compileCRange))];
            
            if (doubleReturnRange.length == 0) {
                // Unexpected content, stop
                // TODO: provide error
                NSLog(@"Unexpected content in build output, can't find two returns after \"CompileC\"");
                location = NSNotFound;
            } else {
                // FROM HERE ON, we know how big an area we're dealing with, so we can continue loop even on further failures.
                location = NSMaxRange(doubleReturnRange);

                const NSRange compileLinesRange = NSMakeRange(compileCRange.location, NSMaxRange(doubleReturnRange) - compileCRange.location);
                
                // ASSUMPTION: clang tool file path will end with this. I want to use something more than "clang" because it's possible that that string might be elsewhere in the settings, a file path, for example.
                // But I don't want to search returns, because Xcode.app path may contain spaces.
                // Surer method: count spaces from beginning, but discount escaped spaces.
                const NSRange clangRange = [compilationOutput rangeOfString:@"xctoolchain/usr/bin/clang " options:NSBackwardsSearch range:compileLinesRange];
                if (clangRange.length == 0) {
                    // Unexpected content
                    // TODO: provide error
                    NSLog(@"Unexpected content in build output, can't find \"xctoolchain/usr/bin/clang \"");
                } else {
                    NSMutableArray *arguments = argumentsFromSingleString([compilationOutput substringWithRange:NSMakeRange(NSMaxRange(clangRange), doubleReturnRange.location - NSMaxRange(clangRange))]);
                    
                    if ([arguments count] <= 4 || [arguments[[arguments count] - 2] isEqual:@"-o"] == NO || [arguments[[arguments count] - 4] isEqual:@"-c"] == NO) {
                        // Unexpected content
                        // TODO: provide error
                        NSLog(@"Unexpected content in build output, can't find \"-c\" entry or \"-o\" entry");
                    } else {
                        NSURL *fileURL = [NSURL fileURLWithPath:arguments[[arguments count] - 3]];
                        
                        [arguments removeObjectsInRange:NSMakeRange([arguments count] - 4, 4)];
                        
                        ChimeTranslationUnit *tu = [[ChimeTranslationUnit alloc] initWithFileURL:fileURL arguments:arguments index:self.index];
                        if (tu == nil) {
                            // TODO: provide error
                            NSLog(@"Couldn't create translation unit for file \"%@\"", [fileURL path]);
                        } else {
                            [result addObject:tu];
                        }
                    }
                }
            }
        }
    }
    
    return result;
}

- (void)handleStage5_parsingTranslationUnits {
    for (ChimeTranslationUnit *tu in self.translationUnits) {
        NSError *error;
        
        if ([tu parse:&error] == NO) {
            // TODO: inform user of problem. Stop?
            NSLog(@"Unable to parse translation unit for file \"%@\": %@", tu.fileURL, error);
            break;
        } else {
            
        }
    }
    
    [self.tableView reloadData];
}

#pragma mark NSTableViewDataSource Methods

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [self.index.symbols count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    id result = nil;
    
    NSArray *symbols = self.index.symbols;
    
    if (row < [symbols count]) {
        ChimeSymbol *symbol = symbols[row];
        
        if ([[tableColumn identifier] isEqualToString:@"name"]) {
            result = symbol.fullName;
        } else if ([[tableColumn identifier] isEqualToString:@"type"]) {
            result = symbol.userVisibleTypeString;
        }
    }
    
    return result;
}

@end
