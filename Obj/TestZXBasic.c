/*  Ofront 1.2 -xtspkaem */
#include "SYSTEM.h"
#include "Console.h"
#include "ZXBasic.h"


static INTEGER TestZXBasic_n, TestZXBasic_len;
static SYSTEM_BYTE TestZXBasic_loader[32];





export main(int argc, char **argv)
{
	__INIT(argc, argv);
	__IMPORT(Console__init);
	__IMPORT(ZXBasic__init);
	__REGMAIN("TestZXBasic", 0);
/* BEGIN */
	ZXBasic_GenTapeLoader(32000, &TestZXBasic_len, (void*)TestZXBasic_loader, 32);
	TestZXBasic_n = 0;
	while (TestZXBasic_len > 4) {
		if (TestZXBasic_len >= 2) {
			Console_WriteInt((int)(__VAL(CHAR, TestZXBasic_loader[__X(TestZXBasic_n + 1, 32)])) + __ASHL((int)(__VAL(CHAR, TestZXBasic_loader[__X(TestZXBasic_n, 32)])), 8));
			TestZXBasic_len -= 2;
		}
		TestZXBasic_n += 2;
		if (TestZXBasic_len >= 2) {
			TestZXBasic_len -= 2;
		}
		TestZXBasic_n += 2;
		for (;;) {
			TestZXBasic_len -= 1;
			switch (__VAL(CHAR, TestZXBasic_loader[__X(TestZXBasic_n, 32)])) {
				case 0x0d: 
					Console_WriteLn();
					TestZXBasic_n += 1;
					goto exit__0;
					break;
				case 0xaf: 
					Console_WriteStr((CHAR*)"CODE ", (LONGINT)6);
					break;
				case 0xb0: 
					Console_WriteStr((CHAR*)" VAL ", (LONGINT)6);
					break;
				case 0xc0: 
					Console_WriteStr((CHAR*)" USR", (LONGINT)5);
					break;
				case 0xef: 
					Console_WriteStr((CHAR*)" LOAD ", (LONGINT)7);
					break;
				case 0xf9: 
					Console_WriteStr((CHAR*)" RANDOMIZE", (LONGINT)11);
					break;
				case 0xfd: 
					Console_WriteStr((CHAR*)" CLEAR", (LONGINT)7);
					break;
				default: 
					Console_WriteCh(__VAL(CHAR, TestZXBasic_loader[__X(TestZXBasic_n, 32)]));
					break;
			}
			TestZXBasic_n += 1;
		}
		exit__0:;
	}
	__FINI;
}
