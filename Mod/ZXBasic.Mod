MODULE ZXBasic; (** portable. *)

IMPORT Platform;

(*
CONST
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
VAR
  marked: INTEGER;

  PROCEDURE AddLineNum (linenum: INTEGER); (* Add BASIC line number. *)
  BEGIN
    ASSERT((linenum >=0 ) & (linenum <= 9999));
    loader[loaderLen] := SHORT(linenum DIV 256); (* MSB *)
    INC(loaderLen); loader[loaderLen] := SHORT(linenum); (* LSB *)
    INC(loaderLen); marked := loaderLen; INC(loaderLen, 2); (* Mark index of line length. *)
  END AddLineNum;

  PROCEDURE Add (b: BYTE); (* Add a byte to BASIC line. *)
  BEGIN
    loader[loaderLen] := b; INC(loaderLen);
  END Add;

  PROCEDURE AddIntStr (num: INTEGER); (* {0..99999} only. *)
  VAR
    digit: INTEGER; nonzero: BOOLEAN;
  BEGIN
    nonzero := FALSE;
    digit := num DIV 10000;
    IF digit # 0 THEN
      loader[loaderLen] := SHORT(digit + ORD("0")); INC(loaderLen); nonzero := TRUE;
    END;
    digit := (num DIV 1000) MOD 10;
    IF nonzero OR (digit # 0) THEN
      loader[loaderLen] := SHORT(digit + ORD("0")); INC(loaderLen); nonzero := TRUE;
    END;
    digit := (num DIV 100) MOD 10;
    IF nonzero OR (digit # 0) THEN
      loader[loaderLen] := SHORT(digit + ORD("0")); INC(loaderLen); nonzero := TRUE;
    END;
    digit := (num DIV 10) MOD 10;
    IF nonzero OR (digit # 0) THEN
      loader[loaderLen] := SHORT(digit + ORD("0")); INC(loaderLen);
    END;
    loader[loaderLen] := SHORT(num MOD 10 + ORD("0")); INC(loaderLen);
  END AddIntStr;

  PROCEDURE EndOfLine;
  BEGIN
    Add(0DX); INC(loaderLen); (* CR *)
    loader[marked]     := SHORT (loaderLen - marked);
    loader[marked + 1] := SHORT((loaderLen - marked) DIV 256);
  END EndOfLine;
  
BEGIN (* Check that LEN(loader) is enough. *)
  loaderLen := 0;
  (* 0, 10: 10 *)
  (* 1AX,0: BASIC line length *)
  AddLineNum(10);
  Add(0FDX); Add(0B0X); Add(022X); (* CLEAR VAL " *)
  AddIntStr(codeStartAddr - 1);    (* 32767   *)
  Add(022X); Add(03AX); Add(0EFX); (* ": LOAD *)
  Add(022X); Add(022X); Add(0AFX); (* ""CODE  *)
  Add(03AX); Add(0F9X); Add(0C0X); (* : RANDOMIZE USR *)
  Add(0B0X); Add(022X);            (* VAL " *)
  AddIntStr(codeStartAddr);        (* 32768 *)
  Add(022X); EndOfLine;            (* "\0DH *)
END GenTapeLoader;

END ZXBasic.

(* TODO:
 implement GenTapeLoader must return BOOLEAN state of successful
*)
