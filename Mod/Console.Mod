(*
DEFINITION Console; (* portable layer for LibC - output to standard out *)
  PROCEDURE WriteInt* (n: LONGINT); (** Write signed long integer number into console. *)
  PROCEDURE WriteStr* (str: ARRAY [1] OF CHAR); (** Write ANSI string into console. *)
END Console.
*)

MODULE Console; (** portable layer for LibC - output to standard out *)

IMPORT SYSTEM;

PROCEDURE -includestdio()	"#include <stdio.h>";

PROCEDURE -writeInt (n: LONGINT)	'printf("%ld", n)';
PROCEDURE -writeLInt (n: LONGINT)	'printf("%lld", n)';
(*
  "%d" and "%i" are the same when used for output, e.g. with printf,
  but different when used as input specifier e.g. with scanf,
  where "%d" scans an integer as a signed decimal number,
  but "%i" allows defaults to decimal but also allows hexadecimal
  (if preceded by "0x") and octal if preceded by "0".
  So "033" would be 27 with "%i" but 33 with "%d".
*)

PROCEDURE -writeStr (str: ARRAY [1] OF CHAR)	'printf("%s", str)';

PROCEDURE -writeLn	'printf("\n")';

PROCEDURE WriteInt* (n: LONGINT); (** Write signed long integer number into console. *)
BEGIN
  IF SIZE(LONGINT) = 4 THEN writeInt(n) END;
  IF SIZE(LONGINT) = 8 THEN writeLInt(n) END;
END WriteInt;

PROCEDURE WriteStr* (str: ARRAY [1] OF CHAR); (* Write ANSI string into console. *)
  (** UNSAFE! Make sure that value of array 'str' is null-terminated. *)
BEGIN writeStr(str) END WriteStr;

PROCEDURE WriteLn* ; (** Write from next line (CR). *)
BEGIN writeLn END WriteLn;

END Console.
