@SET WinDevBin=..\..\..\..\WinDev\Bin
@SET WinDevLib=..\..\..\..\WinDev\Lib
@SET tcc=%WinDevBin%\tcc\tcc

%tcc% ZXBasic.c TapeTAP.c MakeZX.c -I "." -I %WinDevLib% %WinDevLib%\WinDev.a -o makezx.exe
@IF errorlevel 1 PAUSE
@IF EXIST makezx.exe MOVE /Y makezx.exe ..