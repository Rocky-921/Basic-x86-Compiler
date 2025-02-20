# Basic-x86-Compiler
Basic x86 Compiler using flex and bison

I have created 2 sets of flex and bison files:=
1) get_TAC :- Used to create the TAC (Three Address Code) from the given input file.
2) get_x86_assembly :- Used to create the x86 assembly from the generated TAC.

Makefile Compiles both the flex-bison files and gives get_TAC and my_compiler executables.

To generate the x86 assembly code for any input.c file we have to follow these steps:-
1) Compiler Everything :- Use make command
2) Generate TAC file :- ./get_TAC < input.c > temp_intermediate_TAC.txt
3) Generate Assembly code from the TAC :- ./my_compiler < temp_intermediate_TAC.txt > out.s

Now we can compile the assembly code generated using:-
gcc -m32 -no-pie out.s -o output
and run using ./output

All this has been automated in run.sh script
use :- ./run.sh input.c

prereqs:-
sudo apt install binutils gcc-multilib
