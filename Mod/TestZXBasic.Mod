MODULE TestZXBasic; (*$MAIN*)

IMPORT
  SYSTEM, IO := Console, ZXBasic;

CONST
  ENTER = 0DX;
  (* ZX-BASIC tokens: *)
  CODE  = 0AFX; VAL = 0B0X; USR = 0C0X; LOAD = 0EFX; RANDOMIZE = 0F9X;
  CLEAR = 0FDX;

VAR
  n, len: INTEGER; loader: ARRAY 32 OF SYSTEM.BYTE;

BEGIN
  ZXBasic.GenTapeLoader (32000, len, loader);
  n := 0;
  WHILE len > 4 DO
    (* BASIC line number: *)
    IF len >= 2 THEN
      IO.WriteInt( ORD(SYSTEM.VAL(CHAR, loader[n+1])) +
             256 * ORD(SYSTEM.VAL(CHAR, loader[n])) );
      DEC(len, 2);
    END;
    INC(n, 2);
    (* BASIC line length: *)
    IF len >= 2 THEN
(*
      IO.WriteCh("{");
      IO.WriteInt( ORD(SYSTEM.VAL(CHAR, loader[n])) +
             256 * ORD(SYSTEM.VAL(CHAR, loader[n+1])) );
      IO.WriteStr("} ");
*)
      DEC(len, 2);
    END;
    INC(n, 2);
    (* BASIC line body: *)
    LOOP
      DEC(len);
      CASE SYSTEM.VAL(CHAR, loader[n]) OF
      | ENTER:
          IO.WriteLn; INC(n); EXIT
      | CODE:
          IO.WriteStr("CODE ");
      | VAL:
          IO.WriteStr(" VAL ");
      | USR:
          IO.WriteStr(" USR");
      | LOAD:
          IO.WriteStr(" LOAD ");
      | RANDOMIZE:
          IO.WriteStr(" RANDOMIZE");
      | CLEAR:
          IO.WriteStr(" CLEAR");
      ELSE
        IO.WriteCh(SYSTEM.VAL(CHAR, loader[n]));
      END;
      INC(n);
    END;
  END;
END TestZXBasic.