/*  Ofront 1.2 -xtspkaem */
#include "SYSTEM.h"
#include "CmdLine.h"
#include "Console.h"




static void MakeZX_Run (void);
static void MakeZX_Title (void);


static void MakeZX_Title (void)
{
	Console_WriteStr((CHAR*)"MakeZX is a converter from .IHX/.BIN to ZX Spectrum format .TAP", (LONGINT)64);
	Console_Ln();
}

static void MakeZX_Run (void)
{
	CmdLine_String param;
	LONGINT i, _for__2;
	MakeZX_Title();
	Console_WriteStr((CHAR*)"ParamCount = ", (LONGINT)14);
	Console_WriteInt(CmdLine_ParamCount);
	Console_Ln();
	_for__2 = CmdLine_ParamCount;
	i = 0;
	while (i <= _for__2) {
		Console_WriteStr((CHAR*)"[", (LONGINT)2);
		Console_WriteInt(i);
		Console_WriteStr((CHAR*)"] = ", (LONGINT)5);
		CmdLine_GetParam(i, (void*)param, 1024);
		Console_WriteStr(param, 1024);
		Console_Ln();
		i += 1;
	}
}


export main(int argc, char **argv)
{
	__INIT(argc, argv);
	__IMPORT(CmdLine);
	__IMPORT(Console);
	__REGMAIN("MakeZX", 0);
/* BEGIN */
	MakeZX_Run();
	__FINI;
}
