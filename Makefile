all: fix

fix: build
	rgbfix -v -p 0 -C main.gb

build: main.o
	rgblink -o main.gb main.o

main.o: main.asm r.2bpp
	rgbasm -o main.o main.asm

r.2bpp: r.png
	rgbgfx -v -o r.2bpp r.png

clean:
	rm -f main.gb *.o *.2bpp
