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
    //[self openROMFile:self];
}
-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}
- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
    [self openFile:[NSURL URLWithString:[[filenames objectAtIndex:0] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
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
        [self openFile:[open URL]];
    }
}
-(void)openFile:(NSURL *)fileURL
{
    NSString *selectedFile = [fileURL path];
    if (!openMCEditors)
    {
        openMCEditors = [[NSMutableArray alloc] init];
    }
    MicrocodeEditor *mce = [[MicrocodeEditor alloc] initWithROMAtPath:selectedFile];
    BOOL isOpen = NO;
    for (MicrocodeEditor *m in openMCEditors)
    {
        if ([m isEqualTo:mce])
        {
            isOpen = YES;
            [m.window makeKeyAndOrderFront:self];
        }
    }
    if (!isOpen)
    {
        mce.delegate = self;
        [[NSDocumentController sharedDocumentController] noteNewRecentDocumentURL:fileURL];
        [openMCEditors addObject:mce];
        [mce showWindow:self];
    }
}
-(void)microcodeEditorWillClose:(id)editor
{
    [openMCEditors removeObject:editor];
}

@end
