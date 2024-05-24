SET :je = 0x01b
SET :jne = 0x08b
SET :STACK_POINTER = 0x8000
SET :putchar = 0xFF01	//Device id in memory for the character write
SET :bell = 0xFF80		//Device id in memory for the bell

MOV :STACK_POINTER > SP		//Initialize stack pointer
GOTO :main

DEFINE :length
RAW 0x0000

DEFINE :result
RAW 0x0000

DEFINE :main
MOV 5 > D
MOV D > MSP + 4 //Set d as param for next call
ADD PC,8 > IDX	
MOV IDX > MSP + 0 //Add return address
GOTO :fibo
MOV MSP + 2 > D
MOV D > MEM + :result

DEFINE :stop
GOTO :stop







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



SET :sum = -2
SET :index = -4
DEFINE :fibo	//Recursive framesize is 8
ADD SP,8 > SP 	//Move frame stack
MOV MSP + :index > D
SUB D,1 > D
JLTE :endRecur

//Call fibo(index-1)
MOV D > MSP + 4 //Set d as param for next call
ADD PC,8 > IDX	
MOV IDX > MSP + 0 //Add return address
GOTO :fibo

//fibo(index-2)
MOV MSP + 2 > D	//load return value into d
MOV D > MSP + :sum	//save into sum

MOV MSP + :index > C
SUB C,2 > C
MOV C > MSP + 4
ADD PC,8 > IDX
MOV IDX > MSP + 0 //Add return address
GOTO :fibo

MOV MSP + 2 > D	 //load return value into d
MOV MSP + :sum > C
ADD D,C > D
MOV D > MSP + :sum
RETURN 8 :sum



DEFINE :endRecur
MOV 30 > A
MOV A > MEM + :bell
MOV 1 > C
MOV C > MSP + :sum
RETURN 8 :sum

