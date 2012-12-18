/*  Ofront 1.2 -xtspkaem */
#include "SYSTEM.h"
#include "CmdLine.h"
#include "Console.h"
#include "Platform.h"
#include "Strings.h"
#include "TapeTAP.h"
#include "ZXBasic.h"




static void MakeZX_GetTapeName (INTEGER param, INTEGER *addr, CmdLine_String name, INTEGER *dotPos, BOOLEAN addTapExt);
static void MakeZX_HaltError (CHAR *str, LONGINT str__len);
static BOOLEAN MakeZX_IsTAP (INTEGER param);
static void MakeZX_MakeZX (void);


static void MakeZX_HaltError (CHAR *str, LONGINT str__len)
{
	Console_WriteStr(str, str__len);
	Console_WriteLn();
	Console_WriteLn();
	__HALT(1);
}

static BOOLEAN MakeZX_IsTAP (INTEGER param)
{
	CmdLine_String parStr;
	LONGINT parLen;
	CmdLine_GetParam(param, (void*)parStr, 1024);
	parLen = Strings_Length((void*)parStr, 1024);
	if ((((parLen >= 5 && parStr[__X(parLen - 4, 1024)] == '.') && __CAP(parStr[__X(parLen - 3, 1024)]) == 'T') && __CAP(parStr[__X(parLen - 2, 1024)]) == 'A') && __CAP(parStr[__X(parLen - 1, 1024)]) == 'P') {
		return 1;
	}
	return 0;
}

static struct GetTapeName__1 {
	CmdLine_String *parStr;
	INTEGER *parLen;
	struct GetTapeName__1 *lnk;
} *GetTapeName__1_s;

static void StrToInt__4 (INTEGER minPos, INTEGER maxPos, INTEGER *result);

static void StrToInt__4 (INTEGER minPos, INTEGER maxPos, INTEGER *result)
{
	INTEGER i, resHex;
	BOOLEAN isHex, isNum, done;
	*result = 0;
	if (minPos >= 0 && maxPos < *GetTapeName__1_s->parLen) {
		resHex = 0;
		done = 0;
		isHex = 0;
		isNum = 0;
		i = minPos;
		while (i <= maxPos) {
			if (done) {
				MakeZX_HaltError((CHAR*)"Please check input file address.", (LONGINT)33);
			}
			switch ((*GetTapeName__1_s->parStr)[__X(i, 1024)]) {
				case '0': case '1': case '2': case '3': case '4': 
				case '5': case '6': case '7': case '8': case '9': 
					isNum = 1;
					*result = (*result * 10 + (int)(*GetTapeName__1_s->parStr)[__X(i, 1024)]) - 48;
					resHex = (__ASHL(resHex, 4) + (int)(*GetTapeName__1_s->parStr)[__X(i, 1024)]) - 48;
					break;
				case 'A': case 'B': case 'C': case 'D': case 'E': 
				case 'F': 
					isNum = 1;
					isHex = 1;
					*result = ((*result * 10 + (int)(*GetTapeName__1_s->parStr)[__X(i, 1024)]) - 65) + 10;
					resHex = ((__ASHL(resHex, 4) + (int)(*GetTapeName__1_s->parStr)[__X(i, 1024)]) - 65) + 10;
					break;
				case 'a': case 'b': case 'c': case 'd': case 'e': 
				case 'f': 
					isNum = 1;
					isHex = 1;
					*result = ((*result * 10 + (int)(*GetTapeName__1_s->parStr)[__X(i, 1024)]) - 97) + 10;
					resHex = ((__ASHL(resHex, 4) + (int)(*GetTapeName__1_s->parStr)[__X(i, 1024)]) - 97) + 10;
					break;
				case 'H': case 'h': 
					isHex = 1;
					done = 1;
					break;
				default: 
					Console_WriteStr((CHAR*)"Cannot calculate input file address. Wrong character \"", (LONGINT)55);
					Console_WriteCh((*GetTapeName__1_s->parStr)[__X(i, 1024)]);
					MakeZX_HaltError((CHAR*)"\".", (LONGINT)3);
					break;
			}
			i += 1;
		}
		if (!isNum) {
			Console_WriteStr((CHAR*)"Wrong address specified in parameter \"", (LONGINT)39);
			Console_WriteStr(*GetTapeName__1_s->parStr, 1024);
			MakeZX_HaltError((CHAR*)"\".", (LONGINT)3);
		}
		if (isHex) {
			*result = resHex;
		}
	}
}

static void MakeZX_GetTapeName (INTEGER param, INTEGER *addr, CmdLine_String name, INTEGER *dotPos, BOOLEAN addTapExt)
{
	CmdLine_String parStr;
	INTEGER n, parLen, colonPos, startPos, _for__3, _for__2;
	struct GetTapeName__1 _s;
	_s.parStr = (void*)parStr;
	_s.parLen = &parLen;
	_s.lnk = GetTapeName__1_s;
	GetTapeName__1_s = &_s;
	CmdLine_GetParam(param, (void*)parStr, 1024);
	parLen = (int)Strings_Length((void*)parStr, 1024);
	n = 0;
	colonPos = -1;
	while (n < parLen) {
		if (parStr[__X(n, 1024)] == ':') {
			colonPos = n;
		}
		n += 1;
	}
	if (colonPos != -1) {
		StrToInt__4(colonPos + 1, parLen - 1, &*addr);
	} else {
		*addr = 26000;
	}
	if (colonPos >= 0) {
		parLen = colonPos;
	}
	if (parLen == 0) {
		Console_WriteStr((CHAR*)"Empty file name is specified in parameter \"", (LONGINT)44);
		Console_WriteStr(parStr, 1024);
		MakeZX_HaltError((CHAR*)"\".", (LONGINT)3);
	}
	if (parLen + 4 >= 1024) {
		MakeZX_HaltError((CHAR*)"Input file name is too long.", (LONGINT)29);
	}
	*dotPos = -1;
	startPos = -1;
	_for__3 = parLen - 1;
	n = 0;
	while (n <= _for__3) {
		name[__X(n, 1024)] = parStr[__X(n, 1024)];
		if (parStr[__X(n, 1024)] == '.') {
			*dotPos = n;
		}
		if (parStr[__X(n, 1024)] == '/' || parStr[__X(n, 1024)] == '\\') {
			startPos = n + 1;
		}
		n += 1;
	}
	if (startPos > 0) {
		parLen -= startPos;
		*dotPos -= startPos;
		_for__2 = parLen - 1;
		n = 0;
		while (n <= _for__2) {
			name[__X(n, 1024)] = name[__X(n + startPos, 1024)];
			n += 1;
		}
		name[__X(parLen, 1024)] = 0x00;
		Console_WriteStr(name, 1024);
		Console_WriteLn();
	}
	if (*dotPos < 0) {
		*dotPos = parLen;
	}
	if (addTapExt) {
		name[__X(*dotPos, 1024)] = '.';
		name[__X(*dotPos + 1, 1024)] = 't';
		name[__X(*dotPos + 2, 1024)] = 'a';
		name[__X(*dotPos + 3, 1024)] = 'p';
		name[__X(*dotPos + 4, 1024)] = 0x00;
	}
	GetTapeName__1_s = _s.lnk;
}

static void MakeZX_MakeZX (void)
{
	INTEGER nPar, tapPar, startAddr, maxStartAddr, nParWithMaxStartAddr, dotPos;
	CmdLine_String strPar, tapeName;
	TapeTAP_TapeFile tap;
	SYSTEM_BYTE data[65536];
	INTEGER loaderLen;
	maxStartAddr = -1;
	nParWithMaxStartAddr = -1;
	tapPar = -1;
	nPar = 1;
	do {
		if (MakeZX_IsTAP(nPar)) {
			if (tapPar == -1) {
				tapPar = nPar;
			} else {
				Console_WriteStr((CHAR*)"Conflict of the names \"", (LONGINT)24);
				CmdLine_GetParam(nPar, (void*)strPar, 1024);
				Console_WriteStr(strPar, 1024);
				Console_WriteStr((CHAR*)"\" and \"", (LONGINT)8);
				CmdLine_GetParam(tapPar, (void*)strPar, 1024);
				Console_WriteStr(strPar, 1024);
				Console_WriteStr((CHAR*)"\"", (LONGINT)2);
				Console_WriteLn();
				MakeZX_HaltError((CHAR*)"Please specify a TAP file only once.", (LONGINT)37);
			}
		} else {
			MakeZX_GetTapeName(nPar, &startAddr, tapeName, &dotPos, 0);
			if (startAddr > maxStartAddr) {
				maxStartAddr = startAddr;
				nParWithMaxStartAddr = nPar;
			}
		}
		nPar += 1;
	} while (!(nPar > CmdLine_paramCount));
	if (tapPar != -1) {
		MakeZX_GetTapeName(tapPar, &startAddr, tapeName, &dotPos, 0);
	} else {
		MakeZX_GetTapeName(nParWithMaxStartAddr, &startAddr, tapeName, &dotPos, 1);
	}
	__TapeTAP_TapeFile_ReCreate(&tap, TapeTAP_TapeFile__typ, tapeName, 1024);
	if (tap.error) {
		Console_WriteStr((CHAR*)"Cannot create tape file \"", (LONGINT)26);
		Console_WriteStr(tapeName, 1024);
		MakeZX_HaltError((CHAR*)"\". Wrong file name.", (LONGINT)20);
	}
	if (dotPos >= 0) {
		tapeName[__X(dotPos, 1024)] = 0x00;
	}
	Console_WriteInt(startAddr);
	ZXBasic_GenTapeLoader(startAddr, &loaderLen, (void*)data, 65536);
	if (loaderLen == 0) {
		MakeZX_HaltError((CHAR*)"Please check start address, that must be in {0..0FFFFH}.", (LONGINT)57);
	}
	__TapeTAP_TapeFile_SaveBasic(&tap, TapeTAP_TapeFile__typ, tapeName, 1024, 10, loaderLen, (void*)data, 65536);
	if (tap.error) {
	}
	data[0] = '>';
	data[1] = 'A';
	data[2] = 0xd7;
	data[3] = 0xc9;
	__TapeTAP_TapeFile_SaveCode(&tap, TapeTAP_TapeFile__typ, (CHAR*)"mycode", (LONGINT)7, 26000, 4, (void*)data, 65536);
	__TapeTAP_TapeFile_Finalize(&tap, TapeTAP_TapeFile__typ);
}


export main(int argc, char **argv)
{
	__INIT(argc, argv);
	__IMPORT(CmdLine);
	__IMPORT(Console);
	__IMPORT(Platform);
	__IMPORT(Strings);
	__IMPORT(TapeTAP);
	__IMPORT(ZXBasic);
	__REGMAIN("MakeZX", 0);
/* BEGIN */
	Console_WriteStr((CHAR*)"MakeZX v1.0: convert a binary file to ZX Spectrum format TAP", (LONGINT)61);
	Console_WriteLn();
	Console_WriteStr((CHAR*)"Copyright (C) 2012 Oleg N. Cher, VEDAsoft Oberon Club", (LONGINT)54);
	Console_WriteLn();
	Console_WriteStr((CHAR*)"http://sf.net/projects/makezx/   http://zx.oberon2.ru", (LONGINT)54);
	Console_WriteLn();
	Console_WriteLn();
	if (CmdLine_paramCount == 0) {
		Console_WriteStr((CHAR*)"Usage: makezx out_file.tap := in_file.bin[:starting address]", (LONGINT)61);
		Console_WriteLn();
		Console_WriteStr((CHAR*)"Example: makezx mygame.tap := mygame.bin:32000", (LONGINT)47);
	} else {
		MakeZX_MakeZX();
	}
	Console_WriteLn();
	Console_WriteLn();
	__FINI;
}
