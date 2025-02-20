all: my_compiler get_TAC

my_compiler: get_x86_assembly.tab.c get_x86_assembly.yy.c
	g++ -O3 get_x86_assembly.yy.c get_x86_assembly.tab.c -o my_compiler

get_x86_assembly.tab.c: get_x86_assembly.y
	bison -d get_x86_assembly.y -o get_x86_assembly.tab.c

get_x86_assembly.yy.c: get_x86_assembly.l get_x86_assembly.tab.h
	flex -o get_x86_assembly.yy.c get_x86_assembly.l


get_TAC: get_TAC.tab.c get_TAC.yy.c
	g++ -O3 get_TAC.yy.c get_TAC.tab.c -o get_TAC

get_TAC.tab.c: get_TAC.y
	bison -d get_TAC.y -o get_TAC.tab.c

get_TAC.yy.c: get_TAC.l get_TAC.tab.h
	flex -o get_TAC.yy.c get_TAC.l


clean:
	@rm -f get_x86_assembly.yy.c get_TAC.tab.h get_TAC.tab.c get_TAC
	@rm -f get_TAC.yy.c get_x86_assembly.tab.h get_x86_assembly.tab.c my_compiler
	@rm -f temp_intermediate_TAC.txt out.s output