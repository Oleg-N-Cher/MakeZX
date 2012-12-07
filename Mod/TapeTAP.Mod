(* ========================================================================== *)
(*                                 TAP format                                 *)
(* -------------------------------------------------------------------------- *)

MODULE TapeTAP; (** portable *)
(* Дизайн модуля диктуется трудностями в Linux'е с вычислением размера файла. *)
(* Ещё я сознательно избегаю использовать динамическую память и сборку мусора.*)

IMPORT
  Platform, Files;

TYPE
  (* Standard platform types: *)
  BYTE = Platform.BYTE;

  (* TAP format: *)
  TapeFile* = RECORD
    file: Files.File;
    (*checksum: SET;*)
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
PROCEDURE (VAR tap: TapeFile) ReCreate* (tapeName: ARRAY OF CHAR);
BEGIN
  tap.file.OpenToWrite(tapeName);
  IF ~tap.file.isNoError THEN Assert("Cannot create TAP file") END;
END ReCreate;

(*----------------------------------------------------------------------------*)
PROCEDURE (VAR tap: TapeFile) WriteByte (b: BYTE);
BEGIN
  ASSERT(b <= 0FFH);
  tap.file.WriteByte(b);
  IF tap.file.status # OK THEN Assert("Cannot write to tape file"); Assert(tap.name); END;
  tap.checksum := tap.checksum * SET(b); (* ? *)
END WriteByte;

PROCEDURE (VAR tap: TapeFile) WriteWord (w: WORD);
BEGIN
  ASSERT(b <= 0FFFFH);
  tap.file.WriteByte(w);
  IF tap.file.status # OK THEN Assert("Cannot write to tape file"); Assert(tap.name); END;
  tap.file.WriteByte(w DIV 256);
END WriteWord;

PROCEDURE (VAR tap: TapeFile) WriteCheckSum;
BEGIN
  tap.file.WriteByte(ORD(tap.checksum));
END WriteCheckSum;

PROCEDURE (VAR tap: TapeFile) WriteCodeHeader; (*
================================================================================
|     CODE header or SCREEN$ header - for storing machine code or screens.     |
+---------------------------------+--------------------------------------------+
Ofs: Field type: Len: Description:| Additional information:                    |
--+--------------+--+-------------+--------------------------------------------+
 0|     BYTE     | 1|  flag byte  |Always 0 - indicating a ROM loading header  |
 1|     BYTE     | 1|  data type  |Always 3 - byte indicating a byte header    |
 2|ARR 10 OF CHAR|10|  file name  |Loading CODE name (filled with spaces " ")  |
12|     WORD     | 2|[data length]|Len of the following data (after the header)|
  |              |  |             | in case of a SCREEN$ header = 6912         |
14|     WORD     | 2|start address| in case of a SCREEN$ header = 16384        |
16|     WORD     | 2|   unused    | = 32768                                    |
17|     BYTE     | 1|checksum byte|Simply all bytes (including flag byte) XORed|
==+==============+==+=============+============================================+
*)
  TapeHeader = RECORD (* TAP header format (19 bytes): *)
    (* 1*)loadHeader: BYTE;       (* Always 0 - indicating a ROM loading header. *)
    (* 2*)byteHeader: BYTE;       (* Always 3 - byte indicating a byte header.   *)
    (* 3*)name: ARRAY 10 OF CHAR; (* Name of the program. Filled with spaces.    *)
    (*13*)dataLength: WORD;
    (*15*)startAddr : WORD;
    (*17*)unused    : WORD;
    (*19*)checksum  : BYTE;
   END;

BEGIN
  tap.WriteWord(19); (* Standard tape header size = 19 bytes.     *)
  tap.checksum := 0;
  tap.WriteByte(0);  (* 0 indicates ROM header; 0FFH = ROM data.  *)
  tap.WriteByte(3);  (* Always 3 - byte indicating a byte header. *)
  (* Write the CODE name (10 bytes, if less, filled with spaces). *)
  nameIdx := 0;
  FOR i := 0 TO 9 DO (* Cut CODE name, if its len > 10. *)
    IF (nameIdx <= LEN(tap.name)) & (tap.name[nameIdx] # 0X) THEN
      tap.WriteByte(tap.name[nameIdx]);
      INC(nameIdx);
    ELSE
      tap.WriteByte(" ");
    END;
  END;
  (* Write CODE data length (after the header). SCREEN$ length = 6912. *)
  tap.WriteWord(tap.dataLength);
  (* Write CODE start address. SCREEN$ header start address = 16384.   *)
  tap.WriteWord(tap.dataStartAddr);
  tap.WriteWord(32768); (* Always = 32768. *)
  tap.WriteCheckSum;  (* Simply all bytes (including flag byte) XORed. *)
END WriteCodeHeader;

PROCEDURE (VAR tap: TapeFile) WriteCodeBody; (*
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
BEGIN
  tap.WriteWord(1 + tap.dataLength + 1); (* flag + data length + checksum. *)
  tap.checksum := 0;
  tap.WriteByte(255);  (* 255 indicates a standard ROM loading data block. *)
  FOR i := 0 TO tap.dataLength - 1 DO
    tap.WriteByte(tap.data[i]);
  END;
  tap.WriteCheckSum;  (* Simply all bytes (including flag byte) XORed. *)
END WriteCodeBody;

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

END TapeTAP.

