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
}microcode_entry;

off_t locateMicrocodeBlockOffset(char *romBuf, long bufSize, uint8_t index);
void getMicrocodeEntries(char *romBuf, long bufSize, microcode_entry entries[]);
