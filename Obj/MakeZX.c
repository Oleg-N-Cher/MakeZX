/*  Ofront 1.2 -xtspkaem */
#include "SYSTEM.h"
#include "CmdLine.h"
#include "Console.h"
#include "Platform.h"
#include "TapeTAP.h"
#include "ZXBasic.h"




static void MakeZX_AddBasic (void);
static void MakeZX_CreateTape (void);
static void MakeZX_Title (void);


static void MakeZX_Title (void)
{
	Console_WriteStr((CHAR*)"MakeZX v1.0: convert a binary file to ZX Spectrum format TAP", (LONGINT)61);
	Console_WriteLn();
	Console_WriteStr((CHAR*)"Copyright (C) 2012 Oleg N. Cher, VEDAsoft Oberon Club", (LONGINT)54);
	Console_WriteLn();
	Console_WriteStr((CHAR*)"http://sf.net/projects/makezx/   http://zx.oberon2.ru", (LONGINT)54);
	Console_WriteLn();
	Console_WriteLn();
	Console_WriteLn();
	Console_WriteStr((CHAR*)"Usage: makezx out_file.tap := in_file.bin[:starting address]", (LONGINT)61);
	Console_WriteLn();
	Console_WriteStr((CHAR*)"Example: makezx mygame.tap := mygame.bin:32000", (LONGINT)47);
	Console_WriteLn();
}

static void MakeZX_CreateTape (void)
{
	TapeTAP_TapeFile tap;
	SYSTEM_BYTE data[4];
	data[0] = '>';
	data[1] = 'A';
	data[2] = 0xd7;
	data[3] = 0xc9;
	__TapeTAP_TapeFile_ReCreate(&tap, TapeTAP_TapeFile__typ, (CHAR*)"mytape.tap", (LONGINT)11);
	if (tap.error) {
		Console_WriteStr((CHAR*)"Tape creating error", (LONGINT)20);
		Console_WriteLn();
	} else {
		Console_WriteStr((CHAR*)"Tape created OK", (LONGINT)16);
		Console_WriteLn();
		__TapeTAP_TapeFile_SaveCode(&tap, TapeTAP_TapeFile__typ, (CHAR*)"mycode", (LONGINT)7, 26000, 4, (void*)data, 4);
		if (tap.error) {
			Console_WriteStr((CHAR*)"Cannot write to tape file", (LONGINT)26);
			Console_WriteLn();
		}
		__TapeTAP_TapeFile_Finalize(&tap, TapeTAP_TapeFile__typ);
	}
}

static void MakeZX_AddBasic (void)
{
	TapeTAP_TapeFile tap;
	INTEGER loaderLen;
	SYSTEM_BYTE data[65536];
	ZXBasic_GenTapeLoader(26000, &loaderLen, (void*)data, 65536);
	__TapeTAP_TapeFile_ReCreate(&tap, TapeTAP_TapeFile__typ, (CHAR*)"loader.tap", (LONGINT)11);
	__TapeTAP_TapeFile_SaveBasic(&tap, TapeTAP_TapeFile__typ, (CHAR*)"Loader", (LONGINT)7, 10, loaderLen, (void*)data, 65536);
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
	__IMPORT(TapeTAP);
	__IMPORT(ZXBasic);
	__REGMAIN("MakeZX", 0);
/* BEGIN */
	MakeZX_Title();
	MakeZX_CreateTape();
	MakeZX_AddBasic();
	__FINI;
}
