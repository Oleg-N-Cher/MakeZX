@CALL +Compile.bat
@SET Bin=..\..\..\Bin
CD ..
%Bin%\upx makezx.exe
@PAUSE
