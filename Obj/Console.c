/*  Ofront 1.2 -xtspkae */
#include "SYSTEM.h"




export void Console_WriteInt (LONGINT n);

#define Console_WriteCh(ch)	printf("%c", ch)
#define Console_WriteLn()	printf("\n")
#define Console_WriteStr(str, str__len)	printf("%s", str)
#define Console_WriteStrLn(str, str__len)	printf("%s\n", str)
#include <stdio.h>
#define Console_writeInt(n)	printf("%ld", n)
#define Console_writeLInt(n)	printf("%lld", n)

void Console_WriteInt (LONGINT n)
{
	Console_writeInt(n);
}


export void *Console__init(void)
{
	__DEFMOD;
	__REGMOD("Console", 0);
/* BEGIN */
	__ENDMOD;
}
