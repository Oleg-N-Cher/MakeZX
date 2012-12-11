(* ========================================================================== *)
(*                                 TAP format                                 *)
(* -------------------------------------------------------------------------- *)

MODULE TapeTAP; (** portable *)
(* Дизайн модуля диктуется трудностями в Linux'е с вычислением размера файла  *)
(*  до того момента как он будет полностью прочитан (файл может быть потоком).*)
(* Ещё я сознательно избегаю использовать динамическую память и сборку мусора.*)

IMPORT
  SYSTEM, Platform, Files;

TYPE
  (* Standard platform types: *)
  BYTE = Platform.BYTE;
  STRING = Platform.STRING;
  WORD = INTEGER;
  
  (* TAP format: *)
  TapeFile* = RECORD
    file: Files.FileToWrite;
    error-: BOOLEAN;
    checksum: SET; (* BITS *)
  END;

(*
PROCEDURE (VAR tap: Tape) ReCreate* (tapeName: ARRAY OF CHAR);
PROCEDURE (VAR tap: Tape) WriteBas* (name: ARRAY OF CHAR);
PROCEDURE (VAR tap: Tape) WriteBin* (
  name: ARRAY OF CHAR; startAddr, dataLength: INTEGER; VAR data: ARRAY OF BYTE);
PROCEDURE (VAR tap: Tape) WriteIhx* (name: ARRAY OF CHAR);
PROCEDURE (VAR tap: Tape) Close* ;
*)
(*
  IMPORT TapeTAP;
  VAR
    tap: TapeTAP.TapeFile; data: ARRAY 4 OF BYTE;
  BEGIN
    data[0] := 3EH; data[1] := 41H; data[2] := 0D3H; data[3] := 0C9H;
    tap.ReCreate("mytape.tap");
    tap.SaveCode("mycode", 26000, 4, data);
    tap.Finalize;
  END ... *)

(*----------------------------------------------------------------------------*)
PROCEDURE (VAR tap: TapeFile) ReCreate* (tapeName: STRING);
BEGIN
  tap.file.OpenToWrite(tapeName);
  tap.error := tap.file.error; (* Выносим обработку ошибок на уровень выше. *)
END ReCreate;

(*----------------------------------------------------------------------------*)
PROCEDURE (VAR tap: TapeFile) SaveByte (b: BYTE);
BEGIN
  IF ~tap.error THEN tap.file.WriteByte(b); tap.error := tap.file.error END;
(*
  IF tap.file.status # OK THEN Assert("Cannot write to tape file"); Assert(tap.name); END; *)
  tap.checksum := tap.checksum / SYSTEM.VAL(SET, b); (* checksum := checksum XOR b *)
END SaveByte;

PROCEDURE (VAR tap: TapeFile) SaveWord (w: WORD);
BEGIN
  IF (w >= 0) & (w <= 0FFFFH) THEN (* w IN {0..65535} *)
    IF ~tap.error THEN tap.SaveByte(SHORT(w)); tap.error := tap.file.error END;
    IF ~tap.error THEN tap.SaveByte(SHORT(w DIV 256)); tap.error := tap.file.error END;
  ELSE (* ~(w IN {0..65535}) *)
    tap.error := TRUE; (* Причину укажем в tap.state *)
  END; (*
  IF tap.file.status # OK THEN Assert("Cannot write to tape file"); Assert(tap.name); END;
   tap.error := tap.file.error; *)
END SaveWord;

PROCEDURE (VAR tap: TapeFile) SaveCheckSum;
BEGIN
  tap.file.WriteByte(SHORT(Platform.ORD(tap.checksum)));
END SaveCheckSum;

PROCEDURE (VAR tap: TapeFile) SaveBasicHeader (name: STRING; startLine, dataLength: INTEGER);
(*
================================================================================
|BASIC program header or program autostart header - for storing BASIC programs.|
+---------------------------------+--------------------------------------------+
Ofs: Field type: Len: Description:| Additional information:                    |
--+--------------+--+-------------+--------------------------------------------+
 0|     BYTE     | 1|  flag byte  | Always 0: indicating a ROM loading header  |
 1|     BYTE     | 1|  data type  | Always 0: Byte indicating a program header |
 2|ARR 10 OF CHAR|10|  file name  |Loading BASIC name (filled with spaces " ") |
12|     WORD     | 2|[data length]|Length of the BASIC program + variables len |
14|     WORD     | 2|autostrt line| LINE parameter of SAVE command. 32768 means|
  |              |  |             |no auto-loading; 0..9999 are valid line nums|
16|     WORD     | 2|[program len]| length of BASIC program; remaining bytes   |
  |              |  |             |[data len]-[program len]=offset of variables|
18|     BYTE     | 1|checksum byte|Simply all bytes (including flag byte) XORed|
==+==============+==+=============+============================================+
*)
VAR
  i, nameIdx: INTEGER;
BEGIN
  tap.SaveWord(19); (* Standard tape header size = 19 bytes.     *)
  tap.checksum := {};
  tap.SaveByte(0);  (* Always 0: Indicates ROM header; 0FFH = ROM data. *)
  tap.SaveByte(0);  (* Always 0: Byte indicates a BASIC header.  *)
  (* Write the CODE name (10 bytes, if less, filled with spaces). *)
  nameIdx := 0;
  FOR i := 0 TO 9 DO (* Cut CODE name, if its len > 10. *)
    IF (nameIdx <= LEN(name)) & (name[nameIdx] # 0X) THEN
      tap.SaveByte(name[nameIdx]);
      INC(nameIdx);
    ELSE
      tap.SaveByte(" ");
    END;
  END;
  (* Write BASIC data length (after the header). *)
  tap.SaveWord(dataLength);
  (* BASIC autostart line. 32768 = no auto-loading; 0..9999 = valid line nums.*)
  IF ((startLine >= 0) & (startLine <= 9999)) OR (startLine = 32768) THEN
    tap.SaveWord(startLine);
  ELSE
    tap.error := TRUE; (* Incorrect autostart line number. *)
  END;
  tap.SaveWord(dataLength); (* Variables now are not supported. *)
  tap.SaveCheckSum; (* Simply all bytes (including flag byte) XORed. *)
END SaveBasicHeader;

PROCEDURE (VAR tap: TapeFile) SaveCodeHeader (name: STRING; dataStartAddr, dataLength: INTEGER);
(*
================================================================================
|     CODE header or SCREEN$ header - for storing machine code or screens.     |
+---------------------------------+--------------------------------------------+
Ofs: Field type: Len: Description:| Additional information:                    |
--+--------------+--+-------------+--------------------------------------------+
 0|     BYTE     | 1|  flag byte  | Always 0: indicating a ROM loading header  |
 1|     BYTE     | 1|  data type  | Always 3: Byte indicating a byte header    |
 2|ARR 10 OF CHAR|10|  file name  | Loading CODE name (filled with spaces " ") |
12|     WORD     | 2|[data length]| Length of the CODE data (after the header) |
  |              |  |             | in case of a SCREEN$ header = 6912         |
14|     WORD     | 2|start address| in case of a SCREEN$ header = 16384        |
16|     WORD     | 2|   unused    | = 32768                                    |
18|     BYTE     | 1|checksum byte|Simply all bytes (including flag byte) XORed|
==+==============+==+=============+============================================+

  TapeHeader = RECORD (* TAP header format (19 bytes): *)
    (* 1*)loadHeader: BYTE;       (* = 0 - indicates a ROM loading header.    *)
    (* 2*)byteHeader: BYTE;       (* = 3 - indicates a byte header.           *)
    (* 3*)name: ARRAY 10 OF CHAR; (* Name of the program. Filled with spaces. *)
    (*13*)dataLength: WORD;       (* Len of the CODE data (after the header). *)
    (*15*)startAddr : WORD;       (* Start address of the followed CODE data. *)
    (*17*)unused    : WORD;       (* = 32768 - unused.                        *)
    (*19*)checksum  : BYTE;       (* Simply all bytes (incl.flag byte) XORed. *)
   END;
*)
VAR
  i, nameIdx: INTEGER;
BEGIN
  tap.SaveWord(19); (* Standard tape header size = 19 bytes.     *)
  tap.checksum := {};
  tap.SaveByte(0);  (* 0 indicates ROM header; 0FFH = ROM data.  *)
  tap.SaveByte(3);  (* Always 3. Byte indicating a byte header.  *)
  (* Write the CODE name (10 bytes, if less, filled with spaces). *)
  nameIdx := 0;
  FOR i := 0 TO 9 DO (* Cut CODE name, if its len > 10. *)
    IF (nameIdx <= LEN(name)) & (name[nameIdx] # 0X) THEN
      tap.SaveByte(name[nameIdx]);
      INC(nameIdx);
    ELSE
      tap.SaveByte(" ");
    END;
  END;
  (* Write CODE data length (after the header). SCREEN$ length = 6912. *)
  tap.SaveWord(dataLength);
  (* Write CODE start address. SCREEN$ header start address = 16384.   *)
  tap.SaveWord(dataStartAddr);
  tap.SaveWord(32768); (* Always = 32768. *)
  tap.SaveCheckSum;  (* Simply all bytes (including flag byte) XORed. *)
END SaveCodeHeader;

PROCEDURE (VAR tap: TapeFile) SaveDataArray (dataLength: INTEGER; VAR data: ARRAY OF BYTE);
(*
================================================================================
|     Standard data blocks or custom data blocks - (2+[data length]) bytes     |
+---------------------------------+--------------------------------------------+
Ofs: Field type: Len: Description:| Additional information:                    |
--+--------------+--+-------------+--------------------------------------------+
 0|     BYTE     | 1|  flag byte  | = 255 - a standard ROM loading data block. |
 1| ARRAY OF BYTE| ?|  data block | The essential data block (may be empty).   |
1+[data len] BYTE| 1|checksum byte|Simply all bytes (including flag byte) XORed|
==+==============+==+=============+============================================+
*)
VAR
  i: INTEGER;
BEGIN
  tap.SaveWord(1 + dataLength + 1); (* flag + data length + checksum. *)
  tap.checksum := {};
  tap.SaveByte(0FFX);  (* 255 indicates a standard ROM loading data block. *)
  FOR i := 0 TO dataLength - 1 DO
    tap.SaveByte(data[i]);
  END;
  tap.SaveCheckSum;  (* Simply all bytes (including flag byte) XORed. *)
END SaveDataArray;

(*
PROCEDURE (VAR tap: TapeFile) SaveCode* (fileName: ARRAY OF CHAR; start: WORD);
VAR
  bin: File;
BEGIN
  bin := File.Open(fileName);
  IF bin # NIL THEN
    tap.dataLength := 0;
    WHILE ~bin.eof DO (* Read binary data file. *)
      IF tap.dataLength >= LEN(tap.data) THEN Assert("Input file is too big") END;
      data[tap.dataLength] := bin.ReadByte();
      IF bin.status # OK THEN Assert("Cannot read file "); Assert(fileName) END;
      INC(tap.dataLength);
    END;
    Close(bin);
    WriteCodeHeader;
    WriteCodeBody;
  END;
END SaveCode;
*)

PROCEDURE (VAR tap: TapeFile) SaveBasic* (
  name: STRING; startLine, dataLength: INTEGER; VAR data: ARRAY OF BYTE);
BEGIN
  tap.SaveBasicHeader(name, startLine, dataLength);
  tap.SaveDataArray(dataLength, data);
END SaveBasic;

PROCEDURE (VAR tap: TapeFile) SaveCode* (
  name: STRING; startAddr, dataLength: INTEGER; VAR data: ARRAY OF BYTE);
BEGIN
  tap.SaveCodeHeader(name, startAddr, dataLength);
  tap.SaveDataArray(dataLength, data);
END SaveCode;

PROCEDURE (VAR tap: TapeFile) Finalize* ;
BEGIN
  tap.file.Close;
END Finalize;

END TapeTAP.
