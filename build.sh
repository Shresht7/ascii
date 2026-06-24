#!/usr/bin/env sh

SRC="src"
OBJ="obj"
OUT="out"

nasm -f elf64 $SRC/ascii.asm -o $OBJ/ascii.o
ld $OBJ/ascii.o -o $OUT/ascii
chmod +x $OUT/ascii

echo "Build complete. Executable is located at ./$OUT/ascii"
