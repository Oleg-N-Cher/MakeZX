MODULE ZXBasic; (** portable. *)

IMPORT Platform;

CONST
  LoaderStartLine = 10; (* Must be < 256. *)
(*
  "DEFFN","CAT","FORMAT","MOVE","ERASE","OPEN#",
	"CLOSE#","MERGE","VERIFY","BEEP","CIRCLE","INK",
	"PAPER","FLASH","BRIGHT","INVERSE","OVER","OUT",
	"LPRINT","LLIST","STOP","READ","DATA","RESTORE",
	"NEW","BORDER","CONTINUE","DIM","REM","FOR","GOTO",
	"GOSUB","INPUT","LOAD","LIST","LET","PAUSE","NEXT",
	"POKE","PRINT","PLOT","RUN","SAVE","RANDOMIZE",
	"IF","CLS","DRAW","CLEAR","RETURN","COPY"};
*)

TYPE
  BYTE = Platform.BYTE;

PROCEDURE GenTapeLoader* (
  codeStartAddr: INTEGER; VAR loaderLen: INTEGER; VAR loader: ARRAY OF BYTE);
(** After calling of this procedure: loaderLen IN{1..LEN(loader)}, OK;
    loaderLen = 0, if codeStartAddr ~IN{0..65535} or LEN(loader) < 6;
    loaderLen > LEN(loader), if size of array 'loader' is not enough. *)

(* Basic program line in memory:

 MSB     LSB    LSB    MSB
+-------------+-------------+--------+---------+
|   2bytes    |   2bytes    |  ...   |   #0D   |
+-------------+-------------+--------+---------+
  line number  len of text+    text     ENTER
                  +ENTER
Example:

10 REM BASIC
+---+----+---+---+-----+----+----+----+----+----+--------+
| 0 | 10 | 7 | 0 | 243 | 66 | 65 | 83 | 73 | 67 |        |
+---+----+---+---+-----+----+----+----+----+----+--------+
|   10   |   7   |    REM    BASIC              |  ENTER |
+--------+-------+------------------------------+--------+
 number   length        text line
 
*)
(*VAR
  marked: INTEGER;*)
(*
  PROCEDURE AddLineNum (linenum: INTEGER); (* Add BASIC line number. *)
  BEGIN
    ASSERT((linenum >= 0) & (linenum <= 9999));
    loader[loaderLen] := SHORT(linenum DIV 256); (* MSB *)
    INC(loaderLen); loader[loaderLen] := SHORT(linenum); (* LSB *)
    INC(loaderLen); marked := loaderLen; INC(loaderLen, 2); (* Mark index of line length. *)
  END AddLineNum;
*)
  PROCEDURE Add (b: BYTE); (* Add a byte to BASIC line. *)
  BEGIN
    (* Check that LEN(loader) is enough. *)
    IF loaderLen < LEN(loader) THEN loader[loaderLen] := b END;
    INC(loaderLen); (* To return correct loader length. *)
  END Add;

  PROCEDURE AddIntAsVAL (num: INTEGER); (* {0..99999} only. *)
  VAR
    digit: INTEGER; nonzero: BOOLEAN;
  BEGIN
    Add(0B0X); Add(022X); (* VAL " *)
    nonzero := FALSE;
    digit := num DIV 10000;
    IF digit # 0 THEN
      Add(SHORT(digit + ORD("0"))); nonzero := TRUE;
    END;
    digit := (num DIV 1000) MOD 10;
    IF nonzero OR (digit # 0) THEN
      Add(SHORT(digit + ORD("0"))); nonzero := TRUE;
    END;
    digit := (num DIV 100) MOD 10;
    IF nonzero OR (digit # 0) THEN
      Add(SHORT(digit + ORD("0"))); nonzero := TRUE;
    END;
    digit := (num DIV 10) MOD 10;
    IF nonzero OR (digit # 0) THEN
      Add(SHORT(digit + ORD("0")));
    END;
    Add(SHORT(num MOD 10 + ORD("0")));
    Add(022X); (* " *)
  END AddIntAsVAL;
(*
  PROCEDURE EndOfLine;
  BEGIN
    Add(0DX); INC(loaderLen); (* CR *)
    loader[marked]     := SHORT (loaderLen - marked);
    loader[marked + 1] := SHORT((loaderLen - marked) DIV 256);
  END EndOfLine;
*)
BEGIN
  loaderLen := 0;
  IF (LEN(loader) >= 6) & (codeStartAddr >= 0) & (codeStartAddr <= 0FFFFH) THEN
    Add(0); Add(LoaderStartLine);              (* 10 BASIC line number *)
    (*marked := loaderLen;*) Add(0); Add(0);   (* BASIC line length *)
    Add(0FDX); AddIntAsVAL(codeStartAddr - 1); (* CLEAR VAL "codeStartAddr-1" *)
    Add(03AX); Add(0EFX); Add(022X); Add(022X);(* : LOAD "" *)
    Add(0AFX); Add(03AX); Add(0F9X); Add(0C0X);(* CODE : RANDOMIZE USR *)
    AddIntAsVAL(codeStartAddr); Add((*CR*)0DX);(* VAL "codeStartAddr"\0DH *)
    loader[(*marked*)  2] := SHORT (loaderLen -(*marked*)4);
    (* Uncomment this code if length of BASIC line > 255. *)
    (* loader[(*marked+1*)3] := SHORT((loaderLen -(*marked*)4) DIV 256); *)
  END;
END GenTapeLoader;

END ZXBasic.

(* TODO:
 implement GenTapeLoader must return BOOLEAN state of successful
*)
