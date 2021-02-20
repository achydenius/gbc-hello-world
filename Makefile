all: fix

fix: build
	rgbfix -v -p 0 -C main.gb

build: main.o
	rgblink -o main.gb main.o

main.o: main.asm
	rgbasm -o main.o main.asm

clean:
	rm -f main.gb *.o
