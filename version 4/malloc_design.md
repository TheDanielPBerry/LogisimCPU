Stack: 0x6000
Heap Structure: 0xA000
Heap Memory: 0xB000

malloc(32) -> 0xB000
	0xA000 | 0xA004	0xA004	//Pointer to first memory on list and pointer to last memory on list
	0xA004 | 0xB000 0x0020 0x0000 0x0000 0x01	//Pointer to memory block in heap, length of block, pointer to lower, pointer to higher


malloc(45) -> 0xB020
	0xA000 | 0xA004	0xA00D
	0xA004 | 0xB000 0x0020 0x0000 0xA00D 0x01
	0xA00D | 0xB020 0x002D 0x0000 0x0000 0x01



malloc(11) -> 0xB04D
	0xA000 | 0xA004	0xA016	
	0xA004 | 0xB000 0x0020 0xA016 0xA00D 0x01
	0xA00D | 0xB020 0x002D 0x0000 0x0000 0x01
	0xA016 | 0xB04D 0x000B 0x0000 0x0000 0x01

malloc(12) -> 0xB058
	0xA000 | 0xA004	0xA01F	
	0xA004 | 0xB000 0x0020 0xA01F 0xA00D 0x01
	0xA00D | 0xB020 0x002D 0x0000 0x0000 0x01
	0xA016 | 0xB04D 0x000B 0x0000 0x0000 0x01
	0xA01F | 0xB058 0x000C 0xA016 0x0000 0x01


malloc(20) -> B064
	0xA000 | 0xA004	0xA028	
	0xA004 | 0xB000 0x0020 0xA01F 0xA00D 0x01
	0xA00D | 0xB020 0x002D 0x0000 0x0000 0x01
	0xA016 | 0xB04D 0x000B 0x0000 0x0000 0x01
	0xA01F | 0xB058 0x000C 0xA016 0xA028 0x01
	0xA028 | 0xB064 0x0014 0x0000 0x0000 0x01

malloc(18) -> 
	0xA000 | 0xA004	0xA01F	
	0xA004 | 0xB000 0x0020 0xA01F 0xA00D 0x01
	0xA00D | 0xB020 0x002D 0x0000 0x0000 0x01
	0xA016 | 0xB04D 0x000B 0x0000 0x0000 0x01
	0xA01F | 0xB058 0x000C 0xA016 0xA028 0x01
	0xA028 | 0xB064 0x0014 0x0000 0x0000 0x01
	0xA031 | 0xB078 0x0012 0x0000 0x0000 0x01


malloc(18) -> 
	0xA000 | 0xA004	0xA01F	
	0xA004 | 0xB000 0x0020 0xA01F 0xA00D 0x01
	0xA00D | 0xB020 0x002D 0x0000 0x0000 0x01
	0xA016 | 0xB04D 0x000B 0x0000 0x0000 0x01
	0xA01F | 0xB058 0x000C 0xA016 0xA028 0x01
	0xA028 | 0xB064 0x0014 0x0000 0x0000 0x01
	0xA031 | 0xB078 0x0012 0x0000 0x0000 0x01


free(12) -> null

SET :heap_bound_lower = 0xA000
SET :heap_bound_upper = 0xA002
SET :heap_bound_initial = 0xA004 
SET :heap_pointer = 0xB000

//Heap block struct
SET :heap_block_addr = 0x0000
SET :heap_block_size = 0x0002
SET :heap_block_lower = 0x0004
SET :heap_block_upper = 0x0006
SET :heap_block_free = 0x0008


FUNC :InitializeHeap()
	MOV :heap_bound_initial > MEM + :heap_bound_lower
	MOV :heap_bound_initial > MEM + :heap_bound_upper
	MOV MEM + :heap_bound_lower > IDX
	MOV :heap_pointer > MIX + :heap_block_addr
	MOV 0 > C
	MOV C > MIX + :heap_block_size
RETURN 

*word malloc(word :block_size) > LOCAL(:heap_bound_pointer)
{
	//Search heap binary tree for an inactive block matching size
	MOV MEM + :heap_bound_lower > IDX

	DEFINE :search_bt_malloc
		MOV MSP + :block_size > C
		MOV MIX + :heap_block_size > D
		OR C,D > NUL
		JE :check_open_block
	//:search_bt_malloc

	DEFINE :compare_block_size_malloc
		OR C,D > NUL
		JLTE :next_lower_malloc
		GOTO :next_upper_malloc
	//:compare_block_size_malloc

	DEFINE :next_lower_malloc
		MOV :heap_block_lower > D
		ADD IDX,D > D
		MOV D > MSP + :heap_bound_pointer	//Save address to bound pointer to local var

		MOV MIX + :heap_block_lower > D
		OR D,0 > NUL
		JE :new_block_malloc	//If nothing lower, then allocate new memory
		MOV D > IDX
		GOTO :search_bt_malloc	//Goto next node and keep searching
	//:next_lower_malloc


	DEFINE :next_upper_malloc
		MOV :heap_block_upper > D
		ADD IDX,D > D
		MOV D > MSP + :heap_bound_pointer	//Save address to bound pointer to local var

		MOV MIX + :heap_block_upper > D
		OR D,0 > NUL
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
		MOV 0 > C
		MOV C > MIX + :heap_block_upper
		MOV C > MIX + :heap_block_lower
		GOTO :return_malloc
	//:new_block_malloc

	DEFINE :return_malloc
		MOV 1 > A
		MOV A > MIX + :heap_block_free	//Mark block as used
		MOV IDX > MSP + :heap_bound_pointer
		RETURN :heap_bound_pointer
	//:return_malloc
}
