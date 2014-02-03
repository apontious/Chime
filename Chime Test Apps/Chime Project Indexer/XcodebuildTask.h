//
//  XcodebuildTask.h
//  Chime Project Indexer
//
//  Created by Andrew Pontious on 1/31/14.
//  Copyright (c) 2014 Andrew Pontious.
//  Some rights reserved: http://opensource.org/licenses/mit-license.php
//

#import <Foundation/Foundation.h>

@interface XcodebuildTask : NSObject

- (id)initWithProjectOrWorkspaceFileURL:(NSURL *)projectOrWorkspaceFileURL;

// In completionHandler, a nil output means there was an error. TODO: perhaps pass along an NSError?
// TODO: add support for timeouts.
- (void)launchWithArguments:(NSArray *)arguments completionHandler:(void (^)(NSString *output))completionHandler;

@end
