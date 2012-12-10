/*  Ofront 1.2 -xtspkae */

#ifndef TapeTAP__h
#define TapeTAP__h

#include "SYSTEM.h"

typedef
	struct TapeTAP_TapeFile {
		INTEGER _prvt0;
		char _prvt1[4];
		BOOLEAN error;
		char _prvt2[7];
	} TapeTAP_TapeFile;

import void TapeTAP_TapeFile_Finalize (TapeTAP_TapeFile *tap, LONGINT *tap__typ);
import void TapeTAP_TapeFile_ReCreate (TapeTAP_TapeFile *tap, LONGINT *tap__typ, CHAR *tapeName, LONGINT tapeName__len);
import void TapeTAP_TapeFile_SaveCode (TapeTAP_TapeFile *tap, LONGINT *tap__typ, CHAR *name, LONGINT name__len, INTEGER startAddr, INTEGER dataLength, SYSTEM_BYTE *data, LONGINT data__len);
#define __TapeTAP_TapeFile_Finalize(tap, tap__typ) __SEND(tap__typ, TapeTAP_TapeFile_Finalize, 0, void(*)(TapeTAP_TapeFile*, LONGINT *), (tap, tap__typ))
#define __TapeTAP_TapeFile_ReCreate(tap, tap__typ, tapeName, tapeName__len) __SEND(tap__typ, TapeTAP_TapeFile_ReCreate, 1, void(*)(TapeTAP_TapeFile*, LONGINT *, CHAR*, LONGINT ), (tap, tap__typ, tapeName, tapeName__len))
#define __TapeTAP_TapeFile_SaveCode(tap, tap__typ, name, name__len, startAddr, dataLength, data, data__len) __SEND(tap__typ, TapeTAP_TapeFile_SaveCode, 2, void(*)(TapeTAP_TapeFile*, LONGINT *, CHAR*, LONGINT , INTEGER, INTEGER, SYSTEM_BYTE*, LONGINT ), (tap, tap__typ, name, name__len, startAddr, dataLength, data, data__len))



import LONGINT *TapeTAP_TapeFile__typ;

import void *TapeTAP__init(void);


#endif
