//
//  MicrocodeEditor.m
//  Apple Microcode Tool
//
//  Created by Collin Mistr on 6/10/18.
//  Copyright (c) 2018 dosdude1 Apps. All rights reserved.
//

#import "MicrocodeEditor.h"

@interface MicrocodeEditor ()

@end

@implementation MicrocodeEditor

- (id)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    [self.window setDelegate:self];
    [self.window setTitleWithRepresentedFilename:self.romPath];
    [self.window setAnimationBehavior:NSWindowAnimationBehaviorDocumentWindow];
    [self.microcodeTable setDelegate:self];
    [self.microcodeTable setDataSource:self];
}
-(id)init
{
    self = [super initWithWindowNibName:@"MicrocodeEditor"];
    
    return self;
}
-(instancetype)initWithROMAtPath:(NSString *)inRomPath
{
    self = [self init];
    self.romPath = inRomPath;
    [self parseROM];
    return self;
}
-(void)parseROM
{
    microcodes = [[NSMutableArray alloc] init];
    FILE *rom = fopen([self.romPath UTF8String], "rb");
    long fsize;
	fseek(rom, 0, SEEK_END);
	fsize = ftell(rom);
	fseek(rom, 0, SEEK_SET);
    char *buf = malloc(fsize);
    fread(buf, 1, fsize, rom);
    fclose(rom);
    off_t offset = locateMicrocodeBlockOffset(buf, fsize, 0);
    NSLog(@"First offset: %lld", offset);
    offset = locateMicrocodeBlockOffset(buf, fsize, 1);
    NSLog(@"Second offset: %lld", offset);
    microcode_entry entries[50] = { 0 };
    getMicrocodeEntries(buf, fsize, entries);
    for (int i=0; i<50; i++)
    {
        if (entries[i].cpuid != 0)
        {
            NSString *date = [NSString stringWithFormat:@"%02X%02X/%02X/%02X", entries[i].date.yearpre, entries[i].date.yearsuf, entries[i].date.month, entries[i].date.day];
            NSLog(@"Date is %@", date);
            [microcodes addObject:@{@"cpuid": [NSNumber numberWithUnsignedInt:entries[i].cpuid], @"revision":[NSNumber numberWithUnsignedInt:entries[i].updateRev], @"checksum":[NSNumber numberWithUnsignedInt:entries[i].crc], @"date": date, @"platformid": [NSString stringWithFormat:@"%s", entries[i].platformID]}];
        }
    }
    printf("Entry 1 CPUID: %X\n", entries[0].cpuid);
    [self.microcodeTable reloadData];
}
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return [microcodes count];
}
- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if ([[tableColumn identifier] isEqualToString:@"cpuid"])
    {
        return [NSString stringWithFormat:@"%lX", [[[microcodes objectAtIndex:row] objectForKey:@"cpuid"] unsignedIntegerValue]];
    }
    else if ([[tableColumn identifier] isEqualToString:@"revision"])
    {
        return [NSString stringWithFormat:@"%02lX", [[[microcodes objectAtIndex:row] objectForKey:@"revision"] unsignedIntegerValue]];
    }
    else if ([[tableColumn identifier] isEqualToString:@"revdate"])
    {
        return [NSString stringWithFormat:@"%@", [[microcodes objectAtIndex:row] objectForKey:@"date"]];
    }
    else if ([[tableColumn identifier] isEqualToString:@"checksum"])
    {
        return [NSString stringWithFormat:@"%08lX", [[[microcodes objectAtIndex:row] objectForKey:@"checksum"] unsignedIntegerValue]];
    }
    else if ([[tableColumn identifier] isEqualToString:@"platformid"])
    {
        return [NSString stringWithFormat:@"%@", [[microcodes objectAtIndex:row] objectForKey:@"platformid"]];
    }
    return nil;
}
-(BOOL)isEqualTo:(MicrocodeEditor *)object
{
    return ([object.romPath isEqualToString:self.romPath]);
}
- (void)windowWillClose:(NSNotification *)notification
{
    [self.delegate microcodeEditorWillClose:self];
}

@end
