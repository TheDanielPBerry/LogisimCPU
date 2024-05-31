//CPU based constants
SET :je = 0x01b
SET :jne = 0x08b
SET :return = 0x0002

//Pointers
SET :STACK_POINTER = 0x6000

//Device Addresses
SET :putchar = 0xFF01	//Device id in memory for the character write
SET :getchar = 0xFF02	//Device id in memory to read from the keyboard
SET :bell = 0xFF80		//Device id in memory for the bell



MOV :STACK_POINTER > SP		//Initialize stack pointer
GOTO :main

DEFINE :newString
RAW 0x0000


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
		OR D,0 > NUL16
		JE :new_block_malloc	//If nothing lower, then allocate new memory
		MOV D > IDX
		GOTO :search_bt_malloc	//Goto next node and keep searching
	//:next_lower_malloc


	DEFINE :next_upper_malloc
		MOV :heap_block_upper > D
		ADD IDX,D > D
		MOV D > MSP + :heap_bound_pointer	//Save address to bound pointer to local var

		MOV MIX + :heap_block_upper > D
		OR D,0 > NUL16
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
		OR D,C > NUL16
		JE :free_block_free
		JGT :next_upper_free
		JLT :next_lower_free
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

	
	DEFINE :free_block_free
		MOV NUL > A
		MOV A > MIX + :heap_block_free
		RETURN 1
	//:free_block_free

	DEFINE :return_free
		RETURN 1
	//:return_free
//func :free


DEFINE :main

CALL :InitializeHeap()

CALL :malloc(25)
MOV MSP + :return > IDX
MOV IDX > MEM + :newString

MOV 0x41 > A
MOV A > MIX + 0
MOV 0x42 > A
MOV A > MIX + 1
MOV 0x43 > A
MOV A > MIX + 2
MOV NUL > A
MOV A > MIX + 4



DEFINE :end
GOTO :end