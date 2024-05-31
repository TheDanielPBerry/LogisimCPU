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


SET :heap_bound_lower = 0xA000
SET :heap_bound_upper = 0xA002
SET :heap_bound_initial = 0xA004 
SET :HEAP_POINTER = 0xA000
SET :HEAP_SIZE = 0x0400	//1024 bytes allows for 113 entries in the heap

//Heap block struct - 9 bytes
SET :heap_block_addr = 0x0000
SET :heap_block_size = 0x0002
SET :heap_block_lower = 0x0004
SET :heap_block_upper = 0x0006
SET :heap_block_free = 0x0008

FUNC :InitializeHeap > RETURN(:ret) > PARAM() > LOCAL()
	MOV :heap_bound_initial > IDX
	MOV IDX > MEM + :heap_bound_lower	//Initalize pointer to first entry in heap tree
	MOV IDX > MEM + :heap_bound_upper	//Initialize pointer to last entry in heap tree
	MOV :HEAP_POINTER > C
	MOV C > MIX + :heap_block_addr
	MOV :HEAP_SIZE > C
	MOV C > MIX + :heap_block_size	//Initialize first block as 1084 bytes, which is for the tree structure itself
	MOV NUL > C
	MOV C > MIX + :heap_block_lower
	MOV C > MIX + :heap_block_upper	//Initialize lower and upper branches as empty
	MOV 1 > A
	MOV A > MIX + :heap_block_free	//Intialize first block as occupied
RETURN 0



FUNC :malloc > RETURN(:ret) > PARAM(:block_size) > LOCAL(:heap_bound_pointer)

	//Search heap binary tree for an inactive block matching size
	MOV MEM + :heap_bound_lower > IDX

	DEFINE :search_bt_malloc
		MOV MSP + :block_size > C
		MOV MIX + :heap_block_size > D
		ADD16 C, D > NUL16
		JE :check_open_block
	//:search_bt_malloc

	DEFINE :compare_block_size_malloc
		ADD16 C,D > NUL16
		JLTE :next_lower_malloc
		GOTO :next_upper_malloc
	//:compare_block_size_malloc

	DEFINE :next_lower_malloc
		MOV :heap_block_lower > D
		ADD IDX,D > D
		MOV D > MSP + :heap_bound_pointer	//Save address to bound pointer to local var

		MOV MIX + :heap_block_lower > D
		MOV NUL > C
		ADD16 D,C > NUL16
		JE :new_block_malloc	//If nothing lower, then allocate new memory
		MOV D > IDX
		GOTO :search_bt_malloc	//Goto next node and keep searching
	//:next_lower_malloc


	DEFINE :next_upper_malloc
		MOV :heap_block_upper > D
		ADD IDX,D > D
		MOV D > MSP + :heap_bound_pointer	//Save address to bound pointer to local var

		MOV MIX + :heap_block_upper > D
		MOV NUL > C
		ADD16 D,C > NUL16
		JE :new_block_malloc	//If nothing upper, then allocate new memory
		MOV D > IDX
		GOTO :search_bt_malloc	//Goto next node and keep searching
	//:next_upper_malloc
		

	DEFINE :check_open_block
		MOV MIX + :heap_block_free > A
		OR A,0 > NUL
		JE :return_malloc
		GOTO :compare_block_size_malloc
	//:check_open_block


	DEFINE :new_block_malloc
		MOV MSP + :heap_bound_pointer > IDX
		MOV MEM + :heap_bound_upper > D
		ADD D,9 > C	//Increment by 9 bytes
		MOV C > MIX + 0	//Write next block address onto bound pointer
		MOV C > MEM + :heap_bound_upper

		//Fill out next entry in tree
		MOV D > IDX
		MOV MIX + :heap_block_addr > D
		MOV MIX + :heap_block_size > C
		ADD D,C > D
		
		MOV MEM + :heap_bound_upper > IDX
		MOV D > MIX + :heap_block_addr
		MOV MSP + :block_size > C
		MOV C > MIX + :heap_block_size
		MOV NUL > C
		MOV C > MIX + :heap_block_upper
		MOV C > MIX + :heap_block_lower
		GOTO :return_malloc
	//:new_block_malloc

	DEFINE :return_malloc
		MOV 1 > A
		MOV A > MIX + :heap_block_free	//Mark block as used
		MOV MIX + :heap_block_addr > D
		MOV D > MSP + :heap_bound_pointer
		RETURN :heap_bound_pointer
	//:return_malloc
//func :malloc


FUNC :free > RETURN(:ret) > PARAM(:heap_block_addr_free) > LOCAL(:lower_bound_free, :upper_bound_free)
	MOV MEM + :heap_bound_lower > D
	MOV D > MSP + :lower_bound_free

	MOV MEM + :heap_bound_upper > IDX
	MOV IDX > MSP + :upper_bound_free

	DEFINE :match_address_free	//IDX should be set to the entry we want to examine
		MOV MIX + :heap_block_addr > D
		MOV MSP + :heap_block_addr_free > C
		ADD16 D,C > NUL16
		JE :free_block_free
		JGT :next_upper_free
		GOTO :next_lower_free
	//:match_address_free
	
	DEFINE :next_upper_free
		MOV MSP + :lower_bound_free > C
		MOV MSP + :upper_bound_free > D
		SUB D,C > D
		DIV D,2 > D
		ADD C,D > IDX
		
		MOV IDX > MSP + :upper_bound_free
		MOV C > MSP + :lower_bound_free
	//:next_upper_free

	DEFINE :next_lower_free
	GOTO :next_lower_free
	
	DEFINE :free_block_free
		MOV NUL > A
		MOV A > MIX + :heap_block_free
		RETURN 1
	//:free_block_free

	DEFINE :return_free
		RETURN 1
	//:return_free
//func :free



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
	//:loop_breakpoint
	DEFINE :return_breakpoint
		RETURN
	//:return_breakpoint
//func :breakpoint



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
	//:loop_StringLength
	DEFINE :return_StringLength
		MOV D > MSP + :str_StringLength
		RETURN :str_StringLength
	//:return_StringLength
//func :StringLength

FUNC :ReverseString > RETURN(:ret) > PARAM(:str_ReverseString) > LOCAL()
	CALL :StringLength(:str_ReverseString)
	MOV MSP + :return > C
	SUB C,1 > C
	DEFINE :loop_ReverseString
		MOV MSP + :str_ReverseString > IDX
		MOV MIX + 0 > A
		ADD IDX,C > D
		MOV D > IDX
		MOV MIX + 0 > B
		MOV A > MIX + 0
		SUB IDX,C > D
		MOV D > IDX
		MOV B > MIX + 0
		ADD IDX,1 > IDX
		SUB C,2 > C
		ADD16 IDX,C > D
		ADD16 D,IDX > NUL
		JLTE :return_ReverseString
		GOTO :loop_ReverseString
	//:loop_ReverseString
	DEFINE :return_ReverseString
		RETURN :str_ReverseString
	//:return_ReverseString
//:func :ReverseString

FUNC :ToString > RETURN(:ret) > PARAM(:num_ToString, :result_ToString) > LOCAL()
	MOV MSP + :num_ToString > C
	MOV MSP + :result_ToString > IDX
	MOV 48 > B

	DEFINE :loop_ToString
		MOV 10 > D
		REM16 C,D > A
		ADD A,B > A
		MOV A > MIX + 0
		DIV16 C,D > IDX
		MOV NUL > D
		ADD16 IDX,D > NUL
		JE :return_ToString
		MOV IDX > C
		MOV MSP + :result_ToString > IDX
		ADD IDX,1 > IDX
		MOV IDX > MSP + :result_ToString
		GOTO :loop_ToString
	//:loop_ToString

	DEFINE :return_ToString
		MOV MSP + :result_ToString > IDX
		MOV 0 > A
		MOV A > MIX + 1
		CALL :ReverseString(:result_ToString)
		RETURN :result_ToString
	//:return_ToString
//func :ToString

FUNC :scanline > RETURN(:ret) > PARAM(:result_scanline) > LOCAL()
	MOV 10 > B
	MOV MSP + :result_scanline > IDX	//Initialize at start of destination string
	DEFINE :loop_scanline
		MOV MEM + :getchar > A
		OR A,0 > A
		JE :loop_scanline		//If char was null, then don't push onto string
		MOV A > MEM + :putchar
		AND A,B > NUL			//Compare with line feed
		JE :return_scanline
		MOV A > MIX + 0
		ADD IDX,1 > IDX
		GOTO :loop_scanline
	//:loop_scanline
	DEFINE :return_scanline
		MOV NUL > A
		MOV A > MIX + 0
		RETURN 0
	//:return_scanline
//func :scanline


SET :GPU_CONTROLLER = 0xFF40
SET :GPU_CMD = 0x0001
SET :GPU_FILL_CMD = 0x02b
SET :GPU_X_COORD = 0x0002
SET :GPU_Y_COORD = 0x0003
SET :GPU_X_VEC = 0x0004
SET :GPU_Y_VEC = 0x0005
SET :GPU_RED = 0x0006
SET :GPU_GREEN = 0x0007
SET :GPU_BLUE = 0x0008


FUNC :DrawRect > RETURN(:ret) > PARAM(:start_DrawRect, :end_DrawRect) > LOCAL()
	MOV :GPU_CONTROLLER > IDX
	MOV MSP + :start_DrawRect > C
	MOV C > MIX + :GPU_X_COORD

	MOV MSP + :end_DrawRect > C
	MOV C > MIX + :GPU_X_VEC

	MOV :GPU_FILL_CMD > A
	MOV A > MIX + :GPU_CMD
	RETURN
//func :DrawRect


FUNC :SetColor > RETURN(:ret) > PARAM(:color_SetColor) > LOCAL()
	MOV MSP + :color_SetColor > IDX
	MOV MIX + 0 > A
	MOV MIX + 1 > C
	MOV :GPU_CONTROLLER > IDX
	MOV A > MIX + :GPU_RED
	MOV C > MIX + :GPU_GREEN
	RETURN
//func :SetColor


DEFINE :default_color
RAW 0xDDFF22


DEFINE :main
	CALL :SetColor(&default_color)
	CALL :DrawRect(0x1010, 0x2020)

DEFINE :end
GOTO :end