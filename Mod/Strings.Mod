MODULE Strings; (** non-portable. *)

IMPORT SYSTEM;

TYPE
  PtrSTR = ARRAY [1] OF CHAR;

PROCEDURE -includestdio()	"#include <stdio.h>";

PROCEDURE -sprintf (str: PtrSTR; n: LONGINT)	'sprintf(str, "%ld", n)'; 
PROCEDURE -sprintfL (str: PtrSTR; n: LONGINT)	'sprintf(str, "%lld", n)';

PROCEDURE IntToStr* (n: LONGINT; VAR str: ARRAY [1] OF CHAR);
  (** UNSAFE! Make sure that size of array 'str' is enough. *)
BEGIN
  IF SIZE(LONGINT) = 4 THEN sprintf(str, n) END;
  IF SIZE(LONGINT) = 8 THEN sprintfL(str, n) END;
END IntToStr;

END Strings.
