//
//  ChooseSchemeEtcSheetController.h
//  Chime Project Indexer
//
//  Created by Andrew Pontious on 1/31/14.
//  Copyright (c) 2014 Andrew Pontious.
//  Some rights reserved: http://opensource.org/licenses/mit-license.php
//

#import <Foundation/Foundation.h>

@class IndexDocument;

@interface ChooseSchemeEtcSheetController : NSObject

- (void)chooseFromSchemeNames:(NSArray *)schemeNames
                  targetNames:(NSArray *)targetNames
           configurationNames:(NSArray *)configurationNames
                  forDocument:(NSDocument *)document
            completionHandler:(void (^)(BOOL didChoose, NSString *chosenSchemeName, NSString *chosenTargetName, NSString *chosenConfigurationName))completionHandler;

@end
