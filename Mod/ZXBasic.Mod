(* Basic program line in memory:

  MSB     LSB     LSB     MSB
+-------------+-----------------+--------+---------+
|   2 bytes   |     2 bytes     |  ...   |   #0D   |
+-------------+-----------------+--------+---------+
  line number  len of text+ENTER   text     ENTER

   Example: 10 REM BASIC
+---+----+---+---+-----+----+----+----+----+----+-------+
| 0 | 10 | 7 | 0 | 243 | 66 | 65 | 83 | 73 | 67 |       |
+---+----+---+---+-----+----+----+----+----+----+-------+
|   10   |   7   |    REM    BASIC              | ENTER |
+--------+-------+------------------------------+-------+
 number   length        text line *)

MODULE ZXBasic; (** portable *)

IMPORT Platform, Strings;

CONST
  LoaderStartLine* = 10; (* {0..9999} *)
  StackMaxSize = 40H;
  (** Code default start address, if it is not specified: *)
  CodeDefStartAddr* = 8000H + StackMaxSize; (* End of contended mem + Stack *)
  CodeMinStartAddr* = 23900;
  CodeMaxStartAddr* = 0FFFFH;
  CodeMaxSize* = CodeMaxStartAddr - CodeMinStartAddr + 1;

PROCEDURE GenTapeLoader* (codeStartAddr: INTEGER;
  (**OUT*)VAR loaderLen: INTEGER; (* Loader length if success, 0 if not. *)
  (**OUT*)VAR loader: ARRAY OF Platform.OCTET);
  CONST
    ENTER = 0DX;
    (* ZX-BASIC tokens: *)
    CODE  = 0AFX; VAL = 0B0X; USR = 0C0X; LOAD = 0EFX; RANDOMIZE = 0F9X;
    CLEAR = 0FDX;
(*VAR
  marked: INTEGER;*)
(*
  PROCEDURE AddLineNum (linenum: INTEGER); (* Add BASIC line number. *)
  BEGIN
    ASSERT((linenum >= 0) & (linenum <= 9999), 1);
    loader[loaderLen] := SHORT(linenum DIV 256); (* MSB *)
    INC(loaderLen); loader[loaderLen] := SHORT(linenum); (* LSB *)
    INC(loaderLen); marked := loaderLen; INC(loaderLen, 2); (* Mark index of line length. *)
  END AddLineNum;
*)
  PROCEDURE Add (byte: Platform.OCTET); (* Add a byte to BASIC line. *)
  BEGIN
    (* Check that LEN(loader) is enough. *)
    IF loaderLen < LEN(loader) THEN loader[loaderLen] := byte END;
    INC(loaderLen); (* To return correct loader length. *)
  END Add;

  PROCEDURE AddIntAsVAL (num: INTEGER); (* {0..99999} only. *)
  VAR
    n: INTEGER; str: ARRAY 5 + 1 (* LEN("99999" + 0X) *) OF CHAR;
  BEGIN
    ASSERT((num >= 0) & (num <= 99999), 1); Strings.IntToStr(num, str);
    Add(VAL); Add('"'); (* VAL "num" *)
    n := 0; REPEAT Add(str[n]); INC(n) UNTIL str[n] = 0X; Add('"');
  END AddIntAsVAL;
(*
  PROCEDURE EndOfLine;
  BEGIN
    Add(ENTER);
    loader[marked]     := SHORT (loaderLen - marked);
    loader[marked + 1] := SHORT((loaderLen - marked) DIV 256);
  END EndOfLine;
*)
BEGIN
  ASSERT((LoaderStartLine >= 0) & (LoaderStartLine <= 9999), 1);
  ASSERT(LEN(loader) > 5, 1); loaderLen := 0;
  IF (codeStartAddr >= CodeMinStartAddr)
  & (codeStartAddr <= CodeMaxStartAddr) THEN
    Add(LoaderStartLine DIV 256);              (* 10 *)
    Add(LoaderStartLine MOD 256);              (* BASIC line number *)
    (*marked := loaderLen;*) Add(0); Add(0);   (* BASIC line length *)
    Add(CLEAR); AddIntAsVAL(codeStartAddr - 1);(* CLEAR VAL "codeStartAddr-1" *)
    Add(":"); Add(LOAD); Add('"'); Add('"');   (* : LOAD "" *)
    Add(CODE); Add(":"); Add(RANDOMIZE);       (* CODE : RANDOMIZE *)
    Add(USR); AddIntAsVAL(codeStartAddr);      (* USR VAL "codeStartAddr" *)
    Add(ENTER);                                (* end of BASIC line. *)
    loader[(*marked*) 2] := SHORT(loaderLen - (*marked*) 4);
    (* Uncomment this code if length of BASIC line > 255. *)
    (* loader[(*marked+1*)3] := SHORT((loaderLen -(*marked*)4) DIV 256); *)
    IF loaderLen >= LEN(loader) THEN loaderLen := 0 END;
  END;
END GenTapeLoader;

END ZXBasic.

(* TODO:
 implement optimization - if codeStartAddr = "XX000" THEN use "XXe3"
*)
