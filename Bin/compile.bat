@SET WinDevBin=..\..\..\..\WinDev\Bin
@SET WinDevLib=..\..\..\..\WinDev\Lib
@SET tcc=%WinDevBin%\tcc\tcc

%tcc% -c %1.c -I "." -I %WinDevLib%
@IF errorlevel 1 PAUSE