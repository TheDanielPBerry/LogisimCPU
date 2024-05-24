SET :je = 0x01b
SET :jne = 0x08b
SET :STACK_POINTER = 0x8000
SET :putchar = 0xFF01	//Device id in memory for the character write
SET :bell = 0xFF80		//Device id in memory for the bell
SET :return = 0x0002

MOV :STACK_POINTER > SP		//Initialize stack pointer
GOTO :main

DEFINE :returnVal
RAW 0x0002

DEFINE :arg0
0x0002

FUNC :sum > RETURN(:ret) > PARAM(:a, :b) > LOCAL(:result)
	MOV MSP + :a > C
	MOV MSP + :b > D
	ADD C,D > C
	MOV C > MSP + :result
RETURN :result



DEFINE :main
CALL :sum(:arg0, 4)
GOTO :end
MOV MSP + :return > C
MOV C > MEM + :returnVal

DEFINE :end
GOTO :end