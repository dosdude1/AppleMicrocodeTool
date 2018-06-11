//
//  MicrocodeEditor.h
//  Apple Microcode Tool
//
//  Created by Collin Mistr on 6/10/18.
//  Copyright (c) 2018 dosdude1 Apps. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "ROMParser.h"

@protocol MicrocodeEditorDelegate <NSObject>
@optional
-(void)microcodeEditorWillClose:(id)editor;
@end

@interface MicrocodeEditor : NSWindowController <NSTableViewDataSource, NSTableViewDelegate, NSWindowDelegate>
{
    NSMutableArray *microcodes;
}
@property (nonatomic, strong) id <MicrocodeEditorDelegate> delegate;
-(instancetype)initWithROMAtPath:(NSString *)inRomPath;
@property (strong) NSString *romPath;
@property (strong) IBOutlet NSTableView *microcodeTable;
-(BOOL)isEqualTo:(MicrocodeEditor *)object;

@end

