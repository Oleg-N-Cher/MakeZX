/*  Ofront 1.2 -xtspkae */
#include "SYSTEM.h"
#include "Files.h"
#include "Platform.h"

typedef
	struct TapeTAP_TapeFile {
		Files_FileToWrite file;
		BOOLEAN error;
		SET checksum;
	} TapeTAP_TapeFile;

export void TapeTAP_TapeFile_Finalize (TapeTAP_TapeFile *tap, LONGINT *tap__typ);
export void TapeTAP_TapeFile_ReCreate (TapeTAP_TapeFile *tap, LONGINT *tap__typ, CHAR *tapeName, LONGINT tapeName__len);
export void TapeTAP_TapeFile_SaveCode (TapeTAP_TapeFile *tap, LONGINT *tap__typ, CHAR *name, LONGINT name__len, INTEGER startAddr, INTEGER dataLength, SYSTEM_BYTE *data, LONGINT data__len);
static void TapeTAP_TapeFile_WriteByte (TapeTAP_TapeFile *tap, LONGINT *tap__typ, SYSTEM_BYTE b);
static void TapeTAP_TapeFile_WriteCheckSum (TapeTAP_TapeFile *tap, LONGINT *tap__typ);
static void TapeTAP_TapeFile_WriteCodeBody (TapeTAP_TapeFile *tap, LONGINT *tap__typ, INTEGER dataLength, SYSTEM_BYTE *data, LONGINT data__len);
static void TapeTAP_TapeFile_WriteCodeHeader (TapeTAP_TapeFile *tap, LONGINT *tap__typ, CHAR *name, LONGINT name__len, INTEGER dataStartAddr, INTEGER dataLength);
static void TapeTAP_TapeFile_WriteWord (TapeTAP_TapeFile *tap, LONGINT *tap__typ, INTEGER w);
#define __TapeTAP_TapeFile_Finalize(tap, tap__typ) __SEND(tap__typ, TapeTAP_TapeFile_Finalize, 0, void(*)(TapeTAP_TapeFile*, LONGINT *), (tap, tap__typ))
#define __TapeTAP_TapeFile_ReCreate(tap, tap__typ, tapeName, tapeName__len) __SEND(tap__typ, TapeTAP_TapeFile_ReCreate, 1, void(*)(TapeTAP_TapeFile*, LONGINT *, CHAR*, LONGINT ), (tap, tap__typ, tapeName, tapeName__len))
#define __TapeTAP_TapeFile_SaveCode(tap, tap__typ, name, name__len, startAddr, dataLength, data, data__len) __SEND(tap__typ, TapeTAP_TapeFile_SaveCode, 2, void(*)(TapeTAP_TapeFile*, LONGINT *, CHAR*, LONGINT , INTEGER, INTEGER, SYSTEM_BYTE*, LONGINT ), (tap, tap__typ, name, name__len, startAddr, dataLength, data, data__len))
#define __TapeTAP_TapeFile_WriteByte(tap, tap__typ, b) __SEND(tap__typ, TapeTAP_TapeFile_WriteByte, 3, void(*)(TapeTAP_TapeFile*, LONGINT *, SYSTEM_BYTE), (tap, tap__typ, b))
#define __TapeTAP_TapeFile_WriteCheckSum(tap, tap__typ) __SEND(tap__typ, TapeTAP_TapeFile_WriteCheckSum, 4, void(*)(TapeTAP_TapeFile*, LONGINT *), (tap, tap__typ))
#define __TapeTAP_TapeFile_WriteCodeBody(tap, tap__typ, dataLength, data, data__len) __SEND(tap__typ, TapeTAP_TapeFile_WriteCodeBody, 5, void(*)(TapeTAP_TapeFile*, LONGINT *, INTEGER, SYSTEM_BYTE*, LONGINT ), (tap, tap__typ, dataLength, data, data__len))
#define __TapeTAP_TapeFile_WriteCodeHeader(tap, tap__typ, name, name__len, dataStartAddr, dataLength) __SEND(tap__typ, TapeTAP_TapeFile_WriteCodeHeader, 6, void(*)(TapeTAP_TapeFile*, LONGINT *, CHAR*, LONGINT , INTEGER, INTEGER), (tap, tap__typ, name, name__len, dataStartAddr, dataLength))
#define __TapeTAP_TapeFile_WriteWord(tap, tap__typ, w) __SEND(tap__typ, TapeTAP_TapeFile_WriteWord, 7, void(*)(TapeTAP_TapeFile*, LONGINT *, INTEGER), (tap, tap__typ, w))



export LONGINT *TapeTAP_TapeFile__typ;



void TapeTAP_TapeFile_ReCreate (TapeTAP_TapeFile *tap, LONGINT *tap__typ, CHAR *tapeName, LONGINT tapeName__len)
{
	__Files_File_OpenToWrite((void*)&(*tap).file, Files_FileToWrite__typ, tapeName, tapeName__len);
	(*tap).error = (*tap).file.error;
}

static void TapeTAP_TapeFile_WriteByte (TapeTAP_TapeFile *tap, LONGINT *tap__typ, SYSTEM_BYTE b)
{
	if (!(*tap).error) {
		__Files_FileToWrite_WriteByte(&(*tap).file, Files_FileToWrite__typ, b);
		(*tap).error = (*tap).file.error;
	}
	(*tap).checksum = (*tap).checksum ^ __VAL(SET, b);
}

static void TapeTAP_TapeFile_WriteWord (TapeTAP_TapeFile *tap, LONGINT *tap__typ, INTEGER w)
{
	if (w >= 0 && w <= 65535) {
		if (!(*tap).error) {
			__TapeTAP_TapeFile_WriteByte(&*tap, tap__typ, (int)w);
			(*tap).error = (*tap).file.error;
		}
		if (!(*tap).error) {
			__TapeTAP_TapeFile_WriteByte(&*tap, tap__typ, (int)__ASHR(w, 8));
			(*tap).error = (*tap).file.error;
		}
	} else {
		(*tap).error = 1;
	}
}

static void TapeTAP_TapeFile_WriteCheckSum (TapeTAP_TapeFile *tap, LONGINT *tap__typ)
{
	__Files_FileToWrite_WriteByte(&(*tap).file, Files_FileToWrite__typ, (int)Platform_ORD((*tap).checksum));
}

static void TapeTAP_TapeFile_WriteCodeHeader (TapeTAP_TapeFile *tap, LONGINT *tap__typ, CHAR *name, LONGINT name__len, INTEGER dataStartAddr, INTEGER dataLength)
{
	INTEGER i, nameIdx;
	__TapeTAP_TapeFile_WriteWord(&*tap, tap__typ, 19);
	(*tap).checksum = 0x0;
	__TapeTAP_TapeFile_WriteByte(&*tap, tap__typ, 0);
	__TapeTAP_TapeFile_WriteByte(&*tap, tap__typ, 3);
	nameIdx = 0;
	i = 0;
	while (i <= 9) {
		if ((LONGINT)nameIdx <= name__len && name[__X(nameIdx, name__len)] != 0x00) {
			__TapeTAP_TapeFile_WriteByte(&*tap, tap__typ, name[__X(nameIdx, name__len)]);
			nameIdx += 1;
		} else {
			__TapeTAP_TapeFile_WriteByte(&*tap, tap__typ, ' ');
		}
		i += 1;
	}
	__TapeTAP_TapeFile_WriteWord(&*tap, tap__typ, dataLength);
	__TapeTAP_TapeFile_WriteWord(&*tap, tap__typ, dataStartAddr);
	__TapeTAP_TapeFile_WriteWord(&*tap, tap__typ, 32768);
	__TapeTAP_TapeFile_WriteCheckSum(&*tap, tap__typ);
}

static void TapeTAP_TapeFile_WriteCodeBody (TapeTAP_TapeFile *tap, LONGINT *tap__typ, INTEGER dataLength, SYSTEM_BYTE *data, LONGINT data__len)
{
	INTEGER i, _for__7;
	__TapeTAP_TapeFile_WriteWord(&*tap, tap__typ, (1 + dataLength) + 1);
	(*tap).checksum = 0x0;
	__TapeTAP_TapeFile_WriteByte(&*tap, tap__typ, 0xff);
	_for__7 = dataLength - 1;
	i = 0;
	while (i <= _for__7) {
		__TapeTAP_TapeFile_WriteByte(&*tap, tap__typ, data[__X(i, data__len)]);
		i += 1;
	}
	__TapeTAP_TapeFile_WriteCheckSum(&*tap, tap__typ);
}

void TapeTAP_TapeFile_SaveCode (TapeTAP_TapeFile *tap, LONGINT *tap__typ, CHAR *name, LONGINT name__len, INTEGER startAddr, INTEGER dataLength, SYSTEM_BYTE *data, LONGINT data__len)
{
	__TapeTAP_TapeFile_WriteCodeHeader(&*tap, tap__typ, name, name__len, startAddr, dataLength);
	__TapeTAP_TapeFile_WriteCodeBody(&*tap, tap__typ, dataLength, (void*)data, data__len * 1);
}

void TapeTAP_TapeFile_Finalize (TapeTAP_TapeFile *tap, LONGINT *tap__typ)
{
	__Files_File_Close((void*)&(*tap).file, Files_FileToWrite__typ);
}

__TDESC(TapeTAP_TapeFile, 9, 0) = {__TDFLDS("TapeFile", 16), {-4}};

export void *TapeTAP__init(void)
{
	__DEFMOD;
	__IMPORT(Files);
	__IMPORT(Platform);
	__REGMOD("TapeTAP", 0);
	__INITYP(TapeTAP_TapeFile, TapeTAP_TapeFile, 0);
	__INITBP(TapeTAP_TapeFile, TapeTAP_TapeFile_Finalize, 0);
	__INITBP(TapeTAP_TapeFile, TapeTAP_TapeFile_ReCreate, 1);
	__INITBP(TapeTAP_TapeFile, TapeTAP_TapeFile_SaveCode, 2);
	__INITBP(TapeTAP_TapeFile, TapeTAP_TapeFile_WriteByte, 3);
	__INITBP(TapeTAP_TapeFile, TapeTAP_TapeFile_WriteCheckSum, 4);
	__INITBP(TapeTAP_TapeFile, TapeTAP_TapeFile_WriteCodeBody, 5);
	__INITBP(TapeTAP_TapeFile, TapeTAP_TapeFile_WriteCodeHeader, 6);
	__INITBP(TapeTAP_TapeFile, TapeTAP_TapeFile_WriteWord, 7);
/* BEGIN */
	__ENDMOD;
}
