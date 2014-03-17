/*  Ofront 1.2 -xtspkae */
#include "SYSTEM.h"
#include "Platform.h"
#include "Strings.h"




export void ZXBasic_GenTapeLoader (INTEGER codeStartAddr, INTEGER *loaderLen, SYSTEM_BYTE *loader, LONGINT loader__len);


static struct GenTapeLoader__1 {
	INTEGER *loaderLen;
	SYSTEM_BYTE *loader;
	LONGINT loader__len;
	struct GenTapeLoader__1 *lnk;
} *GenTapeLoader__1_s;

static void Add__2 (SYSTEM_BYTE byte);
static void AddIntAsVAL__4 (INTEGER num);

static void Add__2 (SYSTEM_BYTE byte)
{
	if ((LONGINT)*GenTapeLoader__1_s->loaderLen < GenTapeLoader__1_s->loader__len) {
		GenTapeLoader__1_s->loader[__X(*GenTapeLoader__1_s->loaderLen, GenTapeLoader__1_s->loader__len)] = byte;
	}
	*GenTapeLoader__1_s->loaderLen += 1;
}

static void AddIntAsVAL__4 (INTEGER num)
{
	INTEGER n, nulls;
	CHAR str[6];
	__ASSERT(num >= 0 && num <= 99999, 1);
	Strings_IntToStr(num, (void*)str, 6);
	Add__2(0xb0);
	Add__2('\"');
	n = 0;
	nulls = 0;
	do {
		if (str[__X(n, 6)] != '0') {
			nulls = 0;
		} else {
			nulls += 1;
		}
		Add__2(str[__X(n, 6)]);
		n += 1;
	} while (!(str[__X(n, 6)] == 0x00));
	if (nulls >= 3) {
		*GenTapeLoader__1_s->loaderLen -= nulls;
		Add__2('e');
		Add__2((CHAR)(nulls + 48));
	}
	Add__2('\"');
}

void ZXBasic_GenTapeLoader (INTEGER codeStartAddr, INTEGER *loaderLen, SYSTEM_BYTE *loader, LONGINT loader__len)
{
	struct GenTapeLoader__1 _s;
	_s.loaderLen = loaderLen;
	_s.loader = (void*)loader; _s.loader__len = loader__len;
	_s.lnk = GenTapeLoader__1_s;
	GenTapeLoader__1_s = &_s;
	__ASSERT(loader__len > 5, 1);
	*loaderLen = 0;
	if (codeStartAddr >= 23900 && codeStartAddr <= 65535) {
		Add__2(0);
		Add__2(10);
		Add__2(0);
		Add__2(0);
		Add__2(0xfd);
		AddIntAsVAL__4(codeStartAddr - 1);
		Add__2(':');
		Add__2(0xef);
		Add__2('\"');
		Add__2('\"');
		Add__2(0xaf);
		Add__2(':');
		Add__2(0xf9);
		Add__2(0xc0);
		AddIntAsVAL__4(codeStartAddr);
		Add__2(0x0d);
		loader[__X(2, loader__len)] = (int)(*loaderLen - 4);
		if ((LONGINT)*loaderLen >= loader__len) {
			*loaderLen = 0;
		}
	}
	GenTapeLoader__1_s = _s.lnk;
}


export void *ZXBasic__init(void)
{
	__DEFMOD;
	__IMPORT(Platform__init);
	__IMPORT(Strings__init);
	__REGMOD("ZXBasic", 0);
/* BEGIN */
	__ENDMOD;
}
