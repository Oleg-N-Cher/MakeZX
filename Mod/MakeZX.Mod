MODULE MakeZX;	(** portable *)

(* ВНИМАНИЕ. Здесь реализованы модели передачи аргументов на любой вкус.
   Документирован только лишь один Оберон-стиль. Также допускается задание
   не одного двоичного файла, а нескольких, что сделано "на вырост", ибо
   при текущем загрузчике по умолчанию смысла в этом мало.

1. Полный вариант:
      makezx in_file.bin[:addr] out_file.tap
2. Наоборот:
      makezx out_file.tap in_file.bin[:addr]
3. Краткий вариант (имя входного файла с макс.адресом определяет имя выходного):
      makezx in_file.bin[:addr]
4. Переадресация (целевой файл в конце):
      makezx in_file.bin[:addr] => out_file.tap
5. Оберон-стиль:
      makezx out_file.tap := in_file.bin[:addr]
*)

IMPORT
  Platform, IO := Console, Cmd := CmdLine, Strings, ZXBasic,
  (* Supported format: TAP *)
  Tap := TapeTAP;

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

PROCEDURE HaltError (err: Platform.STRING); (* Mark found error. *)
BEGIN
  IO.WriteStrLn(err); IO.WriteLn; HALT(1) (* Exit to OS with error code 1. *)
END HaltError;

PROCEDURE GetTapeName (
  param: INTEGER; VAR addr: INTEGER; VAR name: Cmd.String; VAR dotPos: INTEGER; addTapExt: BOOLEAN);
  (* Parser of a parameter name. *)
CONST
  NotFound = -1;
VAR
  parStr: Cmd.String; n, parLen, colonPos, startPos: INTEGER;

  PROCEDURE StrToInt (minPos, maxPos: INTEGER; VAR result: INTEGER);
  (* Parser of an address - a decimal or hexadecimal number. *)
  VAR
    i, resHex: INTEGER; isHex, isNum, done: BOOLEAN; ch: CHAR;
  BEGIN
    result := 0;
    IF (minPos >= 0) & (maxPos < parLen) THEN (* Check position. *)
      resHex := 0; done := FALSE; isHex := FALSE; isNum := FALSE;
      (*FOR*)i := minPos;(*TO maxPos DO*) WHILE i <= maxPos DO
        IF done THEN HaltError("Please check input file address.") END;
        ch := CAP(parStr[i]);
        CASE ch OF
        | "0".."9":
          isNum := TRUE;
          result := result*10 + ORD(ch) - ORD("0");
          resHex := resHex*16 + ORD(ch) - ORD("0");
        | "A".."F":
          isNum := TRUE; isHex := TRUE;
          result := result*10 + ORD(ch) - ORD("A") + 10;
          resHex := resHex*16 + ORD(ch) - ORD("A") + 10;
        | "H":
          isHex := TRUE; done := TRUE;
        ELSE
          IO.WriteStr('Cannot calculate input file address. Wrong character "');
          IO.WriteCh(parStr[i]); HaltError('".')
        END;
      INC(i);
      END;
      IF ~isNum THEN (* It's not a number. *)
        IO.WriteStr('Wrong address specified in parameter "');
        IO.WriteStr(parStr); HaltError('".')
      END;
      IF isHex THEN result := resHex END;
    END;
  END StrToInt;

BEGIN
  Cmd.GetParam(param, parStr); parLen := SHORT(Strings.Length(parStr));
  n := 0; colonPos := NotFound;
  (* Search position of the last ":", address may be specified after it. *)
  WHILE n < parLen DO IF parStr[n] = ":" THEN colonPos := n END; INC(n) END;
  IF colonPos # NotFound THEN
    StrToInt(colonPos + 1, parLen - 1, addr);
  ELSE
    addr := ZXBasic.DefaultCodeStartAddr;
  END;
  IF colonPos >= 0 THEN parLen := colonPos END;
  IF parLen = 0 THEN IO.WriteStr('Empty file name is specified in parameter "'); IO.WriteStr(parStr); HaltError('".') END;
  IF parLen + 4(*?*) >= LEN(name) THEN HaltError("Input file name is too long.") END;
  dotPos := NotFound; startPos := NotFound;
  FOR n := 0 TO parLen - 1 DO
    name[n] := parStr[n];
    IF parStr[n] = "." THEN dotPos := n END;
    IF (parStr[n] = "/") OR (parStr[n] = "\") THEN startPos := n + 1 END;
  END;
  IF startPos > 0 THEN (* Slash found. *)
    DEC(parLen, startPos); DEC(dotPos, startPos);
    FOR n := 0 TO parLen - 1 DO name[n] := name[n + startPos] END; name[parLen] := 0X; (*IO.WriteStrLn(name)*)
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

PROCEDURE MakeZX; (* Parse the command line parameters. Generate TAP file. *)

CONST
  AddTapExt = TRUE;
  NotFound = -1;

VAR
  paramN,       (* A current parameter number {1..Cmd.paramCount}. *)
  tapParamN,    (* The "*.tap" parameter number. *)
  startAddr,
  maxStartAddr, (* To search a possible "*.tap" file name from a binary file. *)
  paramWithMaxStartAddrN, (* Number of the parameter with max. start address. *)
  dotPos: INTEGER;
  paramStr, (* A current parameter string, indexed by paramN. *)
  tapeName: Cmd.String;
  tap: Tap.TapeFile;
  data: ARRAY 65536 OF Platform.BYTE; (* ZX Spectrum binary data. *)
  loaderLen: INTEGER;

  PROCEDURE IsTAP (): BOOLEAN;
    (* Check: has a current paramStr[paramN] the extens. "*.tap"? *)
  VAR
    paramStrLen: LONGINT;
  BEGIN
    paramStrLen := Strings.Length(paramStr);
    IF (paramStrLen >= 5) (* LEN("*.tap") *)
     & (    paramStr[paramStrLen - 4]  = ".")
     & (CAP(paramStr[paramStrLen - 3]) = "T")
     & (CAP(paramStr[paramStrLen - 2]) = "A")
     & (CAP(paramStr[paramStrLen - 1]) = "P") THEN RETURN TRUE
    END;
    RETURN FALSE
  END IsTAP;

BEGIN
  (*==========================================================================*)
  (* Find "*.tap" parameter(s) and non-"*.tap" parameter with max.start addr. *)
  (*--------------------------------------------------------------------------*)
  maxStartAddr := -1; paramWithMaxStartAddrN := NotFound; tapParamN := NotFound;
  paramN := 1; REPEAT (*FOR paramN := 1 TO Cmd.paramCount DO*)
    Cmd.GetParam(paramN, paramStr);
    IF IsTAP() THEN (* paramStr[paramN] has the extens. "*.tap". *)
      IF tapParamN = NotFound THEN (* The first "*.tap" parameter found. *)
        tapParamN := paramN;
      ELSE (* The second "*.tap" parameter found. *)
        IO.WriteStr('Conflict of the names "'); IO.WriteStr(paramStr);
        IO.WriteStr('" and "'); Cmd.GetParam(tapParamN, paramStr);
        IO.WriteStr(paramStr); IO.WriteStrLn('".');
        HaltError("Please specify a TAP file only once.")
      END;
    ELSE (* It's not a "*.tap" parameter. Try to find paramWithMaxStartAddrN. *)
      (* Get a binary file start address (or default start address: *)
      GetTapeName(paramN, startAddr, tapeName, dotPos, ~AddTapExt);
      IF startAddr > maxStartAddr THEN (* A probable "*.tap" file name found. *)
        maxStartAddr := startAddr; paramWithMaxStartAddrN := paramN;
      END;
    END;
  INC(paramN) UNTIL paramN > Cmd.paramCount; (*END;*)

  (*==========================================================================*)
  (*     Analyze: what "*.tap" and not "*.tap" parameters are specified?      *)
  (*--------------------------------------------------------------------------*)
  IF paramWithMaxStartAddrN = NotFound THEN (* No one binary file found. *)
    HaltError("Please specify a binary file to convert to TAP.")
  END;
  IF tapParamN # NotFound THEN  (* Once ".tap" parameter found, as expected. *)
    (* WARNING: GetTapeName used to remove "*..\", "*../" (to incr. safety). *)
    (* The tool MakeZX can generate "*.tap" files only in current directory. *)
    GetTapeName(tapParamN, startAddr, tapeName, dotPos, ~AddTapExt);
  ELSE
    (* "*.tap" file is not specified, try to find the most probable name. *)
    GetTapeName(paramWithMaxStartAddrN, startAddr, tapeName, dotPos, AddTapExt);
  END;

  (*==========================================================================*)
  (*                      Now tapeName is ready to open.                      *)
  (*--------------------------------------------------------------------------*)
  tap.ReCreate(tapeName);
  IF tap.error THEN
    IO.WriteStr('Cannot create tape file "');
    IO.WriteStr(tapeName); HaltError('". Wrong file name.')
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

BEGIN (* Main *) (* ShowTitle: *)
  IO.WriteStrLn("MakeZX v1.0 RC1: convert a binary file to ZX Spectrum format TAP");
  IO.WriteStrLn("Copyright (C) 2012 Oleg N. Cher, VEDAsoft Oberon Club");
  IO.WriteStrLn("http://sf.net/projects/makezx/ + http://zx.oberon2.ru");
  IO.WriteLn;
  IF Cmd.paramCount = 0 THEN (* ShowUsage: *)
    IO.WriteStrLn("Usage: makezx out_file.tap := in_file.bin[:starting address]");
    IO.WriteStrLn("Example: makezx mygame.tap := mygame.bin:32000");
  ELSE (* Cmd.paramCount >= 1 *)
    MakeZX;
  END;
  IO.WriteLn;
END MakeZX.

(* TODO:
  implement supporting the Intel IHX format.
*)
