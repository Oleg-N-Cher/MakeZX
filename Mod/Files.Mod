(*
DEFINITION
END .
*)

MODULE Files; (** portable layer for LibC - file IO *)

IMPORT SYSTEM;

TYPE
  File = RECORD (** Binary file *)
  END;

PROCEDURE Open* (VAR file: File; name: ARRAY OF CHAR);
BEGIN
END Open;

PROCEDURE Close* (VAR file: File);
BEGIN
END Close;

PROCEDURE ReadByte* (VAR fromfile: File): SYSTEM.BYTE;
BEGIN
END ReadByte;

(*
VAR
  bin: Files.BinFile; i: INTEGER; ch: CHAR;
BEGIN
  bin.OpenRead("Filename.bin");
    IF bin.err # Files.Ok THEN ... END;
    bin.ReadInt(i); bin.Read(ch);
  bin.Close;

  bin.OpenWrite("Filename2.bin");
    IF bin.err # Files.Ok THEN ... END;
    bin.WriteInt(i); bin.Write(ch);
  bin.Close;
END;
*)

