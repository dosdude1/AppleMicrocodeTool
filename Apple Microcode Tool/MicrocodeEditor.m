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
    [[self microcodeTable] registerForDraggedTypes:[NSArray arrayWithObject:(NSString*)kUTTypeFileURL]];
    [self setUpMenu];
    [self updateUIWithFreeSpace];
}
- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id < NSDraggingInfo >)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
    //get the file URLs from the pasteboard
    NSPasteboard* pb = info.draggingPasteboard;
    
    //list the file type UTIs we want to accept
    NSArray* acceptedTypes = [NSArray arrayWithObject:(NSString*)kUTTypeData];
    
    NSArray* urls = [pb readObjectsForClasses:[NSArray arrayWithObject:[NSURL class]]
                                      options:[NSDictionary dictionaryWithObjectsAndKeys:
                                               [NSNumber numberWithBool:YES],NSPasteboardURLReadingFileURLsOnlyKey,
                                               acceptedTypes, NSPasteboardURLReadingContentsConformToTypesKey,
                                               nil]];
    
    //only allow drag if there is exactly one file
    if(urls.count != 1)
        return NSDragOperationNone;
    
    return NSDragOperationCopy;
}
- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id <NSDraggingInfo>)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
    NSPasteboard* pboard = [info draggingPasteboard];
    NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
    [self addMicrocodeFromFileAtPath:[files objectAtIndex:0] toIndex:row];
    
    
    return YES;
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
-(void)setUpMenu
{
    NSMenu *contextMenu = [[NSMenu alloc] init];
    NSMenuItem *addItem = [[NSMenuItem alloc] initWithTitle:@"Add Microcode..." action:@selector(addMicrocode:) keyEquivalent:@""];
    [contextMenu addItem:addItem];
    NSMenuItem *deleteItem = [[NSMenuItem alloc] initWithTitle:@"Delete Microcode" action:@selector(removeMicrocode:) keyEquivalent:@""];
    [contextMenu addItem:deleteItem];
    NSMenuItem *extractItem = [[NSMenuItem alloc] initWithTitle:@"Extract Microcode..." action:@selector(extractMicrocode:) keyEquivalent:@""];
    [contextMenu addItem:extractItem];
    [contextMenu addItem:[NSMenuItem separatorItem]];
    NSMenuItem *cancelItem = [[NSMenuItem alloc] initWithTitle:@"Cancel Action" action:@selector(cancelAction:) keyEquivalent:@""];
    [contextMenu addItem:cancelItem];
    [self.microcodeTable setMenu:contextMenu];
    [contextMenu setDelegate:self];
    [contextMenu setAutoenablesItems:NO];
}
-(void)parseROM
{
    [self.window setDocumentEdited:NO];
    microcodes = [[NSMutableArray alloc] init];
    FILE *rom = fopen([self.romPath UTF8String], "rb");
    long fsize;
	fseek(rom, 0, SEEK_END);
	fsize = ftell(rom);
	fseek(rom, 0, SEEK_SET);
    fileBuf = malloc(fsize);
    fread(fileBuf, 1, fsize, rom);
    fclose(rom);
    fileSize = fsize;
    firstBlockOffset = locateMicrocodeBlockOffset(fileBuf, fsize, 0);
    if (firstBlockOffset == -1)
    {
        firstBlockOffset = locateMicrocodeBlockOffsetUsingZeroGUID(fileBuf, fsize, 0);
        if (firstBlockOffset == -1)
        {
            [self handleError:errInvalidROMFile];
            return;
        }
        secondBlockOffset = -1;
    }
    else
    {
        secondBlockOffset = locateMicrocodeBlockOffset(fileBuf, fsize, 1);
    }
    endOffsetOfLastBlock = locateEndOffsetOfLastSection(fileBuf, fsize);
    if (secondBlockOffset != -1)
    {
        totalBlockSize = endOffsetOfLastBlock - secondBlockOffset;
    }
    else
    {
        totalBlockSize = endOffsetOfLastBlock - firstBlockOffset;
    }
    
    microcode_entry entries[50] = { 0 };
    freeSpace = getMicrocodeEntries(fileBuf, fsize, entries);
    if (freeSpace < 1)
    {
        freeSpace = totalBlockSize;
    }
    for (int i=0; i<50; i++)
    {
        if (entries[i].cpuid != 0)
        {
            NSString *date = [NSString stringWithFormat:@"%02X%02X/%02X/%02X", entries[i].date.yearpre, entries[i].date.yearsuf, entries[i].date.month, entries[i].date.day];
            [microcodes addObject:[NSMutableDictionary dictionaryWithDictionary:@{@"cpuid": [NSNumber numberWithUnsignedInt:entries[i].cpuid], @"revision":[NSNumber numberWithUnsignedInt:entries[i].updateRev], @"checksum":[NSNumber numberWithUnsignedInt:entries[i].crc], @"date": date, @"platformid": [NSString stringWithFormat:@"%s", entries[i].platformID], @"offset":[NSNumber numberWithUnsignedInt:entries[i].offset], @"size":[NSNumber numberWithUnsignedInt:entries[i].size], @"action":@"", @"contentFile":@""}]];
        }
    }
    [self updateUIWithFreeSpace];
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
        return [NSString stringWithFormat:@"%02lX (%lu)", [[[microcodes objectAtIndex:row] objectForKey:@"revision"] unsignedIntegerValue], [[[microcodes objectAtIndex:row] objectForKey:@"revision"] unsignedIntegerValue]];
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
    else if ([[tableColumn identifier] isEqualToString:@"offset"])
    {
        NSUInteger offset = [[[microcodes objectAtIndex:row] objectForKey:@"offset"] unsignedIntegerValue];
        if (offset != 0)
        {
            return [NSString stringWithFormat:@"%02lX", offset];
        }
        return @"-";
    }
    else if ([[tableColumn identifier] isEqualToString:@"size"])
    {
        return [NSString stringWithFormat:@"%02lX (%lu KB)", [[[microcodes objectAtIndex:row] objectForKey:@"size"] unsignedIntegerValue], [[[microcodes objectAtIndex:row] objectForKey:@"size"] unsignedIntegerValue]/1024];
    }
    else if ([[tableColumn identifier] isEqualToString:@"action"])
    {
        return [[microcodes objectAtIndex:row] objectForKey:@"action"];
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
-(BOOL)windowShouldClose:(id)sender
{
    if ([self.window isDocumentEdited])
    {
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:[NSString stringWithFormat:@"Do you want to save the changes made to the document \"%@\"?", [self.romPath lastPathComponent]]];
        [alert setInformativeText:@"Your changes will be lost if you don’t save them."];
        [alert addButtonWithTitle:@"Save"];
        [alert addButtonWithTitle:@"Cancel"];
        [alert addButtonWithTitle:@"Don't Save"];
        [alert beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse returnHandler) {
            switch (returnHandler)
            {
                case NSAlertFirstButtonReturn:
                    [self saveFileToPath:self.romPath];
                    [self.window close];
                    break;
                case NSAlertThirdButtonReturn:
                    [self.window close];
                    break;
            }
        }];
        return NO;
    }
    return YES;
}
- (void)menuNeedsUpdate:(NSMenu *)menu
{
    NSInteger clickedRow=[self.microcodeTable clickedRow];
    if (clickedRow == -1)
    {
        clickedRow=[self.microcodeTable selectedRow];
    }
    if (clickedRow > -1)
    {
        [[self.microcodeTable.menu itemAtIndex:1] setEnabled:YES];
        [[self.microcodeTable.menu itemAtIndex:2] setEnabled:YES];
        if (![[[microcodes objectAtIndex:clickedRow] objectForKey:@"action"] isEqualToString:@""])
        {
            [[self.microcodeTable.menu itemAtIndex:4] setEnabled:YES];
        }
        else
        {
            [[self.microcodeTable.menu itemAtIndex:4] setEnabled:NO];
        }
    }
    else
    {
        [[self.microcodeTable.menu itemAtIndex:1] setEnabled:NO];
        [[self.microcodeTable.menu itemAtIndex:2] setEnabled:NO];
        [[self.microcodeTable.menu itemAtIndex:4] setEnabled:NO];
    }
}
-(void)updateDocumentEdited
{
    BOOL edited = NO;
    for (NSDictionary *microcode in microcodes)
    {
        if (![[microcode objectForKey:@"action"] isEqualToString:@""])
        {
            edited = YES;
        }
    }
    if (edited)
    {
        [self.window setDocumentEdited:YES];
    }
    else
    {
        [self.window setDocumentEdited:NO];
    }
}
- (IBAction)saveDocument:(id)sender
{
    [self saveFileToPath:self.romPath];
}
- (IBAction)saveDocumentAs:(id)sender
{
    NSSavePanel *save = [[NSSavePanel alloc] init];
    [save setTitle:@"Save ROM"];
    [save setPrompt:@"Save ROM"];
    [save setAllowedFileTypes:@[@"bin"]];
    [save beginSheetModalForWindow:self.window completionHandler:^(NSInteger result){
        if (result == NSOKButton)
        {
            NSString *path = [[save URL] path];
            [self saveFileToPath:path];
        }
    }];
}
-(void)saveFileToPath:(NSString *)path
{
    char *buf = malloc(fileSize);
    for (int i=0; i<fileSize; i++)
    {
        buf[i] = fileBuf[i];
    }
    clearSection(buf, firstBlockOffset, totalBlockSize);
    if (secondBlockOffset > 1)
    {
        clearSection(buf, secondBlockOffset, totalBlockSize);
    }
    off_t lastOffset = firstBlockOffset - 1;
    for (NSDictionary *microcode in microcodes)
    {
        if ([[microcode objectForKey:@"action"] isEqualToString:@""])
        {
            long size = [[microcode objectForKey:@"size"] unsignedIntegerValue];
            off_t mcOffset = [[microcode objectForKey:@"offset"] unsignedIntegerValue];
            lastOffset = appendData(fileBuf, buf, mcOffset, lastOffset + 1, size);
        }
        else if ([[microcode objectForKey:@"action"] isEqualToString:@"Replace"] || [[microcode objectForKey:@"action"] isEqualToString:@"Add"])
        {
            char *contentBuf;
            NSString *addFilePath = [microcode objectForKey:@"contentFile"];
            FILE *rom = fopen([addFilePath UTF8String], "rb");
            long fsize;
            fseek(rom, 0, SEEK_END);
            fsize = ftell(rom);
            fseek(rom, 0, SEEK_SET);
            contentBuf = malloc(fsize);
            fread(contentBuf, 1, fsize, rom);
            fclose(rom);
            lastOffset = appendData(contentBuf, buf, 0, lastOffset + 1, fsize);
        }
    }
    if (secondBlockOffset != -1)
    {
        off_t lastOffset = secondBlockOffset - 1;
        for (NSDictionary *microcode in microcodes)
        {
            if ([[microcode objectForKey:@"action"] isEqualToString:@""])
            {
                long size = [[microcode objectForKey:@"size"] unsignedIntegerValue];
                off_t mcOffset = [[microcode objectForKey:@"offset"] unsignedIntegerValue];
                lastOffset = appendData(fileBuf, buf, mcOffset, lastOffset + 1, size);
            }
            else if ([[microcode objectForKey:@"action"] isEqualToString:@"Replace"] || [[microcode objectForKey:@"action"] isEqualToString:@"Add"])
            {
                char *contentBuf;
                NSString *addFilePath = [microcode objectForKey:@"contentFile"];
                FILE *rom = fopen([addFilePath UTF8String], "rb");
                long fsize;
                fseek(rom, 0, SEEK_END);
                fsize = ftell(rom);
                fseek(rom, 0, SEEK_SET);
                contentBuf = malloc(fsize);
                fread(contentBuf, 1, fsize, rom);
                fclose(rom);
                lastOffset = appendData(contentBuf, buf, 0, lastOffset + 1, fsize);
            }
        }
    }
    FILE *save = fopen([path UTF8String], "wb");
    fwrite(buf, 1, fileSize, save);
    fclose(save);
    self.romPath = path;
    [self parseROM];
    [self.window setTitleWithRepresentedFilename:self.romPath];
    [self updateUIWithFreeSpace];
}
-(void)updateUIWithFreeSpace
{
    [self.freeSpaceLabel setStringValue:[NSString stringWithFormat:@"Free Space in Microcode Section: %02lX (%ld KB)", freeSpace, freeSpace/1024]];
}
-(void)cancelAction:(id)sender
{
    NSInteger clickedRow=[self.microcodeTable clickedRow];
    if (clickedRow == -1)
    {
        clickedRow=[self.microcodeTable selectedRow];
    }
    NSIndexSet *clickedRows=[self.microcodeTable selectedRowIndexes];
    if (clickedRow>-1 && clickedRows.count<=1)
    {
        NSString *action = [[microcodes objectAtIndex:clickedRow] objectForKey:@"action"];
        if ([action isEqualToString:@"Remove"])
        {
            freeSpace -= [[[microcodes objectAtIndex:clickedRow] objectForKey:@"size"] unsignedIntValue];
            [[microcodes objectAtIndex:clickedRow] setObject:@"" forKey:@"action"];
            for (int i = 0; i<microcodes.count; i++)
            {
                if ([[[microcodes objectAtIndex:i] objectForKey:@"action"] isEqualToString:@"Replace"])
                {
                    freeSpace += [[[microcodes objectAtIndex:i] objectForKey:@"size"] unsignedIntegerValue];
                    [microcodes replaceObjectAtIndex:i withObject:[replacedMicrocodes objectForKey:[NSNumber numberWithInteger:i]]];
                    [replacedMicrocodes removeObjectForKey:[NSNumber numberWithInteger:i]];
                    freeSpace -= [[[microcodes objectAtIndex:i] objectForKey:@"size"] unsignedIntegerValue];
                }
                else if ([[[microcodes objectAtIndex:i] objectForKey:@"action"] isEqualToString:@"Add"])
                {
                    freeSpace += [[[microcodes objectAtIndex:i] objectForKey:@"size"] unsignedIntegerValue];
                    [microcodes removeObjectAtIndex:i];
                }
            }
            [self updateUIWithFreeSpace];
        }
        else if ([action isEqualToString:@"Replace"])
        {
            freeSpace += [[[microcodes objectAtIndex:clickedRow] objectForKey:@"size"] unsignedIntegerValue];
            [microcodes replaceObjectAtIndex:clickedRow withObject:[replacedMicrocodes objectForKey:[NSNumber numberWithInteger:clickedRow]]];
            [replacedMicrocodes removeObjectForKey:[NSNumber numberWithInteger:clickedRow]];
            freeSpace -= [[[microcodes objectAtIndex:clickedRow] objectForKey:@"size"] unsignedIntegerValue];
            [self updateUIWithFreeSpace];
        }
        else if ([action isEqualToString:@"Add"])
        {
            freeSpace += [[[microcodes objectAtIndex:clickedRow] objectForKey:@"size"] unsignedIntegerValue];
            [microcodes removeObjectAtIndex:clickedRow];
            [self updateUIWithFreeSpace];
        }
    }
    [self.microcodeTable reloadData];
    [self updateDocumentEdited];
}
-(void)removeMicrocode:(id)sender
{
    NSIndexSet *indices=[self.microcodeTable selectedRowIndexes];
    if (indices.count >= 1)
    {
        NSUInteger lastIndex=[indices firstIndex];
        for (int i=0; i<indices.count; i++)
        {
            if ([[[microcodes objectAtIndex:lastIndex] objectForKey:@"action"] isEqualToString:@""])
            {
                [[microcodes objectAtIndex:lastIndex] setObject:@"Remove" forKey:@"action"];
                freeSpace += [[[microcodes objectAtIndex:lastIndex] objectForKey:@"size"] unsignedIntValue];
                //[(NSTextFieldCell *)[self.microcodeTable preparedCellAtColumn:7 row:lastIndex] setTextColor:[NSColor redColor]];
                lastIndex=[indices indexGreaterThanIndex:lastIndex];
                [self updateUIWithFreeSpace];
            }
        }
    }
    else
    {
        NSInteger clickedRow = [self.microcodeTable clickedRow];
        if (clickedRow > -1)
        {
            if ([[[microcodes objectAtIndex:clickedRow] objectForKey:@"action"] isEqualToString:@""])
            {
                [[microcodes objectAtIndex:clickedRow] setObject:@"Remove" forKey:@"action"];
                freeSpace += [[[microcodes objectAtIndex:clickedRow] objectForKey:@"size"] unsignedIntValue];
                //[(NSTextFieldCell *)[self.microcodeTable preparedCellAtColumn:7 row:clickedRow] setTextColor:[NSColor redColor]];
                [self updateUIWithFreeSpace];
            }
        }
    }
    [self.microcodeTable reloadData];
    [self updateDocumentEdited];
}
-(void)addMicrocode:(id)sender
{
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    [panel setCanChooseFiles:YES];
    [panel setCanChooseDirectories:NO];
    [panel setAllowsMultipleSelection:NO];
    [panel setAllowedFileTypes:[NSArray arrayWithObjects:@"bin", @"rom", nil]];
    
    [panel beginSheetModalForWindow:self.window completionHandler:^(NSInteger result) {
        if (result == NSFileHandlingPanelOKButton)
        {
            NSArray* files = [panel URLs];
            NSString *microcodeFile = [[files objectAtIndex:0] path];
            [self addMicrocodeFromFileAtPath:microcodeFile toIndex:microcodes.count];
        }
    }];
    
}
-(void)extractMicrocode:(id)sender
{
    NSInteger clickedRow=[self.microcodeTable clickedRow];
    if (clickedRow == -1)
    {
        clickedRow=[self.microcodeTable selectedRow];
    }
    NSIndexSet *clickedRows=[self.microcodeTable selectedRowIndexes];
    if (clickedRow>-1 && clickedRows.count<=1)
    {
        NSDictionary *microcode = [microcodes objectAtIndex:clickedRow];
        NSString *defaultFileName = [NSString stringWithFormat:@"cpu%02lX_plat%@_ver%08lX_%@_PRD_%02lX", [[microcode objectForKey:@"cpuid"] unsignedIntegerValue], [microcode objectForKey:@"platformid"], [[microcode objectForKey:@"revision"]unsignedIntegerValue], [[microcode objectForKey:@"date"] stringByReplacingOccurrencesOfString:@"/" withString:@"-"], [[microcode objectForKey:@"checksum"] unsignedIntegerValue]];
        NSSavePanel *save = [[NSSavePanel alloc] init];
        [save setTitle:@"Extract Microcode"];
        [save setPrompt:@"Extract Microcode"];
        [save setAllowedFileTypes:@[@"bin"]];
        [save setNameFieldStringValue:defaultFileName];
        [save beginSheetModalForWindow:self.window completionHandler:^(NSInteger result){
            if (result == NSOKButton)
            {
                NSString *path = [[save URL] path];
                [self extractMicrocodeAtIndex:clickedRow toPath:path];
            }
        }];
    }
}
-(void)addMicrocodeFromFileAtPath:(NSString *)path toIndex:(NSInteger)index
{
    FILE *rom = fopen([path UTF8String], "rb");
    long fsize;
	fseek(rom, 0, SEEK_END);
	fsize = ftell(rom);
	fseek(rom, 0, SEEK_SET);
    char *buf = malloc(fsize);
    fread(buf, 1, fsize, rom);
    fclose(rom);
    microcode_entry entries[1] = { 0 };
    getMicrocodeEntries(buf, fsize, entries);
    microcode_entry toAdd = entries[0];
    if (toAdd.cpuid == 0 || toAdd.size != fsize)
    {
        [self handleError:errInvalidMicrocodeFile];
        return;
    }
    NSString *date = [NSString stringWithFormat:@"%02X%02X/%02X/%02X", toAdd.date.yearpre, toAdd.date.yearsuf, toAdd.date.month, toAdd.date.day];
    BOOL exists = NO;
    BOOL replacement = NO;
    for (int i=0; i<microcodes.count; i++)
    {
        NSUInteger CPUID = [[[microcodes objectAtIndex:i] objectForKey:@"cpuid"] unsignedIntegerValue];
        NSString *platformID = [[microcodes objectAtIndex:i] objectForKey:@"platformid"];
        NSUInteger checksum = [[[microcodes objectAtIndex:i] objectForKey:@"checksum"] unsignedIntegerValue];
        if (checksum == toAdd.crc)
        {
            exists = YES;
            break;
        }
        if (CPUID == toAdd.cpuid && [platformID isEqualToString:[NSString stringWithUTF8String:toAdd.platformID]])
        {
            replacement = YES;
            NSUInteger newFreeSpace = freeSpace + [[[microcodes objectAtIndex:i] objectForKey:@"size"] unsignedIntegerValue];
            if (toAdd.size <= newFreeSpace)
            {
                if (!replacedMicrocodes)
                {
                    replacedMicrocodes = [[NSMutableDictionary alloc] init];
                }
                [replacedMicrocodes setObject:[microcodes objectAtIndex:i] forKey:[NSNumber numberWithInt:i]];
                [microcodes replaceObjectAtIndex:i withObject:[NSMutableDictionary dictionaryWithDictionary:@{@"cpuid": [NSNumber numberWithUnsignedInt:toAdd.cpuid], @"revision":[NSNumber numberWithUnsignedInt:toAdd.updateRev], @"checksum":[NSNumber numberWithUnsignedInt:toAdd.crc], @"date": date, @"platformid": [NSString stringWithFormat:@"%s", toAdd.platformID], @"offset":[NSNumber numberWithUnsignedInt:0], @"size":[NSNumber numberWithUnsignedInt:toAdd.size], @"action":@"Replace", @"contentFile":path}]];
                freeSpace = (unsigned int)newFreeSpace;
                freeSpace -= toAdd.size;
                
                //[(NSTextFieldCell *)[self.microcodeTable preparedCellAtColumn:7 row:i] setTextColor:[NSColor yellowColor]];
                [self updateUIWithFreeSpace];
            }
            else
            {
                [self handleError:errNoFreeSpace];
            }
        }
    }
    if (!replacement && !exists)
    {
        if (toAdd.size <= freeSpace)
        {
            [microcodes insertObject:[NSMutableDictionary dictionaryWithDictionary:@{@"cpuid": [NSNumber numberWithUnsignedInt:toAdd.cpuid], @"revision":[NSNumber numberWithUnsignedInt:toAdd.updateRev], @"checksum":[NSNumber numberWithUnsignedInt:toAdd.crc], @"date": date, @"platformid": [NSString stringWithFormat:@"%s", toAdd.platformID], @"offset":[NSNumber numberWithUnsignedInt:0], @"size":[NSNumber numberWithUnsignedInt:toAdd.size], @"action":@"Add", @"contentFile":path}] atIndex:index];
            freeSpace -= toAdd.size;
            
            //[(NSTextFieldCell *)[self.microcodeTable preparedCellAtColumn:7 row:microcodes.count-1] setTextColor:[NSColor greenColor]];
            [self updateUIWithFreeSpace];
        }
        else
        {
            [self handleError:errNoFreeSpace];
        }
    }
    [self.microcodeTable reloadData];
    [self updateDocumentEdited];
}
-(void)extractMicrocodeAtIndex:(NSInteger)index toPath:(NSString *)path
{
    off_t offset = [[[microcodes objectAtIndex:index] objectForKey:@"offset"] unsignedIntegerValue];
    long size = [[[microcodes objectAtIndex:index] objectForKey:@"size"] unsignedIntegerValue];
    char *buf = malloc(size);
    appendData(fileBuf, buf, offset, 0, size);
    FILE *save = fopen([path UTF8String], "wb");
    fwrite(buf, 1, size, save);
    fclose(save);
}
-(void)handleError:(err)error
{
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setAlertStyle:NSCriticalAlertStyle];
    [alert addButtonWithTitle:@"OK"];
    switch (error)
    {
        case errNoFreeSpace:
            [alert setMessageText:@"Not Enough Free Space"];
            [alert setInformativeText:@"There is not enough free space in the microcode section of this ROM to perform that action."];
            break;
        case errInvalidMicrocodeFile:
            [alert setMessageText:@"Invalid Microcode File"];
            [alert setInformativeText:@"This file does not contain a valid microcode."];
            break;
        case errInvalidROMFile:
            [alert setMessageText:@"Invalid ROM File"];
            [alert setInformativeText:@"This file is not a valid ROM dump."];
            break;
        default:
            [alert setMessageText:@"Unknown Error"];
            [alert setInformativeText:[NSString stringWithFormat:@"An unknown error occurred (%d).", error]];
            break;
    }
    [alert beginSheetModalForWindow:self.window modalDelegate:nil didEndSelector:nil contextInfo:nil];
}
@end
