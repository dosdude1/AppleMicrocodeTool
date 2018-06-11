//
//  AppDelegate.m
//  Apple Microcode Tool
//
//  Created by Collin Mistr on 6/10/18.
//  Copyright (c) 2018 dosdude1 Apps. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [self openROMFile:self];
}
-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}
- (IBAction)openROMFile:(id)sender
{
    NSOpenPanel *open = [[NSOpenPanel alloc] init];
    [open setTitle:@"Open ROM"];
    [open setAllowedFileTypes:@[@"bin", @"rom"]];
    [open setAllowsMultipleSelection:NO];
    NSInteger result = [open runModal];
    if (result == NSOKButton)
    {
        NSString *selectedFile = [[open URL] path];
        if (!openMCEditors)
        {
            openMCEditors = [[NSMutableArray alloc] init];
        }
        MicrocodeEditor *mce = [[MicrocodeEditor alloc] initWithROMAtPath:selectedFile];
        BOOL open = NO;
        for (MicrocodeEditor *m in openMCEditors)
        {
            if ([m isEqualTo:mce])
            {
                open = YES;
                [m.window makeKeyAndOrderFront:self];
            }
        }
        if (!open)
        {
            mce.delegate = self;
            [openMCEditors addObject:mce];
            [mce showWindow:self];
        }
    }
}
-(void)microcodeEditorWillClose:(id)editor
{
    [openMCEditors removeObject:editor];
}

@end
