//
//  XcodebuildTask.m
//  Chime Project Indexer
//
//  Created by Andrew Pontious on 1/31/14.
//  Copyright (c) 2014 Andrew Pontious.
//  Some rights reserved: http://opensource.org/licenses/mit-license.php
//

#import "XcodebuildTask.h"

@interface XcodebuildTask ()

@property (nonatomic) NSURL *projectOrWorkspaceFileURL;

@property (nonatomic) NSTask *task;
@property (nonatomic) NSString *output;
@property (nonatomic) BOOL readFinished;
@property (nonatomic) BOOL taskFinished;

@property (nonatomic, copy) void (^completionHandler)(NSString *output);

@end

@implementation XcodebuildTask

- (id)initWithProjectOrWorkspaceFileURL:(NSURL *)projectOrWorkspaceFileURL {
    self = [super init];
    
    if (self != nil) {
        _projectOrWorkspaceFileURL = projectOrWorkspaceFileURL;
    }

    return self;
}

- (void)launchWithArguments:(NSArray *)arguments completionHandler:(void (^)(NSString *output))completionHandler {
    self.completionHandler = completionHandler;
    
    self.task = [[NSTask alloc] init];
    
    // TODO: get path to Xcode, use that version, otherwise relying on command line tools being installed.
    [self.task setLaunchPath:@"/usr/bin/xcodebuild"];
    [self.task setArguments:arguments];
    [self.task setCurrentDirectoryPath:[[self.projectOrWorkspaceFileURL URLByDeletingLastPathComponent] path]];
    
    NSPipe *outputPipe = [NSPipe pipe];
    [self.task setStandardOutput:outputPipe];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(taskOutputReadCompleted:)
                                                 name:NSFileHandleReadToEndOfFileCompletionNotification
                                               object:[outputPipe fileHandleForReading]];
    [[outputPipe fileHandleForReading] readToEndOfFileInBackgroundAndNotify];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(finishedTask:)
                                                 name:NSTaskDidTerminateNotification
                                               object:self.task];
    
    // Send to dev/null!
    // Without this, I get logging like this:
    //
    //      IDELogStore: Log record's backing file ("/path/to/Project-aytjtmfnehdtkgebkondoblcarkx/Logs/Build/F79B00D7-CCD0-4A00-B566-7F2817A578B2.xcactivitylog") is missing. Skipping.
    //
    // TODO: figure out why that's happening and stop it?
    [self.task setStandardError:[NSFileHandle fileHandleWithNullDevice]];
    
    [self.task launch];
}

- (void)taskOutputReadCompleted:(NSNotification *)notification {
    NSData *data = [[notification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    
    if ([data length] > 0) {
        NSString *string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        
        if ([string length] > 0) {
            self.output = string;
        }
    }
    
    self.readFinished = YES;
    
    [self handleFinished];
}

- (void)finishedTask:(NSNotification *)notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSTaskDidTerminateNotification object:self.task];
    
    self.taskFinished = YES;
    
    [self handleFinished];
}

- (void)handleFinished {
    if (self.readFinished == YES && self.taskFinished == YES) {
        NSString *output = self.output;
        void (^completionHandler)(NSString *) = [self.completionHandler copy];
        
        // Reset for potential next time! Which might be within the completion handler!
        self.task = nil;
        self.output = nil;
        self.readFinished = NO;
        self.taskFinished = NO;
        self.completionHandler = nil;

        completionHandler(output);
    }
}

@end
