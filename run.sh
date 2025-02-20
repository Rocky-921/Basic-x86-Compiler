#!/bin/bash

# Run the make command to compile the files
make
if [ $? -ne 0 ]; then
    echo "Compilation failed."
    exit 1
fi

# Check if the correct number of arguments is provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <input_file>"
    exit 1
fi

# Assign the input file to a variable
input_file=$1

# Execute ./tac with the input file and redirect output to temp.txt
./get_TAC < "$input_file" > temp_intermediate_TAC.txt

# Execute ./a.out with temp.txt as input and redirect output to out.s
./my_compiler < temp_intermediate_TAC.txt > out.s

gcc -m32 -no-pie out.s -o output

./output