//
//  ROMParser.h
//  Apple Microcode Tool
//
//  Created by Collin Mistr on 6/10/18.
//  Copyright (c) 2018 dosdude1 Apps. All rights reserved.
//

#ifndef Apple_Microcode_Tool_ROMParser_h
#define Apple_Microcode_Tool_ROMParser_h



#endif

typedef struct {
    unsigned int yearpre;
    unsigned int yearsuf;
    unsigned int month;
    unsigned int day;
}date;

typedef struct {
    unsigned int cpuid;
    unsigned int updateRev;
    date date;
    unsigned int crc;
    char platformID[50];
    unsigned int offset;
    unsigned int size;
}microcode_entry;

off_t locateMicrocodeBlockOffset(char *romBuf, long bufSize, uint8_t index);
off_t locateMicrocodeBlockOffsetUsingZeroGUID(char *romBuf, long bufSize, uint8_t index);
off_t locateEndOffsetOfLastSection(char *romBuf, long bufSize);
int getMicrocodeEntries(char *romBuf, long bufSize, microcode_entry entries[]);
