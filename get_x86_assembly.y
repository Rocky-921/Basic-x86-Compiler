%{
    #include <bits/stdc++.h>
    #include <stdlib.h>
    #include <stdio.h>
    #include <string.h>
    #include <string>
    using namespace std;
    void yyerror(const char* c);
    int yylex(void);
    extern char* yytext;
    extern int yylineno;
    string text,prologue,code,epilogue,datas,bss;
    int sp=8;
    map<string,int> pos_stack;
    set<string> bss_vars,bss_arrs;

    string get_pos(string a){   // giving address of a
        string a_pos;
        if(bss_vars.find(a)!=bss_vars.end()){
            a_pos = a;
        }else if(pos_stack.find(a)!=pos_stack.end()){
            a_pos = to_string(pos_stack[a]) + "(%ebp)";

        }else{
            sp -= 4;
            a_pos = to_string(sp) + "(%ebp)";
            pos_stack[a] = sp;
        }
        return a_pos;
    }

    vector<string> args;
    int msg_count=1;
%}

%token RETVAL GLOBAL GOTO IF RET CALL LOCAL PARAMS_DONE

%union{
    char *str;
    int val;
}

%token<str> RELOP PARAM TEXT LABEL F_ID ID SOME_CHAR GOTO_LABEL
%token<val> NUM

%%
program: globaldecls functions;

globaldecls: globaldecl globaldecls | ;

globaldecl: GLOBAL ID{
                string s=string($2);
                bss+= s + ":\t.space 4\n";
                bss_vars.insert(s);
            }| ID '=' NUM GLOBAL ID '[' ID ']'{
                string s=string($5);
                bss+= string($5) + ":\t.space " + to_string($3) + "\n";
                bss_vars.insert(s);
                bss_arrs.insert(s);
};

functions: function functions | ;

function: F_ID{
    string s = string($1);
    s.pop_back();
    prologue += "\t.globl " + s + "\n"
                + s + ":\n"
                +   "\tpushl\t%ebp\n"
                +   "\tmovl\t%esp, %ebp\n";
} params PARAMS_DONE{
    sp = 0;
} lines RET{
    prologue += "\tsub $" + to_string(-sp) + ", %esp\n#Prologue\n";
    epilogue += "#Epilogue\n\tmovl\t%ebp, %esp\n\tpopl\t%ebp\n\tret\n";
    text += prologue;
    for(auto it:pos_stack){
        text += "# " + it.first + " -> " + to_string(it.second) + "\n";
    }
    text += code + epilogue;
    prologue = code = epilogue = "";
    sp = 8;
    pos_stack.clear();
};

params: params param | ;

param: ID '=' PARAM{
    pos_stack[string($1)]=sp;
    sp+=4;
};

lines: line lines | ;

line:   assignmt
        | func_call
        | if_state
        | GOTO GOTO_LABEL{
            code += "\tjmp\t" + string($2) + "\n";
        }| LABEL{
            code += string($1) + "\n";
};

// data, bss, stack

assignmt: ID '=' ID{
            string a=string($1),b=string($3);
            // a -> bss, stack
            string a_pos = get_pos(a),b_pos = get_pos(b);
            if(bss_arrs.find(b)!=bss_arrs.end()){
                code += "\tleal\t";
            }else{
                code += "\tmovl\t";
            }
            code += b_pos + ", %eax\n"
                    + "\tmovl\t%eax, " + a_pos + "\t\t\t\t# " + a + " = " + b + "\n";
        }| ID '=' NUM{
            string a = string($1);
            string a_pos=get_pos(a);
            code += "\tmovl\t$" + to_string($3) + ", " + a_pos + "\t\t\t\t# " + a + " = " + to_string($3) + "\n";
        }| ID '=' exp{
            string a = string($1);
            string a_pos=get_pos(a);
            code += "\tmovl\t%eax, " + a_pos + "\t\t\t\t# " + a + " = exp\n";
        }| ID '=' TEXT{
            string a = string($1),b=string($3);
            string msg = ".msg" + to_string(msg_count++);
            datas += msg + ":\t.asciz " + b + "\n";
            code += "\tleal\t" + msg + ", %eax\n"
                    + "\tmovl\t%eax, " + get_pos(a) + "\t\t\t\t# " + a + " = " + b + "\n";
        }| ID '=' SOME_CHAR {
            string a = string($1),b = string($3);
            if(b=="\'\\0\'") b="0";
            string a_pos;
            sp -= 1;
            a_pos = to_string(sp) + "(%ebp)";
            pos_stack[a] = sp;
            code += "\tmovb\t$" + b + ", " + a_pos + "\t\t\t\t# " + a + " = " + b + "\n";
        }| ID '[' ID ']' '=' ID{
            string a = string($1),b = string($3), c = string($6);
            string a_pos = get_pos(a),b_pos = get_pos(b),c_pos = get_pos(c);
            code += "\tmovl\t" + a_pos + ", %eax\n";
            if(bss_arrs.find(a)!=bss_arrs.end()){
                code += "\tleal\t";
            }else{
                code += "\tmovl\t";
            }
            code +=  a_pos + ", %eax\n" + "\taddl\t" + b_pos + ", %eax\n"
                    + "\tmovb\t" + c_pos + ", %bl\n"
                    + "\tmovb\t%bl, 0(%eax)\t\t\t\t# " + a + "[" + b + "] = " + c + "\n";
        }| ID '=' ID '[' ID ']' { 
            string a = string($1),b=string($3),c=string($5);
            string a_pos,b_pos=get_pos(b),c_pos=get_pos(c);
            sp -= 1;
            a_pos = to_string(sp) + "(%ebp)";
            pos_stack[a] = sp;
            if(bss_arrs.find(b)!=bss_arrs.end()){
                code += "\tleal\t";
            }else{
                code += "\tmovl\t";
            }
            code +=  b_pos + ", %eax\n"
                    + "\taddl\t" + c_pos + ", %eax\n"
                    + "\tmovb\t0(%eax), %bl\n"
                    + "\tmovb\t%bl, " + a_pos + "\t\t\t\t# " + a + " = " + c + "[" + b + "]\n";
        }| ID '=' RETVAL{
            string a = string($1);
            string a_pos=get_pos(a);
            code += "\tmovl\t%eax, " + a_pos + "\t\t\t\t# " + a + " = retval\n";
        }| ID '=' NUM LOCAL ID '[' ID ']'{
            sp-=$3;
            string s = string($5);
            code += "\tleal\t" + to_string(sp) + "(%ebp), %eax\n";
            sp-=4;
            code += "\tmovl\t%eax, " + to_string(sp) + "(%ebp)\n";
            pos_stack[s] = sp;
                    
        }| RETVAL '=' ID{
            string b = string($3);
            string b_pos = get_pos(b);
            code += "\tmovl\t" + b_pos + ", %eax\t\t\t\t# retval = " + b + "\n";
};

exp: ID '+' ID{
        string a = string($1),b=string($3);
        string a_pos = get_pos(a),b_pos = get_pos(b);
        code += "\tmovl\t" + a_pos + ", %eax\n"
                + "\taddl\t" + b_pos + ", %eax\t\t\t\t# " + a + " + " + b + "\n";
    }| ID '-' ID{
        string a = string($1),b=string($3);
        string a_pos = get_pos(a),b_pos = get_pos(b);
        code += "\tmovl\t" + a_pos + ", %eax\n"
                + "\tsubl\t" + b_pos + ", %eax\t\t\t\t# " + a + " - " + b + "\n";
    }| ID '*' ID{
        string a = string($1),b=string($3);
        string a_pos = get_pos(a),b_pos = get_pos(b);
        code += "\tmovl\t" + a_pos + ", %eax\n"
                + "\timull\t" + b_pos + ", %eax\t\t\t\t# " + a + " * " + b + "\n";
    }| ID '/' ID{
        string a = string($1),b=string($3);
        string a_pos = get_pos(a),b_pos = get_pos(b);
        code += "\tsubl\t%edx, %edx\n\tmovl\t" + a_pos + ", %eax\n\tcdq\n"
                + "\tidivl\t" + b_pos + "\t\t\t\t# " + a + " / " + b + "\n";
    } | '-' ID{
        string a = string($2);
        string a_pos = get_pos(a);
        code += "\tmovl\t" + a_pos + ", %eax\n"
                + "\timull\t$-1, %eax\t\t\t\t# -" + a + "\n";
};

func_call: arg_pass CALL ID{
    for(int i=args.size()-1;i>=0;i--){
        code += args[i];
    }
    code += "\tcall\t" + string($3) + "\n"
            + "\taddl\t$" + to_string(args.size()*4) + ", %esp\n";
    args.clear();
};

arg_pass: one_arg_pass arg_pass | ;

one_arg_pass: PARAM '=' ID{
    string b = string($3);
    string b_pos = get_pos(b);
    args.push_back("\tpushl\t" + b_pos + "\n");
};

if_state: ID '=' ID RELOP ID IF '(' ID ')' GOTO GOTO_LABEL{
    // t1 = t2<t3 if (t1) goto L1
    string a = string($3),relop=string($4),b=string($5);
    code += "\tmovl\t" + get_pos(a) + ", %eax\n"
            + "\tcmpl\t" + get_pos(b) + ", %eax\n";
    string label = string($11);
    if(relop=="<"){
        code += "\tjl\t" + label + "\n";
    }else if(relop==">"){
        code += "\tjg\t" + label + "\n";
    }else if(relop=="<="){
        code += "\tjle\t" + label + "\n";
    }else if(relop==">="){
        code += "\tjge\t" + label + "\n";
    }else if(relop=="=="){
        code += "\tje\t" + label + "\n";
    }else if(relop=="!="){
        code += "\tjne\t" + label + "\n";
    }
}


%%

void yyerror(const char *c){
    cout << c << " " << yylineno << " " << yytext << "\n";
    exit(1);
}

int main(void){
    datas+="\t.data\n";
    bss+="\t.bss\n";
    text+="\t.text\n";
    yyparse();
    cout << datas << bss << text;
    return 0;
}