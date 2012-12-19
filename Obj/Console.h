/*  Ofront 1.2 -xtspkae */

#ifndef Console__h
#define Console__h

#include "SYSTEM.h"




import void Console_WriteInt (LONGINT n);
import void *Console__init(void);

#define Console_WriteCh(ch)	printf("%c", ch)
#define Console_WriteLn()	printf("\n")
#define Console_WriteStr(str, str__len)	printf("%s", str)
#define Console_WriteStrLn(str, str__len)	printf("%s\n", str)

#endif
