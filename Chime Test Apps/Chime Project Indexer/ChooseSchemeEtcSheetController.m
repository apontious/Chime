//
//  ChooseSchemeEtcSheetController.m
//  Chime Project Indexer
//
//  Created by Andrew Pontious on 1/31/14.
//  Copyright (c) 2014 Andrew Pontious.
//  Some rights reserved: http://opensource.org/licenses/mit-license.php
//

#import "ChooseSchemeEtcSheetController.h"

@interface ChooseSchemeEtcSheetController ()

@property (nonatomic, weak) NSDocument *document;

@property (nonatomic, weak) IBOutlet NSPanel *sheet;

@property (nonatomic, weak) IBOutlet NSMatrix *radioButtonMatrix;

@property (nonatomic, weak) IBOutlet NSTextField *schemelabel;
@property (nonatomic, weak) IBOutlet NSPopUpButton *schemesPopupButton;

@property (nonatomic, weak) IBOutlet NSTextField *targetlabel;
@property (nonatomic, weak) IBOutlet NSPopUpButton *targetsPopupButton;

@property (nonatomic, weak) IBOutlet NSTextField *configurationLabel;
@property (nonatomic, weak) IBOutlet NSPopUpButton *configurationsPopupButton;

@property (nonatomic, weak) IBOutlet NSButton *cancelButton;
@property (nonatomic, weak) IBOutlet NSButton *chooseButton;

@property (nonatomic, copy) void (^completionHandler)(BOOL didChoose, NSString *chosenSchemeName, NSString *chosenTargetName, NSString *chosenConfigurationName);

@end

@implementation ChooseSchemeEtcSheetController

- (id)initWithDocument:(NSDocument *)document {
    self = [super init];
    if (self != nil) {
        _document = document;
    }
    return self;
}

- (BOOL)schemesSelected {
    return ([self.radioButtonMatrix selectedColumn] == 0);
}
- (void)setSchemesSelected:(BOOL)schemesSelected {
    [self.radioButtonMatrix selectCellAtRow:0 column:(schemesSelected ? 0 : 1)];
}

- (void)chooseFromSchemeNames:(NSArray *)schemeNames
                  targetNames:(NSArray *)targetNames
           configurationNames:(NSArray *)configurationNames
                  forDocument:(NSDocument *)document
            completionHandler:(void (^)(BOOL didChoose, NSString *chosenSchemeName, NSString *chosenTargetName, NSString *chosenConfigurationName))completionHandler {

    const BOOL canChooseSchemeNames = (schemeNames != nil);
    const BOOL canChooseTargetEtcNames = (targetNames != nil && configurationNames != nil);
    
    if (canChooseSchemeNames == NO || canChooseTargetEtcNames == NO) {
        if (canChooseTargetEtcNames == NO) {
            if ([schemeNames count] == 1) {
                completionHandler(YES, schemeNames[0], nil, nil);
                return;
            }
        } else {
            if ([targetNames count] == 1 && [configurationNames count] == 1) {
                completionHandler(YES, nil, targetNames[0], configurationNames[0]);
                return;
            }
        }
    }

    self.document = document;
    
    [[NSBundle mainBundle] loadNibNamed:@"ChooseSchemeEtcSheet" owner:self topLevelObjects:nil];
    
    if (canChooseSchemeNames == YES) {
        [self.schemesPopupButton addItemsWithTitles:schemeNames];
    } else {
        // *Can't* choose schemes
        self.schemesSelected = NO;

        [self.radioButtonMatrix setEnabled:NO];
    }
    
    if (canChooseTargetEtcNames == YES) {
        [self.targetsPopupButton addItemsWithTitles:targetNames];
        [self.configurationsPopupButton addItemsWithTitles:configurationNames];
    } else {
        // *Can't* choose targets and configurations
        self.schemesSelected = YES;

        [self.radioButtonMatrix setEnabled:NO];
    }
    
    if (self.schemesSelected == YES) {
        self.targetsAndConfigurationsEnabled = NO;
    } else {
        self.schemesEnabled = NO;
    }
    
    self.completionHandler = completionHandler;
    
    [self.document.windowForSheet beginSheet:self.sheet completionHandler:nil];
}

- (IBAction)handleChoose:(NSButton *)sender {
    NSString *chosenSchemeName;
    NSString *chosenTargetName;
    NSString *chosenConfigurationName;
    
    if (self.schemesSelected == YES) {
        chosenSchemeName = [self.schemesPopupButton titleOfSelectedItem];
    } else {
        chosenTargetName = [self.targetsPopupButton titleOfSelectedItem];
        chosenConfigurationName = [self.configurationsPopupButton titleOfSelectedItem];
    }
    
    [self.document.windowForSheet endSheet:self.sheet];
    
    self.completionHandler(YES, chosenSchemeName, chosenTargetName, chosenConfigurationName);
}
- (IBAction)handleCancel:(NSButton *)sender {
    self.completionHandler(NO, nil, nil, nil);
    
    [self.document.windowForSheet endSheet:self.sheet];

    self.completionHandler(NO, nil, nil, nil);
}

- (void)setSchemesEnabled:(BOOL)enabled {
    NSColor *textColor = (enabled ? [NSColor controlTextColor] : [NSColor disabledControlTextColor]);
    
    [self.schemelabel setTextColor:textColor];
    [self.schemesPopupButton setEnabled:enabled];
}
- (void)setTargetsAndConfigurationsEnabled:(BOOL)enabled {
    NSColor *textColor = (enabled ? [NSColor controlTextColor] : [NSColor disabledControlTextColor]);
    
    [self.targetlabel setTextColor:textColor];
    [self.targetsPopupButton setEnabled:enabled];
    
    [self.configurationLabel setTextColor:textColor];
    [self.configurationsPopupButton setEnabled:enabled];
}

- (IBAction)handleRadioButtonChanged:(NSMatrix *)sender {
    if (self.schemesSelected == YES) {
        self.schemesEnabled = YES;
        self.targetsAndConfigurationsEnabled = NO;
    } else {
        self.schemesEnabled = NO;
        self.targetsAndConfigurationsEnabled = YES;
    }
}

@end
