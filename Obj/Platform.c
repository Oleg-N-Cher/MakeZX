/*  Ofront 1.2 -xtspkae */
#include "SYSTEM.h"

typedef
	CHAR *Platform_STRING;




export SET Platform_BITS (INTEGER i);
export INTEGER Platform_ORD (SET s);


SET Platform_BITS (INTEGER i)
{
	return __VAL(SET, i);
}

INTEGER Platform_ORD (SET s)
{
	return __VAL(INTEGER, s);
}


export void *Platform__init(void)
{
	__DEFMOD;
	__REGMOD("Platform", 0);
/* BEGIN */
	__ENDMOD;
}
