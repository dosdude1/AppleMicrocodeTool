//
//  ROMEditor.h
//  Apple Microcode Tool
//
//  Created by Collin Mistr on 6/12/18.
//  Copyright (c) 2018 dosdude1 Apps. All rights reserved.
//

#ifndef Apple_Microcode_Tool_ROMEditor_h
#define Apple_Microcode_Tool_ROMEditor_h

void clearSection(char *buf, off_t startOffset, long size);
off_t appendData(char *buf, char* data, off_t sourceStartOffset, off_t destStartOffset, long size);

#endif


