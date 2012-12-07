(*
DEFINITION
END .
*)

MODULE Files; (** portable layer for LibC - file IO *)
(*
    Description: provides a simple buffered file input/output library.
*)

IMPORT SYSTEM;

CONST
  Successful* = 0;
  Failed* = 3;

TYPE
  PtrFILE = INTEGER; (* Internal system type. *)
  PtrSTR = ARRAY [1] OF CHAR;

  File* = RECORD (** Binary file *)
    handle: PtrFILE;
    isNoError- : BOOLEAN; (* isNoError - returns a TRUE if no error has occured on file. *)
    state- : INTEGER; (* successful, outofmemory, toomanyfilesopen, failed, connectionfailure. *)
  END;

(*
   OpenToRead - attempts to open a file, fname, for reading and
                it returns this file.
                The success of this operation can be checked by
                calling IsNoError.
*)

PROCEDURE -includestdio()	"#include <stdio.h>";

PROCEDURE -fopen(filename, mode: PtrSTR): PtrFILE "fopen(filename, mode)";
PROCEDURE -fclose(file: PtrFILE) "fclose(file)";

PROCEDURE (VAR file: File) OpenToRead* (fname: ARRAY [1] OF CHAR);
BEGIN
  file.state := Successful;
  file.handle := fopen(fname, "rb");
  IF file.handle = 0 THEN file.state := Failed END;
END OpenToRead;

(*
   OpenToWrite - attempts to open a file, fname, for write and
                 it returns this file.
                 The success of this operation can be checked by
                 calling IsNoError.
*)

PROCEDURE (VAR file: File) OpenToWrite* (fname: ARRAY OF CHAR);
BEGIN
  file.state := Successful;
  file.handle := fopen(fname, "wb");
  IF file.handle = 0 THEN file.state := Failed END;
END OpenToWrite;

(*
   Close - close a file which has been previously opened using:
           OpenToRead, OpenToWrite, OpenForRandom.
           It is correct to close a file which has an error status.
*)

PROCEDURE (VAR file: File) Close* ;
BEGIN
  IF file.handle # 0 THEN
    fclose(file.handle); file.handle := 0; file.state := Successful;
  ELSE
    file.state := Failed;
  END;
END Close;

(*
PROCEDURE (VAR fromfile: FileToRead) ReadByte* (): SYSTEM.BYTE;
BEGIN
END ReadByte;
*)
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

END Files.
