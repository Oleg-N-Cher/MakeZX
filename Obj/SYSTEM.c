#include "SYSTEM.h"

extern void exit (int status);

/* runtime system routines */
extern void SYSTEM_INIT (int argc, long argvadr);

/* runtime system variables */
LONGINT SYSTEM_argc;
LONGINT SYSTEM_argv;

void SYSTEM_INIT (int argc, long argvadr)
{
  SYSTEM_argc = argc;
  SYSTEM_argv = *(long*)argvadr;
  //SYSTEM__init();
}

void SYSTEM_FINALL (void)
{
  exit(0);
}

void SYSTEM_FINI (void)
{
  SYSTEM_FINALL();
}
