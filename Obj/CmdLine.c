/*  Ofront 1.2 -xtspkae */
#include "SYSTEM.h"

typedef
	CHAR (*CmdLine_ArgPtr)[1024];

typedef
	CmdLine_ArgPtr (*CmdLine_ArgVec)[1024];

typedef
	CHAR CmdLine_String[1024];


export LONGINT CmdLine_ParamCount;


export void CmdLine_GetParam (LONGINT n, CHAR *param, LONGINT param__len);

#define CmdLine_Argc()	SYSTEM_argc
#define CmdLine_Argv()	(long)SYSTEM_argv

void CmdLine_GetParam (LONGINT n, CHAR *param, LONGINT param__len)
{
	CmdLine_ArgVec av = NIL;
	if (n <= CmdLine_ParamCount) {
		av = (CmdLine_ArgVec)CmdLine_Argv();
		__COPY(*(*av)[__X(n, 1024)], param, param__len);
	} else {
		__COPY("", param, param__len);
	}
}


export void *CmdLine__init(void)
{
	__DEFMOD;
	__REGMOD("CmdLine", 0);
/* BEGIN */
	CmdLine_ParamCount = CmdLine_Argc() - 1;
	__ENDMOD;
}
