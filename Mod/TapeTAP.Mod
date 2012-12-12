(* ========================================================================== *)
(*                                 TAP format                                 *)
(* -------------------------------------------------------------------------- *)

(* The .TAP files contain blocks of tape-saved data. All blocks start with two
bytes specifying how many bytes will follow (not counting the two length bytes).
Then raw tape data follows, including the flag and checksum bytes. The checksum
is the bitwise XOR of all bytes including the flag byte. For example, when you
execute the line SAVE "ROM" CODE 0,2 this will result:

             |------ Spectrum-generated data -------|       |---------|

       13 00 00 03 52 4f 4d 7x20 02 00 00 00 00 80 f1 04 00 ff f3 af a3

       ^^^^^...... first block is 19 bytes (17 bytes+flag+checksum)
             ^^... flag byte (A reg, 00 for headers, ff for data blocks)
                ^^ first byte of header, indicating a code block

       file name ..^^^^^^^^^^^^^
       header info ..............^^^^^^^^^^^^^^^^^
       checksum of header .........................^^
       length of second block ........................^^^^^
       flag byte ............................................^^
       first two bytes of rom .................................^^^^^
       checksum (checkbittoggle would be a better name!).............^^

Note that it is possible to join .TAP files by simply stringing them together,
for example COPY /B FILE1.TAP + FILE2.TAP ALL.TAP

For completeness, I'll include the structure of a tape header. A header always
consists of 17 bytes:

        Byte    Length  Description
        ---------------------------
        0       1       Type (0,1,2 or 3)
        1       10      Filename (padded with blanks)
        11      2       Length of data block
        13      2       Parameter 1
        15      2       Parameter 2

The type is 0,1,2 or 3 for a Program, Number array, Character array or Code
file. A SCREEN$ file is regarded as a Code file with start address 16384 and
length 6912 decimal. If the file is a Program file, parameter 1 holds the
autostart line number (or a number >=32768 if no LINE parameter was given) and
parameter 2 holds the start of the variable area relative to the start of the
program. If it's a Code file, parameter 1 holds the start of the code block
when saved, and parameter 2 holds 32768. For data files finally, the byte at
position 14 decimal holds the variable name. *)

MODULE TapeTAP; (** portable *)

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
  (* tap.checksum := tap.checksum XOR b *)
  tap.checksum := tap.checksum / SYSTEM.VAL(SET, b);
END SaveByte;

(*----------------------------------------------------------------------------*)
PROCEDURE (VAR tap: TapeFile) SaveWord (w: WORD);
BEGIN
  IF (w >= 0) & (w <= 0FFFFH) THEN (* w IN {0..65535} *)
    IF ~tap.error THEN tap.SaveByte(SHORT(w)); tap.error := tap.file.error END;
    IF ~tap.error THEN tap.SaveByte(SHORT(w DIV 256)); tap.error := tap.file.error END;
  ELSE (* ~(w IN {0..65535}) *)
    tap.error := TRUE; (* Причину укажем в tap.state *)
  END;
END SaveWord;

(*----------------------------------------------------------------------------*)
PROCEDURE (VAR tap: TapeFile) SaveCheckSum;
BEGIN
  tap.file.WriteByte(SHORT(Platform.ORD(tap.checksum)));
END SaveCheckSum;

(*----------------------------------------------------------------------------*)
PROCEDURE (VAR tap: TapeFile) SaveName (name: STRING);
  (* Write a name (10 bytes, if less, filled with spaces). *)
VAR
  i, nameIdx: INTEGER;
BEGIN
  nameIdx := 0;
  FOR i := 0 TO 9 DO (* Cut a name, if its len > 10. *)
    IF (nameIdx <= LEN(name)) & (name[nameIdx] # 0X) THEN
      tap.SaveByte(name[nameIdx]);
      INC(nameIdx);
    ELSE
      tap.SaveByte(" ");
    END;
  END;
END SaveName;

(*----------------------------------------------------------------------------*)
PROCEDURE (VAR tap: TapeFile) SaveBasicHeader (
  name: STRING; startLine, dataLength: INTEGER);
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
BEGIN
  tap.SaveWord(19); (* Standard tape header size = 19 bytes.     *)
  tap.checksum := {};
  tap.SaveByte(0);  (* Always 0: Indicates ROM header; 0FFH = ROM data. *)
  tap.SaveByte(0);  (* Always 0: Byte indicates a BASIC header.  *)
  (* Write the CODE name (10 bytes, if less, filled with spaces). *)
  tap.SaveName(name);
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

(*----------------------------------------------------------------------------*)
PROCEDURE (VAR tap: TapeFile) SaveCodeHeader (
  name: STRING; dataStartAddr, dataLength: INTEGER);
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
BEGIN
  tap.SaveWord(19); (* Standard tape header size = 19 bytes.     *)
  tap.checksum := {};
  tap.SaveByte(0);  (* 0 indicates ROM header; 0FFH = ROM data.  *)
  tap.SaveByte(3);  (* Always 3. Byte indicating a byte header.  *)
  (* Write the CODE name (10 bytes, if less, filled with spaces). *)
  tap.SaveName(name);
  (* Write CODE data length (after the header). SCREEN$ length = 6912. *)
  tap.SaveWord(dataLength);
  (* Write CODE start address. SCREEN$ header start address = 16384.   *)
  tap.SaveWord(dataStartAddr);
  tap.SaveWord(32768); (* Always = 32768. *)
  tap.SaveCheckSum;  (* Simply all bytes (including flag byte) XORed. *)
END SaveCodeHeader;

(*----------------------------------------------------------------------------*)
PROCEDURE (VAR tap: TapeFile) SaveDataBlock (
  dataLength: INTEGER; VAR data: ARRAY OF BYTE);
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
END SaveDataBlock;

(*----------------------------------------------------------------------------*)
PROCEDURE (VAR tap: TapeFile) SaveBasic* (
  name: STRING; startLine, dataLength: INTEGER; VAR data: ARRAY OF BYTE);
BEGIN
  tap.SaveBasicHeader(name, startLine, dataLength);
  tap.SaveDataBlock(dataLength, data);
END SaveBasic;

(*----------------------------------------------------------------------------*)
PROCEDURE (VAR tap: TapeFile) SaveCode* (
  name: STRING; startAddr, dataLength: INTEGER; VAR data: ARRAY OF BYTE);
BEGIN
  tap.SaveCodeHeader(name, startAddr, dataLength);
  tap.SaveDataBlock(dataLength, data);
END SaveCode;

(*----------------------------------------------------------------------------*)
PROCEDURE (VAR tap: TapeFile) Finalize* ;
BEGIN
  tap.file.Close;
END Finalize;

(*============================================================================*)
END TapeTAP.

(*
  IMPORT TapeTAP;
  VAR
    tap: TapeTAP.TapeFile; data: ARRAY 4 OF BYTE;
  BEGIN
    data[0] := 3EX; data[1] := 41X; data[2] := 0D3X; data[3] := 0C9X;
    tap.ReCreate("mytape.tap");
    tap.SaveCode("mycode", 26000, 4, data);
    tap.Finalize;
  END ...
*)

(* TODO:
  implement SaveDataBlock with Files.SaveBytes (incr. efficiency).
*)