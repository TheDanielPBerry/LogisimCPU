# LogisimCPU
### Version 4
The latest version 4 of this project is available in the version 4 directory.  
This latest version includes a simple shell with access to different programs such as pong or a painting program.  
This new cpu has much more capability to work with pointers as well as do function calls on the stack.  
The stdlib.asm program has examples of iterating through strings based on pointers passed on the stack, indexed based addressing, device management and much more.  
There is also a simple implementation of malloc in the code to allocate new memory on the stack.  
I've made a video with instructions on how to start it using the included JS assembler:  
  
[![IMAGE ALT TEXT](http://img.youtube.com/vi/viT7sIJhgzI/0.jpg)](http://www.youtube.com/watch?v=viT7sIJhgzI "Logisim Computer v4 - Instructions")





### Instructions for original:
A CPU I made in logisim with a graphics output and tty interface. It comes with the machine code for pong. Also an assembler written in Java with the assembly code for pong.

How to operate and load Pong Code:
1) Open in Logisim: roget_v3.circ
2) At the bottom right is a ROM Module. Right Click and "Load Image." 
3) Open the "ComputerCode" file from the repo.
4) Enable the clock at your desired speed.
4) Click once the button next to rom module. It will burn loaded rom into loaded memory of the cpu.
5) Once Ram starts writing only zeros the program is done.
6) Click power on once.
7) Teletype will read info.
8) Next to power button use keyboard input to control game. Just give it focus and it will accept your keyboard inputs.
9) A to move left. D to move right. The ball will bounce around screen at a slow speed.
10) Thanks for using and enjoy
