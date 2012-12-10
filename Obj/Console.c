/*  Ofront 1.2 -xtspkae */
#include "SYSTEM.h"




export void Console_WriteInt (LONGINT n);
export void Console_WriteLn (void);
export void Console_WriteStr (CHAR *str, LONGINT str__len);

#include <stdio.h>
#define Console_writeInt(n)	printf("%ld", n)
#define Console_writeLInt(n)	printf("%lld", n)
#define Console_writeLn()	printf("\n")
#define Console_writeStr(str, str__len)	printf("%s", str)

void Console_WriteInt (LONGINT n)
{
	Console_writeInt(n);
}

void Console_WriteStr (CHAR *str, LONGINT str__len)
{
	Console_writeStr(str, str__len);
}

void Console_WriteLn (void)
{
	Console_writeLn();
}


export void *Console__init(void)
{
	__DEFMOD;
	__REGMOD("Console", 0);
	__REGCMD("WriteLn", Console_WriteLn);
/* BEGIN */
	__ENDMOD;
}
