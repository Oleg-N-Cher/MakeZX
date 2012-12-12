@SET obj=..\..\..\..\Ofront\Obj
@SET tcc=..\..\..\..\WinDev\Bin\tcc\tcc.exe -Wall

@CD Obj
@DEL *.o

@IF EXIST %obj%\Platform.h MOVE /Y %obj%\Platform.h
@IF EXIST %obj%\Platform.c MOVE /Y %obj%\Platform.c
@IF EXIST %obj%\Console.h MOVE /Y %obj%\Console.h
@IF EXIST %obj%\Console.c MOVE /Y %obj%\Console.c
@IF EXIST %obj%\CmdLine.h MOVE /Y %obj%\CmdLine.h
@IF EXIST %obj%\CmdLine.c MOVE /Y %obj%\CmdLine.c
@IF EXIST %obj%\Files.h MOVE /Y %obj%\Files.h
@IF EXIST %obj%\Files.c MOVE /Y %obj%\Files.c
@IF EXIST %obj%\TapeTAP.h MOVE /Y %obj%\TapeTAP.h
@IF EXIST %obj%\TapeTAP.c MOVE /Y %obj%\TapeTAP.c
@IF EXIST %obj%\MakeZX.c MOVE /Y %obj%\MakeZX.c

%tcc% -c SYSTEM.c
%tcc% -c Platform.c
%tcc% -c Console.c
%tcc% -c CmdLine.c
%tcc% -c Files.c
%tcc% -c TapeTAP.c
%tcc% MakeZX.c SYSTEM.o Platform.o Console.o CmdLine.o Files.o TapeTAP.o -omakezx.exe

@IF EXIST MakeZX.exe MOVE MakeZX.exe ..
@PAUSE
