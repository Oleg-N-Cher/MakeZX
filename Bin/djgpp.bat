@SET DJGPP=d:\Archive\Projects\XDev\WinDev\Bin\djgpp\djgpp.env
@SET PATH=d:\Archive\Projects\XDev\WinDev\Bin\djgpp\bin;%PATH%
@SET gcc=gcc.exe @..\Bin\djgpp.opt

@CD ..\Obj
%gcc% MakeZX.c ZXBasic.c ..\..\..\..\WinDev\Lib\WinDevDJGPP.a ..\..\..\..\WinDev\Bin\djgpp\lib\libmsvcrt.a
@IF ERRORLEVEL 1 @PAUSE
@IF EXIST a.out @DEL a.out
@IF EXIST aout.exe MOVE /Y aout.exe ..\makezx.exe