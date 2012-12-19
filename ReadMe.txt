MakeZX v1.0 RC1
===============
This tool is a converter from binary files
to ZX Spectrum TAP tape image files,
widely used in ZX Spectrum emulators.

Usage:
  makezx out_file.tap := in_file.bin[:starting address]

where "in_file.bin" is an existing binary file,
and "starting address" is a decimal or hexadecimal number.
If it is not specified, used default value 26000.

Example:
  makezx mygame.tap := game.bin:7D00H

MakeZX adds to your tape the default boot loader:

10 CLEAR VAL "codeStartAddr-1": LOAD ""CODE : RANDOMIZE USR VAL "codeStartAddr"


License
=======
MakeZX is available under BSD-like license.
For details, please read file License.txt

Official website of MakeZX tool:

http://sf.net/projects/makezx/

MakeZX is written in Oberon-2 language.
To build it from sources, you need XDev kit:

https://github.com/Oleg-N-Cher/BB-XDev/

Yes, we like the language Oberon:
VEDAsoft Oberon Club - http://zx.oberon2.ru

Oleg N. Cher, the author.
2012, Dnepropetrovsk, Ukraine.