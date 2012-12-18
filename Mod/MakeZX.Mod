MODULE MakeZX; (** portable *)

(*
Полный вариант:
  makezx in_file.bin[:addr] out_file.tap
Наоборот (делать ли?):
  makezx out_file.tap in_file.bin[:addr]
Короткий вариант:
  makezx in_file.bin[:addr]
Оберон-стиль:
  makezx out_file.tap := in_file.bin[:addr]
*)

IMPORT
  Platform, IO := Console, Cmd := CmdLine, Strings,
  (* Supported format: TAP *)
  Tap := TapeTAP, ZXBasic;

(*
  name     type len start  prog |
1 COPY-COPY P  2048     0  2048 |
2 Loader    P    30    10    30 |
3 test/test B  7560 32768     0 |
4 mycode    B     4 26000 32768 |
*)
(*
01 OOOOOOOOOOOOOOOOOOOOOOO     4
02 Loader      BASIC    10    30
03 OOOOOOOOOOOOOOOOOOOOOOO    30
04 test/test   CODE  32768  7560
05 OOOOOOOOOOOOOOOOOOOOOOO  7560
*)
(* Parser of the command line. *)
(*
PROCEDURE Run;
VAR
  param: Cmd.String; i: INTEGER;
BEGIN
  Title;
  Out.WriteStr("ParamCount = "); Out.WriteInt(Cmd.paramCount); Out.Ln;
  FOR i := 0 TO Cmd.paramCount DO
    Out.WriteStr("["); Out.WriteInt(i); Out.WriteStr("] = ");
    Cmd.GetParam(i, param); Out.WriteStr(param); Out.Ln;
  END;
END Run; *)

(*
PROCEDURE CreateTape; (** For testing - must give exact tape image: *)
VAR
  tap: Tap.TapeFile; data: ARRAY 2 OF Platform.BYTE;
BEGIN
  data[0] := CHR(243); data[1] := CHR(175);
  tap.ReCreate("mytape.tap");
  tap.SaveCode("ROM", 0, 2, data);
END ...
*)
(*
PROCEDURE CreateTape;
VAR
  tap: Tap.TapeFile; data: ARRAY 4 OF Platform.BYTE;
BEGIN
  data[0] := 3EX; data[1] := 41X; (* LD A,"A" *)
  data[2] := 0D7X; (* RST #10 *)
  data[3] := 0C9X; (* RET *)
  tap.ReCreate("mytape.tap");
  IF tap.error THEN
    IO.WriteStr("Tape creating error"); IO.WriteLn;
  ELSE
    IO.WriteStr("Tape created OK"); IO.WriteLn;
    tap.SaveCode("mycode", 26000, 4, data);
    IF tap.error THEN
      IO.WriteStr("Cannot write to tape file"); IO.WriteLn;
    END;
    tap.Finalize;
  END;
END CreateTape;

PROCEDURE AddBasic;
VAR
  tap: Tap.TapeFile;
  loaderLen: INTEGER;
  data: ARRAY 65536 OF Platform.BYTE;
BEGIN
  (* BASIC *)
  ZXBasic.GenTapeLoader(26000, loaderLen, data);
  tap.ReCreate("loader.tap");
  tap.SaveBasic("Loader", 10, loaderLen, data);
  (* CODE *)
  data[0] := 3EX; data[1] := 41X; (* LD A,"A" *)
  data[2] := 0D7X; (* RST #10 *)
  data[3] := 0C9X; (* RET *)
  tap.SaveCode("mycode", 26000, 4, data);
  tap.Finalize;
END AddBasic;
*)

PROCEDURE HaltError (str: Platform.STRING); (* Mark found error. *)
BEGIN
  IO.WriteStr(str); IO.WriteLn; IO.WriteLn; HALT(1);
END HaltError;

PROCEDURE IsTAP (param: INTEGER): BOOLEAN; (* Check: is a param.ext. ".tap"? *)
VAR
  parStr: Cmd.String; parLen: LONGINT;
BEGIN
  Cmd.GetParam(param, parStr); parLen := Strings.Length(parStr);
  IF (parLen >= 5)
   & (    parStr[parLen - 4]  = '.')
   & (CAP(parStr[parLen - 3]) = "T")
   & (CAP(parStr[parLen - 2]) = "A")
   & (CAP(parStr[parLen - 1]) = "P") THEN RETURN TRUE;
  END;
  RETURN FALSE;
END IsTAP;

PROCEDURE GetTapeName (
  param: INTEGER; VAR addr: INTEGER; VAR name: Cmd.String; VAR dotPos: INTEGER; addTapExt: BOOLEAN);
VAR
  parStr: Cmd.String; n, parLen, colonPos, startPos: INTEGER;

  PROCEDURE StrToInt (minPos, maxPos: INTEGER; VAR result: INTEGER);
  VAR
    i, resHex: INTEGER; isHex, isNum, done: BOOLEAN;
  BEGIN
    result := 0;
    IF (minPos >= 0) & (maxPos < parLen) THEN (* Check position. *)
      resHex := 0; done := FALSE; isHex := FALSE; isNum := FALSE;
      (*FOR*)i := minPos;(*TO maxPos DO*) WHILE i <= maxPos DO
        IF done THEN HaltError("Please check input file address.") END;
        CASE parStr[i] OF
        | "0".."9":
          isNum := TRUE;
          result := result*10 + ORD(parStr[i]) - ORD("0");
          resHex := resHex*16 + ORD(parStr[i]) - ORD("0");
        | "A".."F":
          isNum := TRUE; isHex := TRUE;
          result := result*10 + ORD(parStr[i]) - ORD("A") + 10;
          resHex := resHex*16 + ORD(parStr[i]) - ORD("A") + 10;
        | "a".."f":
          isNum := TRUE; isHex := TRUE;
          result := result*10 + ORD(parStr[i]) - ORD("a") + 10;
          resHex := resHex*16 + ORD(parStr[i]) - ORD("a") + 10;
        | "H", "h":
          isHex := TRUE; done := TRUE;
        ELSE
          IO.WriteStr('Cannot calculate input file address. Wrong character "');
          IO.WriteCh(parStr[i]); HaltError('".');
        END;
      INC(i);
      END;
      IF ~isNum THEN (* It's not a number. *)
        IO.WriteStr('Wrong address specified in parameter "');
        IO.WriteStr(parStr); HaltError('".');
      END;
      IF isHex THEN result := resHex END;
    END;
  END StrToInt;

BEGIN
  Cmd.GetParam(param, parStr); parLen := SHORT(Strings.Length(parStr));
  n := 0; colonPos := -1;
  (* Search position of the last ":", address may be specified after it. *)
  WHILE n < parLen DO IF parStr[n] = ":" THEN colonPos := n END; INC(n) END;
  IF colonPos >= 0 THEN
    StrToInt(colonPos + 1, parLen - 1, addr);
  ELSE
    addr := ZXBasic.DefaultCodeStartAddr;
  END;
  IF colonPos >= 0 THEN parLen := colonPos END;
  IF parLen = 0 THEN IO.WriteStr('Empty file name is specified in parameter "'); IO.WriteStr(parStr); HaltError('".') END;
  IF parLen + 4(*?*) >= LEN(name) THEN HaltError("Input file name is too long.") END;
  dotPos := -1; startPos := -1;
  FOR n := 0 TO parLen - 1 DO
    name[n] := parStr[n];
    IF parStr[n] = "." THEN dotPos := n END;
    IF (parStr[n] = "/") OR (parStr[n] = "\") THEN startPos := n + 1 END;
  END;
  IF startPos > 0 THEN (* Slash found. *)
    DEC(parLen, startPos); DEC(dotPos, startPos);
    FOR n := 0 TO parLen -1 DO name[n] := name[n + startPos] END; name[parLen] := 0X; IO.WriteStr(name) ; IO.WriteLn;
  END;
  IF dotPos < 0 THEN (* "." not found. *)
    dotPos := parLen;
  END;
  IF addTapExt THEN
    name[dotPos] := ".";
    name[dotPos + 1] := "t";
    name[dotPos + 2] := "a";
    name[dotPos + 3] := "p";
    name[dotPos + 4] := 0X;
  END;
END GetTapeName;

PROCEDURE MakeZX; (* Analyze command line parameters. *)
    (*
    IO.WriteStr("Par["); IO.WriteInt(i); IO.WriteStr("]="); IO.WriteStr(str);
    IO.WriteStr(" "); IF IsTAP(i) THEN IO.WriteStr("Y") ELSE IO.WriteStr("N") END;
    IO.WriteLn;
    *)
VAR
  nPar, tapPar, startAddr, maxStartAddr, nParWithMaxStartAddr, dotPos: INTEGER;
  strPar, tapeName: Cmd.String;
  tap: Tap.TapeFile; data: ARRAY 65536 OF Platform.BYTE; loaderLen: INTEGER;
BEGIN
  (* Find .tap parameters: *)
  maxStartAddr := -1; nParWithMaxStartAddr := -1;
  tapPar := 0; (* 0 is not found. *)
  nPar := 1; REPEAT (*FOR nPar := 1 TO Cmd.paramCount TO DO*)
    IF IsTAP(nPar) THEN
      IF tapPar = 0 THEN (* Found first .tap parameter. *)
        tapPar := nPar;
      ELSE (* Found second or third, etc. *)
        IO.WriteStr('Conflict of the names "');
        Cmd.GetParam(nPar, strPar); IO.WriteStr(strPar); IO.WriteStr('" and "');
        Cmd.GetParam(tapPar, strPar); IO.WriteStr(strPar); IO.WriteStr('"');
        IO.WriteLn; HaltError("Please specify a TAP file only once.");
      END;
    ELSE
      GetTapeName(nPar, startAddr, tapeName, dotPos, FALSE);
      IF startAddr > maxStartAddr THEN
        maxStartAddr := startAddr; nParWithMaxStartAddr := nPar;
      END;
    END;
  INC(nPar) UNTIL nPar > Cmd.paramCount; (*END;*)
  IF tapPar > 0 THEN (* Found once ".tap" parameter, as expected. *)
    GetTapeName(tapPar, startAddr, tapeName, dotPos, FALSE);
  ELSE
    (* ".tap" file is not specified, try to find the most probable name. *)
    GetTapeName(nParWithMaxStartAddr, startAddr, tapeName, dotPos, TRUE);
  END;

  (*==========================================================================*)
  (*                      Now tapeName is ready to open.                      *)
  (*==========================================================================*)
  tap.ReCreate(tapeName);
  IF tap.error THEN
    IO.WriteStr('Cannot create tape file "'); IO.WriteStr(tapeName); HaltError('". Wrong file name.');
  END;
  (* BASIC *)
  IF dotPos >= 0 THEN tapeName[dotPos] := 0X END;
  (* ... *) IO.WriteInt(startAddr);
  ZXBasic.GenTapeLoader(startAddr, loaderLen, data);
  IF loaderLen = 0 THEN HaltError("Please check start address, that must be in {0..0FFFFH}.") END;
  tap.SaveBasic(tapeName, ZXBasic.LoaderStartLine, loaderLen, data);
  IF tap.error THEN END; (* ? *)
  (* CODE *)
  data[0] := 3EX; data[1] := 41X; (* LD A,"A" *)
  data[2] := 0D7X; (* RST #10 *)
  data[3] := 0C9X; (* RET *)
  tap.SaveCode("mycode", 26000, 4, data);
  tap.Finalize;
END MakeZX;

(*
  IF Cmd.paramCount = 0 THEN
    ShowUsage;
  ELSE
    paramN := paramCount;
    REPEAT
      AnalyzeParam(paramN);
      DEC(paramN);
    UNTIL paramN = 0;
    IF paramsOk THEN Make ELSE (* ShowErr *) END;
  END;
END MakeZX; *)

BEGIN (* Main *)                       (*/Intel IHX*)
  (* ============================== ShowTitle =============================== *)
  IO.WriteStr("MakeZX v1.0: convert a binary file to ZX Spectrum format TAP");
  IO.WriteLn;
  (* IO.WriteStr("May be used as linker for SDCC/ZXDev"); IO.WriteLn; *)
  IO.WriteStr("Copyright (C) 2012 Oleg N. Cher, VEDAsoft Oberon Club");
  IO.WriteLn;
  IO.WriteStr("http://sf.net/projects/makezx/   http://zx.oberon2.ru");
  IO.WriteLn; IO.WriteLn;
  IF Cmd.paramCount = 0 THEN (* ShowUsage. *)
    IO.WriteStr("Usage: makezx out_file.tap := in_file.bin[:starting address]");
    IO.WriteLn;
    IO.WriteStr("Example: makezx mygame.tap := mygame.bin:32000");
    IO.WriteLn; IO.WriteLn;
  ELSE
    MakeZX;
  END;
END MakeZX.
 (*
  ShowTitle;
  IF Cmd.paramCount = 0 THEN
    ShowUsage;
  ELSE
    paramMin := 1; paramMax := paramCount;
    REPEAT
      IF IsTAP(n) THEN ... END;
      AnalyzeParam(paramN);
      DEC(paramN);
    UNTIL paramN = 0;
    IF paramsOk THEN Make ELSE (* ShowErr *) END;
  END;

  
  
  CASE Cmd.paramCount OF
  (* makezx *)
  | 0: ShowUsage;
  (* makezx infile.bin *)
  | 1: (* Задан один входной файл, имя выходного получим, изменив расширение. *)
  (* makezx infile.bin outfile.tap *)
  | 2: (* Вход и выход. *)
  ELSE
  END;
  CreateTape;
  AddBasic; *)
END MakeZX.

(* Принцип обработки ошибок: если что-то идёт не так - ругайся. *)
