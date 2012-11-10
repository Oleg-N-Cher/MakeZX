(*
DEFINITION CmdLine; (* portable layer for LibC - command line parameters handling *)
  VAR ParamCount-: LONGINT;
  PROCEDURE GetParam (n: LONGINT; VAR param: ARRAY OF CHAR);
END CmdLine.
*)

MODULE CmdLine; (** portable layer for LibC - command line parameters handling *)

IMPORT SYSTEM;

TYPE
  String* = ARRAY 1024 OF CHAR;
  ArgPtr = POINTER [1] TO ARRAY [1] 1024 OF CHAR;
  ArgVec = POINTER [1] TO ARRAY [1] 1024 OF ArgPtr;

VAR
  ParamCount-: LONGINT; (* argc - 1 *)

PROCEDURE -Argc(): INTEGER "SYSTEM_argc";
PROCEDURE -Argv(): LONGINT "(long)SYSTEM_argv";

PROCEDURE GetParam* (n: LONGINT; VAR param: ARRAY OF CHAR);
VAR
  av: ArgVec;
BEGIN
  IF n <= ParamCount THEN
    av := SYSTEM.VAL(ArgVec, Argv()); COPY(av[n]^, param);
  ELSE
    COPY("", param);
  END;
END GetParam;

BEGIN
  ParamCount := Argc() - 1;
END CmdLine.
