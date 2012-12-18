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
  Platform, IO := Console, Cmd := CmdLine, Strings, ZXBasic,
  (* Supported format: TAP *)
  Tap := TapeTAP;

CONST
  AddTapExt = TRUE;
  NotFound = -1;

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
  (* Parser of a parameter name. *)
VAR
  parStr: Cmd.String; n, parLen, colonPos, startPos: INTEGER;

  PROCEDURE StrToInt (minPos, maxPos: INTEGER; VAR result: INTEGER);
  (* Parser of an address - a decimal or hexadecimal number. *)
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
    FOR n := 0 TO parLen - 1 DO name[n] := name[n + startPos] END; name[parLen] := 0X; IO.WriteStr(name) ; IO.WriteLn;
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

PROCEDURE MakeZX; (* Parser of specified command line parameters. *)
VAR
  nPar, tapPar, startAddr, maxStartAddr, nParWithMaxStartAddr, dotPos: INTEGER;
  strPar, tapeName: Cmd.String;
  tap: Tap.TapeFile; data: ARRAY 65536 OF Platform.BYTE; loaderLen: INTEGER;
BEGIN
  (* Find .tap parameters: *)
  maxStartAddr := NotFound; nParWithMaxStartAddr := NotFound;
  tapPar := NotFound;
  nPar := 1; REPEAT (*FOR nPar := 1 TO Cmd.paramCount TO DO*)
    IF IsTAP(nPar) THEN
      IF tapPar = NotFound THEN (* Found first .tap parameter. *)
        tapPar := nPar;
      ELSE (* Found second or third, etc. *)
        IO.WriteStr('Conflict of the names "');
        Cmd.GetParam(nPar, strPar); IO.WriteStr(strPar); IO.WriteStr('" and "');
        Cmd.GetParam(tapPar, strPar); IO.WriteStr(strPar); IO.WriteStr('"');
        IO.WriteLn; HaltError("Please specify a TAP file only once.");
      END;
    ELSE
      GetTapeName(nPar, startAddr, tapeName, dotPos, ~AddTapExt);
      IF startAddr > maxStartAddr THEN
        maxStartAddr := startAddr; nParWithMaxStartAddr := nPar;
      END;
    END;
  INC(nPar) UNTIL nPar > Cmd.paramCount; (*END;*)
  IF tapPar # NotFound THEN (* Found once ".tap" parameter, as expected. *)
    GetTapeName(tapPar, startAddr, tapeName, dotPos, ~AddTapExt);
  ELSE
    (* ".tap" file is not specified, try to find the most probable name. *)
    GetTapeName(nParWithMaxStartAddr, startAddr, tapeName, dotPos, AddTapExt);
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

BEGIN (* Main *)
  (* ============================== ShowTitle =============================== *)
                                    (*Intel IHX*)
  IO.WriteStr("MakeZX v1.0: convert a binary file to ZX Spectrum format TAP"); IO.WriteLn;
  IO.WriteStr("Copyright (C) 2012 Oleg N. Cher, VEDAsoft Oberon Club"); IO.WriteLn;
  IO.WriteStr("http://sf.net/projects/makezx/   http://zx.oberon2.ru");
  IO.WriteLn; IO.WriteLn;
  IF Cmd.paramCount = 0 THEN (* ShowUsage. *)
    IO.WriteStr("Usage: makezx out_file.tap := in_file.bin[:starting address]"); IO.WriteLn;
    IO.WriteStr("Example: makezx mygame.tap := mygame.bin:32000");
  ELSE
    MakeZX;
  END;
  IO.WriteLn; IO.WriteLn;
END MakeZX.

(* Принцип обработки ошибок: если что-то идёт не так - ругайся. *)
