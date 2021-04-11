all: fix

fix: build
	rgbfix -v -p 0 -C bitmap.gb

build: bitmap.o
	rgblink -o bitmap.gb bitmap.o

bitmap.o: bitmap.asm
	rgbasm -o bitmap.o bitmap.asm

clean:
	rm -f *.gb *.o
