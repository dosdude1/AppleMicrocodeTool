//
//  MicrocodeEditor.h
//  Apple Microcode Tool
//
//  Created by Collin Mistr on 6/10/18.
//  Copyright (c) 2018 dosdude1 Apps. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "ROMParser.h"

@interface MicrocodeEditor : NSWindowController <NSTableViewDataSource, NSTableViewDelegate>
{
    NSString *romPath;
    NSMutableArray *microcodes;
}
-(instancetype)initWithROMAtPath:(NSString *)inRomPath;
@property (strong) IBOutlet NSTableView *microcodeTable;

@end
