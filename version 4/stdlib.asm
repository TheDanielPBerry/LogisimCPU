//CPU based locations
SET :je = 0x01b
SET :jne = 0x08b
SET :return = 0x0002

//Pointers
SET :STACK_POINTER = 0x6000
SET :HEAP_REFERENCE = 0xA000
SET :HEAP_POINTER = 0xB000

//Device Addresses
SET :putchar = 0xFF01	//Device id in memory for the character write
SET :getchar = 0xFF02	//Device id in memory to read from the keyboard
SET :bell = 0xFF80		//Device id in memory for the bell


MOV :STACK_POINTER > SP		//Initialize stack pointer
GOTO :main

FUNC :print > RETURN(:ret) > PARAM(:str_print) > LOCAL()
	MOV MSP + :str_print > IDX
	DEFINE :loop_print
		MOV MIX + 0 > A

		OR 0,A > A	
		JE :return_print //If character is null, stop and return

		MOV A > MEM + :putchar	//output character
		ADD 1,IDX > IDX		//Increment C by 1
	GOTO :loop_print

DEFINE :return_print
RETURN


DEFINE :DisplayBreakpoint
RAW "Press Enter to Continue\n"

FUNC :breakpoint > RETURN(:ret) > PARAM() > LOCAL()
	CALL :print(&DisplayBreakpoint)
	MOV 10 > B
	DEFINE :loop_breakpoint
		MOV MEM + :getchar > A
		OR A,B > A			//Compare with line feed
		JE :return_breakpoint
	GOTO :loop_breakpoint
DEFINE :return_breakpoint
RETURN




DEFINE :num_string_pointer 	//Max length of 100 characters
RAW 0x0000
RAW "                                                                                                   "


FUNC :StringLength > RETURN(:ret) > PARAM(:str_StringLength) > LOCAL()
	MOV MSP + :str_StringLength > IDX
	MOV 0 > D
	DEFINE :loop_StringLength
		MOV MIX + 0 > A
		OR A,0 > A
		JE :return_StringLength
		ADD IDX,1 > IDX
		ADD D,1 > D
	GOTO :loop_StringLength
DEFINE :return_StringLength
MOV D > MSP + :str_StringLength
RETURN :str_StringLength

FUNC :ReverseString > RETURN(:ret) > PARAM(:str_ReverseString) > LOCAL()
	CALL :StringLength(:str_ReverseString)
	MOV MSP + :return > C
	SUB C,1 > C
	DEFINE :loop_ReverseString
		MOV MSP + :str_ReverseString > IDX
		MOV MIX + 0 > A
		ADD IDX,C > IDX
		MOV MIX + 0 > B
		MOV A > MIX + 0
		SUB IDX,C > IDX
		MOV B > MIX + 0
		ADD IDX,1 > IDX
		SUB C,2 > C
		ADD IDX,C > D
		OR D,IDX > D
		JLTE :return_ReverseString
	GOTO :loop_ReverseString
DEFINE :return_ReverseString
RETURN :str_ReverseString

FUNC :ToString > RETURN(:ret) > PARAM(:num_ToString, :result_ToString) > LOCAL()
	MOV MSP + :num_ToString > C
	MOV 10 > D
	MOV MSP + :result_ToString > IDX
	MOV 48 > B

	DEFINE :loop_ToString
		REM16 D,C > A
		ADD A,B > A
		MOV A > MIX + 0
		DIV C,D > C
		OR C,0 > C
		JE :return_ToString
		ADD IDX,1 > IDX
	GOTO :loop_ToString

DEFINE :return_ToString
MOV 0 > A
MOV A > MIX + 1
CALL :ReverseString(:result_ToString)
RETURN :result_ToString

FUNC :scanline > RETURN(:ret) > PARAM(:result_scanline) > LOCAL()
MOV 10 > B
MOV MSP + :result_scanline > IDX
DEFINE :loop_scanline
	MOV MEM + :getchar > A
	OR A,0 > A
	JE :loop_scanline		//If char was null, then don't push onto string
	MOV A > MEM + :putchar
	AND A,B > A			//Compare with line feed
	JE :return_scanline
	MOV A > MIX + 0
	ADD IDX,1 > IDX
GOTO :loop_scanline
DEFINE :return_scanline
MOV 0 > A
MOV A > MIX + 1
RETURN



DEFINE :answer
RAW 0x0026

DEFINE :message
RAW "Result Length: "

DEFINE :scan_in
RAW "                                                                                                                              "

DEFINE :main
CALL :scanline(:scan_in)

CALL :breakpoint()

CALL :StringLength(&scan_in)
MOV MSP + :return > C
MOV C > MEM + :answer


CALL :ToString(:answer, &num_string_pointer)

CALL :print(&message)
CALL :print(&num_string_pointer)

DEFINE :end
GOTO :end