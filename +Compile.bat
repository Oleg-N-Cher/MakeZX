@SET obj=..\..\..\..\Ofront\Obj
@SET tcc=..\..\..\..\WinDev\Bin\tcc\tcc.exe

@CD Obj
@DEL *.o

@IF EXIST %obj%\Console.h COPY /Y /B %obj%\Console.h
@IF EXIST %obj%\Console.c COPY /Y /B %obj%\Console.c
@IF EXIST %obj%\CmdLine.h COPY /Y /B %obj%\CmdLine.h
@IF EXIST %obj%\CmdLine.c COPY /Y /B %obj%\CmdLine.c
@IF EXIST %obj%\MakeZX.c COPY /Y /B %obj%\MakeZX.c

@IF NOT EXIST SYSTEM.o %tcc% -c SYSTEM.c
@IF NOT EXIST Console.o %tcc% -c Console.c
@IF NOT EXIST CmdLine.o %tcc% -c CmdLine.c
%tcc% MakeZX.c SYSTEM.o Console.o CmdLine.o

@IF EXIST MakeZX.exe MOVE MakeZX.exe ..
@PAUSE
