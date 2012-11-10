MODULE MakeZX; (** portable *)

IMPORT
  Out := Console, Cmd := CmdLine;

(* ========================================================================== *)
(*                                 TAP format                                 *)
(* -------------------------------------------------------------------------- *)
TYPE
  TAP* = RECORD
  END;

PROCEDURE (VAR tap: TAP) Open* (name: ARRAY OF CHAR);
PROCEDURE (VAR tap: TAP) WriteBas* (name: ARRAY OF CHAR);
PROCEDURE (VAR tap: TAP) WriteBin* (name: ARRAY OF CHAR);
PROCEDURE (VAR tap: TAP) WriteIhx* (name: ARRAY OF CHAR);
PROCEDURE (VAR tap: TAP) Close* ;
(* ========================================================================== *)

PROCEDURE Title;
BEGIN
  Out.WriteStr("MakeZX is a converter from BIN/IHX to ZX Spectrum format TAP"); Out.Ln;
END Title;

PROCEDURE Run;
VAR
  param: Cmd.String; i: LONGINT;
BEGIN
  Title;
  Out.WriteStr("ParamCount = "); Out.WriteInt(Cmd.ParamCount); Out.Ln;
  FOR i := 0 TO Cmd.ParamCount DO
    Out.WriteStr("["); Out.WriteInt(i); Out.WriteStr("] = ");
    Cmd.GetParam(i, param); Out.WriteStr(param); Out.Ln;
  END;
END Run;

BEGIN
  Run;
END MakeZX.
