all: fix

fix: build
	rgbfix -v -p 0 -C main.gb

build: main.o
	rgblink -o main.gb main.o

main.o: main.asm monoglyph.2bpp gradient.inc
	rgbasm -o main.o main.asm

monoglyph.2bpp: monoglyph.png
	rgbgfx -v -o monoglyph.2bpp monoglyph.png

gradient.inc: create-gradient.py
	./create-gradient.py > gradient.inc

clean:
	rm -f main.gb *.o *.2bpp gradient.inc
