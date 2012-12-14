MODULE MakeZX; (** portable *)

IMPORT
  Platform, IO := Console, Cmd := CmdLine,
  (* Supported format: TAP *)
  Tap := TapeTAP, ZXBasic;

PROCEDURE Title;
BEGIN                                  (*/Intel IHX*)
  IO.WriteStr("MakeZX v1.0: convert a binary file to ZX Spectrum format TAP"); IO.WriteLn;
  (* IO.WriteStr("May be used as linker for SDCC/ZXDev"); IO.WriteLn; *)
  IO.WriteStr("Copyright (C) 2012 Oleg N. Cher, VEDAsoft Oberon Club"); IO.WriteLn;
  IO.WriteStr("http://sf.net/projects/makezx/   http://zx.oberon2.ru"); IO.WriteLn;
  IO.WriteLn; IO.WriteLn;
  IO.WriteStr("Usage: makezx out_file.tap := in_file.bin[:starting address]"); IO.WriteLn;
  IO.WriteStr("Example: makezx mygame.tap := mygame.bin:32000"); IO.WriteLn;
END Title;

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

VAR
  tap: Tap.TapeFile; data: ARRAY 2 OF Platform.BYTE;
BEGIN
  data[0] := CHR(243); data[1] := CHR(175);
  tap.ReCreate("mytape.tap");
  tap.SaveCode("ROM", 0, 2, data);
END ...
*)

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
  ZXBasic.GenTapeLoader(26000, loaderLen, data);
  tap.ReCreate("loader.tap");
  tap.SaveBasic("Loader", 10, loaderLen, data);
  tap.Finalize;
END AddBasic;
  
BEGIN
  Title;
  CreateTape;
  AddBasic;
END MakeZX.

(* Принцип обработки ошибок: если что-то идёт не так - ругайся. *)
