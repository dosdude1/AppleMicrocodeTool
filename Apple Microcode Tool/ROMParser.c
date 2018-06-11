//
//  ROMParser.c
//  Apple Microcode Tool
//
//  Created by Collin Mistr on 6/10/18.
//  Copyright (c) 2018 dosdude1 Apps. All rights reserved.
//

#include <stdio.h>
#include <string.h>
#include "ROMParser.h"

off_t locateMicrocodeBlockOffset(char *romBuf, long bufSize, uint8_t index)
{
    uint8_t OFFSET_FROM_SEARCH_DATA = 225;
    uint8_t BYTES_TO_SEARCH = 6;
    uint8_t bytes [] = {0x88, 0x7F, 0x70, 0xE4, 0x1A, 0x6B};
    off_t offset = -1;
    int ct = 0;
    int found = 0;
    int numFound = 0;
    for (int i=0; i<bufSize; i++)
    {
        if ((uint8_t)romBuf[i] == bytes[ct])
        {
            if (ct < BYTES_TO_SEARCH)
            {
                ct++;
            }
            if (ct == BYTES_TO_SEARCH)
            {
                found = 1;
            }
        }
        else
        {
            found = 0;
            ct = 0;
        }
        if (found == 1)
        {
            offset = i+OFFSET_FROM_SEARCH_DATA;
            printf("Found at offset: %lld\n", offset);
            numFound ++;
            if (index + 1 == numFound)
            {
                break;
            }
        }
    }
	return offset;
}
void getMicrocodeEntries(char *romBuf, long bufSize, microcode_entry entries[])
{
    int ct=0;
    for (int i=0; i<bufSize-2000; i++)
	{
		if (
            *(unsigned int*)(&romBuf[i+0]) == 1
			&& (romBuf[i+9]==0x20 || romBuf[i+9]==0x19)
			&& (romBuf[i+10]>=0x01 && romBuf[i+10]<=0x09 || romBuf[i+10]>=0x10 && romBuf[i+10]<=0x19 || romBuf[i+10]>=0x20 && romBuf[i+10]<=0x29 || romBuf[i+10]>=0x30 && romBuf[i+10]<=0x31)
			&& (romBuf[i+11]>=0x01 && romBuf[i+11]<=0x09 || romBuf[i+11]>=0x10 && romBuf[i+11]<=0x12)
            )
        {
			
			int totalsize = *(unsigned int*)(&romBuf[i+32]);
			//printf("   datasize=%d totalsize=%d\n", *(unsigned int*)(&buf[i+28]), totalsize);
			if (totalsize == 0) totalsize = 2048;
			if ((totalsize & 1023) != 0) continue;
			if (i+totalsize > bufSize) continue;
			int j,sum=0;
			for (j=0; j<totalsize; j+=4) sum += *(unsigned int*)(&romBuf[i+j]);
			if (sum != 0) continue;
			
            char platform[50] = {'\0'};
            int flag = 0;
			for (int j=0; j<=7; ++j)
			{
				if ((1<<j) & *(unsigned int*)(&romBuf[i+24]))
				{
					if (flag == 1) {
                        strcat(platform, ",");
					}
					flag = 1;
                    sprintf(platform, "%s%d", platform, j);
				}
			}
            printf("Platform ID: %s\n", platform);
            int exists = 0;
            for (int c=0; c < ct; c++)
            {
                if (entries[c].crc == *(unsigned int*)(&romBuf[i+16]))
                {
                    exists = 1;
                }
            }
            if (exists == 0)
            {
                entries[ct].cpuid = *(unsigned int*)(&romBuf[i+12]);
                entries[ct].updateRev = *(unsigned int*)(&romBuf[i+4]);
                entries[ct].date.yearpre = romBuf[i+9];
                entries[ct].date.yearsuf = romBuf[i+8];
                entries[ct].date.month = romBuf[i+11];
                entries[ct].date.day = romBuf[i+10];
                entries[ct].crc = *(unsigned int*)(&romBuf[i+16]);
                strcpy(entries[ct].platformID, platform);
                ct++;
            }
            
            
			printf("CPUID=%X UpdateRev=%02X %02X%02X/%02X/%02X Checksum=%08X", *(unsigned int*)(&romBuf[i+12]), *(unsigned int*)(&romBuf[i+4]), romBuf[i+9], romBuf[i+8], romBuf[i+11], romBuf[i+10], *(unsigned int*)(&romBuf[i+16]));
            
            
			printf("\n");
            
		}
	}
}