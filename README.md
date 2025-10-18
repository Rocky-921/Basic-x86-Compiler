# 🧩 Basic x86 Compiler

A simple **C-to-x86 compiler** built using **Flex** and **Bison**.  
The compiler parses C source code, generates **Three Address Code (TAC)**, and then converts the TAC to **x86 assembly**.

---

## ⚙️ Overview

This project demonstrates the basic steps of a compiler:

1. **Lexical & Syntax Analysis** using Flex and Bison  
2. **Intermediate Code Generation (TAC)**  
3. **Assembly Code Generation (x86)**  

There are two compiler stages, each implemented using separate Flex-Bison files:

- **get_TAC/** → Converts input C code to TAC  
- **get_x86_assembly/** → Converts TAC to x86 assembly  

---

## 🏗️ Project Structure
```text
├── get_TAC/ # Flex and Bison files for TAC generation
├── get_x86_assembly/ # Flex and Bison files for x86 code generation
├── Makefile # Builds both compiler stages
├── run.sh # Automates the entire compilation process
└── examples/ # Example C files (optional)
```

---

## 🚀 Usage

### 1️⃣ Build the compiler
```bash
make
```

This will create two executables:

**get_TAC** — generates the TAC

**my_compiler** — generates x86 assembly from TAC

### 2️⃣ Generate TAC from C code
```bash
./get_TAC < input.c > temp_intermediate_TAC.txt
```

### 3️⃣ Generate x86 Assembly from TAC
```bash
./my_compiler < temp_intermediate_TAC.txt > out.s
```

### 4️⃣ Compile and Run the Assembly
```bash
gcc -m32 -no-pie out.s -o output
./output
```

### ⚡ One-Command Automation

All the above steps are automated with:
```bash
./run.sh input.c
```

## 🧰 Prerequisites

Make sure the following are installed:
```bash
sudo apt install binutils gcc-multilib
```

### 🧪 Example
```bash
# Example C file: input.c
int main() {
    int a = 3, b = 5;
    int c = a + b;
    return c;
}

# Run
./run.sh input.c

# Output: x86 assembly in out.s
# Executable binary: output
```

## 👨‍💻 Author

Prince Garg
