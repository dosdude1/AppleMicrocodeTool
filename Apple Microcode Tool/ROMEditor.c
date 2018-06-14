//
//  ROMEditor.c
//  Apple Microcode Tool
//
//  Created by Collin Mistr on 6/12/18.
//  Copyright (c) 2018 dosdude1 Apps. All rights reserved.
//

#include <stdio.h>
#include "ROMEditor.h"

void clearSection(char *buf, off_t startOffset, long size)
{
    for (off_t i=startOffset; i<startOffset + size; i++)
    {
        buf[i] = 0xFF;
    }
}
off_t appendData(char *source, char* dest, off_t sourceStartOffset, off_t destStartOffset, long size)
{
    int ct = 0;
    off_t lastOffset = -1;
    for (off_t i=sourceStartOffset; i<size+sourceStartOffset; i++)
    {
        dest[destStartOffset + ct] = source[i];
        lastOffset = destStartOffset + ct;
        ct++;
    }
    return lastOffset;
}