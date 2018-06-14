//
//  MicrocodeEditor.h
//  Apple Microcode Tool
//
//  Created by Collin Mistr on 6/10/18.
//  Copyright (c) 2018 dosdude1 Apps. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "ROMParser.h"
#include "ROMEditor.h"

typedef enum {
    errNoFreeSpace = 0,
    errInvalidMicrocodeFile = 1,
    errInvalidROMFile = 2
}err;


@protocol MicrocodeEditorDelegate <NSObject>
@optional
-(void)microcodeEditorWillClose:(id)editor;
@end

@interface MicrocodeEditor : NSWindowController <NSTableViewDataSource, NSTableViewDelegate, NSWindowDelegate, NSMenuDelegate>
{
    NSMutableArray *microcodes;
    NSMutableDictionary *replacedMicrocodes;
    long fileSize;
    char *fileBuf;
    long freeSpace;
    off_t firstBlockOffset;
    off_t secondBlockOffset;
    off_t endOffsetOfLastBlock;
    long totalBlockSize;
}
@property (nonatomic, strong) id <MicrocodeEditorDelegate> delegate;
-(instancetype)initWithROMAtPath:(NSString *)inRomPath;
@property (strong) NSString *romPath;
@property (strong) IBOutlet NSTableView *microcodeTable;
-(BOOL)isEqualTo:(MicrocodeEditor *)object;
- (IBAction)saveDocument:(id)sender;
- (IBAction)saveDocumentAs:(id)sender;
@property (strong) IBOutlet NSTextField *freeSpaceLabel;

@end

