
## Sources 
0 I/O Immediate
	variable args based on destination
	Address is PC
	
1 I/O Memory - MEM
	2 args for address
	Address is ARG

2 I/O Stack - MSP
	1 arg for offset
	Address is SP + offset arg0 can be negative

3 I/O Indexed - MIX
	Address is Index	

4 Register A General purpose register
	1 execute step
5 Register B General purpose register
	1 execute step
6 Register C - 16 bit
	2 execute steps
7 Register D - 16 bit
	2 execute steps


8 PC
	2 execute steps
9 SP
	2 execute steps
10 IDX
	2 execute steps
11 ALU
	1 arg for inputs
		TOP if 0 is immediate
		Bottom, if 0 is immediate
	1 arg for operation
	Top 3 bits of arg are for the op
		0 = AND
		1 = OR
		2 = XOR
		3 = ADD
		4 = SUB
		5 = MUL
		6 = DIV
		7 = SHIFT
	Bottom 5 bits of arg are an optional signed immediate digit

12 Opcode
13 ARG
14 ARG1

## Destinations
0 
1 I/O Memory - MEM
	2 args for address

2 I/O Stack - MSP
	1 arg is the signed offset
	Address is SP + offset ARG0
3 I/O Indexed - MIX

4 Register A
5 Register B
6 Register C - 16 bit
7 Register D - 16 bit
8 PC
9 SP
10 IDX
11 CMP Register




### Example function call
byte ligma(byte a, byte b) {
	return a + b;
}

byte arg1 = 4;
byte arg2 = 6;

byte j = ligma(arg1, arg2);


#### Assembler

DEFINE arg1, 5
DEFINE arg2, 6

//Start function call
ADD SP0, 5, SP0	//Move the stack pointer to new frame
	//SP-1 = 2 byte Return Address
	//SP-2 = 1 byte Return Value
	//SP-3 = 1 byte a
	//SP-4 = 1 byte b

MOV :arg1, A	//Load arg1 into register A
MOV :arg2, B	//Load arg2 onto register
MOV A, SP, -3 	//Move arg1 onto stack
MOV B, SP, -4	//Move arg2 onto stack
MOV PC0, SP, -1	//Set the return address
MOV :ligma, PC0	//Goto ligma function
MOV SP, A, -2	//Move the return value off the stack
MOV A, :j
SUB SP0, 5, SP0 //Deallocate memory off the stack



FUNC ligma:
MOV SP, A, -3	//Load a from stack
MOV SP, B, -4	//Load b from stack
ADD A, A, B
MOV A, SP, -2	//Save return value
MOV SP, PC0, -1	//Return back to function call

#### Binary
0x0000	0x04	//:arg1 = 0x00
0x0001	0x06	//:arg2 = 0x01
0x0002	0x00	//:j is 0x02

0x0003	0xa8	//Source is ALU, Dest is stack pointer
0x0004	0x80	//top is stackpointer, bottom is direct
0x0005	0x45	//Top is ADD, Bottom is 5

0x0006	0x14	//Load arg1 into A
0x0007	0x00	//Top of :arg1
0x0008	0x00	//Bottom of :arg1

0x0009	0x15	//Load arg2 into a
0x000a	0x00	//Top of :arg2
0x000b	0x01	//Bottom of :arg2

0x000c	0x42	//Move A onto stack
0x000d	0x
0x000e
0x000f
0x0010
0x0011
0x0012
0x0013
0x0014
0x0014



## Example program to be able to run

int[5] indices = {1, 3, 4, 8, 9};

//
bool fib(int[] indexes) {
	for(int i=0; i<sizeof(index)/sizeof(int); i++) {
		if(indexes[i]) {

		}
	}
}

//str is a pointer to an array of chars
bool writeline(char* str) {
	int i = 0;
	while(str[i] != 0x00) {
		SET(0x8000, str[i]); //Write char j to memory address
		i++;
	}
	return 0;
}


byte result = fib(indices);
char* success = "The array was all fibofunctional";
char* fail = "That array sucked ass";
if(result == 0) {
	writeline(fail);
} else {
	writeline(success);
}


### Assembler
GOTO :main

DEFINE :indices 
[1, 3, 4, 8, 9]

DEFINE :success 
"The array was all fibofunctional"

DEFINE :fail 
"That array sucked ass"

DEFINE :putchar //putchar device output is device address 00
0xFF00

DEFINE :JNE
0x08


DEFINE :main
MOV MEM, IDX, :success	//Load success string pointer
MOV IDX, MSP, 2		//Add argument onto stack
MOV PC, MSP, 0		//Add Return address onto stack
GOTO :writeline

DEFINE :fib



DEFINE :writeline
ADD SP, 5, SP	//Move stack frame up by 5
MOV 0, A	//Load 0 into A
MOV A, MSP, -1	//Load A onto stack local vars

DEFINE :loop
MOV MSP, IDX, -3	//Load pointer to first char into index
MOV MSP, A, -1	//Load local var i into A
ADD IDX, A, IDX	//Add A to IDX
MOV MIX, B		//Load memory from index address into A - str[i]
CMP B, 0		//See if register A is 0 
MOV :JNE, CMP	//Load comparative flags to check against
JCMP :return_writeline	//Jump if the result flags match the CMP flags

MOV B, MEM, :putchar	//Send B register out to putchar device
ADD A, 1, A		//Add 1 to A
MOV A, MSP, 1	//Move A back to local var i on stack
GOTO :loop

:return_writeline
MOV 0, MSP, -4 	//set Return value to 0
ADD SP, -5, SP	//Reset Stack pointer frame
MOV MSP, PC, 0	//Jump to saved memory address










-----------------------------------
SET :je = 0x02
SET :jne = 0x08

0x80 > SP	//e9 80 00 - Initialize stack pointer
GOTO :main	//e8 :main
DEFINE :message 
"Fuck that shit bruv"	//Raw string in memory


DEFINE :main
CALL(:writeline, :message)	//ea :message 
							//a2 00 02 --PUSH ARGS
							//b7 80 86 --Add 6 to PC into D
							//72 00 00 --Save D onto stack return address
							//e8 :writeline -- goto writeline



DEFINE :infinite
GOTO :infinite	//db 00 e8 :infinite

DEFINE :writeline
RETURN(offset :return) -> PARAM(offset :str) -> LOCAL(offset :a)
			//--Stack frame is 8, all offsets are 2 bytes
			//:length = -6 :str = -4, :a = -2
			//b9 90 88	--move stack pointer up 8


0x00 > C	//e6 00 00 	//Initialize :a var on stack
C > MSP + :a	//62 ff fe

:loop
MSP + :str > IDX	//2a ff fc --Move str pointer into INDEX
MSP + :a > C 	//26 ff fe --Load :a into C register
ADD IDX + C > IDX //ba a6 80 --Add C to IDX

MIX + 0 > A //34 00 00 --Load char into A register

CMP A, 0, A	//b4 40 20 Compare char in A with 0
JE :return
		//d9 01	--Set flag register to 1
		//e8 :return

A > MEM, :putchar	//41 :putchar	//Write a register to putchar device address

ADD C, 1 > C	//b6 60 81	--Add 1 to C register
C > MSP + :a 	//62 ff fe --Store C register on :a var

GOTO :loop
	//db 00 --set no flags
	//e8 :loop




:return
RETURN :a
		//27 :a		--Load :a from stack into D
		//72 :return	--Save D into return var
		//b9 90 a8	--Subtract 8 from stack pointer
		//db 00 --set no flags
		//28 00 00 -- jump to return address

