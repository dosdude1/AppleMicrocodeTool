//
//  AppDelegate.h
//  Apple Microcode Tool
//
//  Created by Collin Mistr on 6/10/18.
//  Copyright (c) 2018 dosdude1 Apps. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MicrocodeEditor.h"


@interface AppDelegate : NSObject <NSApplicationDelegate, MicrocodeEditorDelegate>
{
    NSMutableArray *openMCEditors;
}
@property (assign) IBOutlet NSWindow *window;
- (IBAction)openROMFile:(id)sender;

@end
