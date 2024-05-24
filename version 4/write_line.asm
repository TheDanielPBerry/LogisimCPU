SET :je = 0x01b
SET :jne = 0x08b
SET :STACK_POINTER = 0x8000
SET :putchar = 0xFF01	//Device id in memory for the character write

MOV :STACK_POINTER > SP		//Initialize stack pointer
GOTO :main

DEFINE :length
RAW 0x0000

DEFINE :main
MOV :message > IDX
MOV IDX > MSP + 4
ADD PC,8 > IDX	
MOV IDX > MSP + 0 //Add return address
GOTO :writeline

MOV MSP + 2 > C
MOV C > MEM + :length
MOV 10 > A
MOV A > MEM + :putchar	//Break line
GOTO :main


SET :i = -2
SET :str = -4
SET :frameSize = 8
DEFINE :writeline
ADD SP,8 > SP
MOV 0 > C
MOV C > MSP + :i	//initialize local var as 0

DEFINE :loop
MOV MSP + :i > C
MOV MSP + :str > IDX

ADD IDX,C > IDX
MOV MIX + 0 > A

MOV :je > CMP
OR A,0 > A
JMP :return

MOV A > MEM + :putchar

ADD C,1 > C
MOV C > MSP + :i	//increment :a var

GOTO :loop


DEFINE :return
RETURN 8 :i


DEFINE :message
RAW "Fuck that shit I'm out"
