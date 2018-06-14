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
    
}
- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename
{
    [self openFile:[NSURL fileURLWithPath:filename]];
    return YES;
}
- (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames
{
    [self openFile:[NSURL fileURLWithPath:[filenames objectAtIndex:0]]];
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
    BOOL isOpen = NO;
    for (MicrocodeEditor *m in openMCEditors)
    {
        if ([m.romPath isEqualToString:selectedFile])
        {
            isOpen = YES;
            [m.window makeKeyAndOrderFront:self];
        }
    }
    if (!isOpen)
    {
        MicrocodeEditor *mce = [[MicrocodeEditor alloc] initWithROMAtPath:selectedFile];
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
