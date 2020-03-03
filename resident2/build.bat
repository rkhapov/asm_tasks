del resident.com 2>NUL
tasm /t resident.asm
tlink /t resident.obj
del resident.obj 2>NUL
del resident.map 2>NUL

del printer.com 2>NUL
tasm /t printer.asm
tlink /t printer.obj
del printer.obj 2>NUL
del printer.map 2>NUL
