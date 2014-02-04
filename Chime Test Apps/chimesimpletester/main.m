//
//  main.m
//  chimesimpletester
//
//  Created by Andrew Pontious on 2/1/14.
//  Copyright (c) 2014 Andrew Pontious.
//  Some rights reserved: http://opensource.org/licenses/mit-license.php
//

#import <Foundation/Foundation.h>

#import <Chime/Chime.h>

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        
        if (argc != 2 || argv[1] == NULL || argv[1][0] == 0) {
            fprintf(stderr, "Usage: pass in full path to a translation unit as the only argument.\n\nThis should be a .m file with Objective-C classes that do not reference system frameworks like Foundation, only themselves and C primitives. For an example, see the MyClass.h and MyClass.m files included with the project.\n\nIf you're launching from Xcode, edit the scheme and go to Arguments tab of the Run section.\n");
            
            return 1;
        } else {
            NSURL *fileURL;
            
            NSString *filePath = [NSString stringWithUTF8String:argv[1]];
            if (filePath != nil) {
                fileURL = [NSURL fileURLWithPath:filePath];
            }
            
            if (fileURL == nil) {
                fprintf(stderr, "Error: file path \"%s\" does not appear to be valid.\n", argv[1]);
                
                return 1;
            } else {
                ChimeIndex *index = [[ChimeIndex alloc] init];
                
                ChimeTranslationUnit *tu = [[ChimeTranslationUnit alloc] initWithFileURL:fileURL
                                                                               arguments:nil
                                                                                   index:index];
                
                if ([tu parse:nil] == YES) {
                    NSLog(@"%@", [index symbols]);
                }
            }
        }
    }
    return 0;
}

