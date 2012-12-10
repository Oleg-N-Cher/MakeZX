/*  Ofront 1.2 -xtspkaem */
#include "SYSTEM.h"
#include "CmdLine.h"
#include "Console.h"
#include "Platform.h"
#include "TapeTAP.h"




static void MakeZX_CreateTape (void);


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


export main(int argc, char **argv)
{
	__INIT(argc, argv);
	__IMPORT(CmdLine);
	__IMPORT(Console);
	__IMPORT(Platform);
	__IMPORT(TapeTAP);
	__REGMAIN("MakeZX", 0);
/* BEGIN */
	MakeZX_CreateTape();
	__FINI;
}
