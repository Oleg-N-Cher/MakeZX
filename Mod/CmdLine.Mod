MODULE CmdLine; (** portable layer for LibC - command line parameters handling *)

IMPORT SYSTEM;

TYPE
  String* = ARRAY 1024 OF CHAR;
  ArgPtr = POINTER [1] TO ARRAY [1] 1024 OF CHAR;
  ArgVec = POINTER [1] TO ARRAY [1] 1024 OF ArgPtr;

VAR
  paramCount-: INTEGER; (* argc - 1 *)

PROCEDURE -argc(): INTEGER "SYSTEM_argc";
PROCEDURE -argv(): LONGINT "(long)SYSTEM_argv";

PROCEDURE GetParam* (n: INTEGER; VAR param: ARRAY OF CHAR);
VAR
  av: ArgVec;
BEGIN
  IF n <= paramCount THEN
    av := SYSTEM.VAL(ArgVec, argv()); COPY(av[n]^, param);
  ELSE
    COPY("", param);
  END;
END GetParam;

BEGIN
  paramCount := argc() - 1;
END CmdLine.