%{
    #include <bits/stdc++.h>
    #include <stdlib.h>
    #include <stdio.h>
    #include <string.h>
    using namespace std;
    void yyerror(const char* c);
    int yylex(void);
    extern char* yytext;
    extern int yylineno;
    int t_count = 1,param_count=1,l_count=1;
    multimap<string,int> vars;   // 1-> local, 2-> .retval, 0-> not defined
    int location=2;         // 1-> local, 2-> .retval
    vector<string> args,params;
    string exp_buff;

    char* create_t(){
        string s=".t"+to_string(t_count);
        t_count++;
        return strdup(s.c_str());
    }

    class cond{
        public:
        string comp,sep;
        cond *left, *right;
        string decl;
        // to calculate
        int tstate,fstate;

        cond(string c,string d){
            comp=c;
            decl=d;
            sep.clear();
            left=NULL;
            right=NULL;
            tstate=-1;
            fstate=-1;
        }
        cond(cond *l, string s, cond *r){
            comp.clear();
            sep=s;
            left=l;
            right=r;
            tstate=-1;
            fstate=-1;
        }

        void set_state(int t,int f){
            tstate=t;
            fstate=f;
            if(sep.empty()){
                return;
            }
            if(sep=="!"){
                left->set_state(f,t);
                return;
            }
            if(sep=="||"){
                left->set_state(t,l_count++);
                right->set_state(t,f);
                return;
            }
            if(sep=="&&"){
                left->set_state(l_count++,f);
                right->set_state(t,f);
                return;
            }
            cout << "GADBAD\n";
            return;
        }

        string get_code(){
            if(sep.empty()){
                /*
                ti = comp
                if (ti) goto true
                goto false
                */
                string code=decl + ".t" + to_string(t_count) + " = " + comp + "\n"
                    + "if (.t" + to_string(t_count) + ") goto .L" + to_string(tstate) + "\n"
                    + "goto .L" + to_string(fstate) + "\n";
                t_count++;
                decl.clear();
                return code;
            }
            if(sep=="!"){
                string code=left->get_code();
                delete(left);
                return code;
            }
            if(sep=="||"){
                string code=left->get_code()
                    + ".L" + to_string(left->fstate) + ":\n"
                    + right->get_code();
                delete(left);
                delete(right);
                return code;
            }
            if(sep=="&&"){
                string code=left->get_code()
                    + ".L" + to_string(left->tstate) + ":\n"
                    + right->get_code();
                delete(left);
                delete(right);
                return code;
            }
            return "GADBAD\n";
        }
    };
%}

%token INT ELSE CHAR PWR RET OR NOT AND START

%union{
    char* str;
    int val;
    int arr[2];
    char c;
    void* cond_ptr;
}

%token<str> VAR TEXT COMP SOME_CHAR
%token<val> CONST IF WHILE FOR
%token<c> MD

%type<str> access_var exp unary_exp
%type<val> arguments some_arguments parameters some_parameters
%type<arr> base_line
%type<cond_ptr> condition one_cond not_cond
%type<cond_ptr> poss_lines_1

%left OR
%left AND
%right NOT
%left '+' '-'
%left MD
%right PWR

%%

start: START program;

program: 
        | function program 
        | declaration ';' program
        | decl_assign ';' program;

function: datatype VAR '(' parameters ')' '{'{
    cout << $2 << ":\n";
    exp_buff.clear();
    location=1;
    param_count=1;
    for(int i=params.size()-$4;i<params.size();i++){
        vars.insert({params[i],1});
        cout << params[i] << " = " << ".param" << param_count++ << "\n";
    }
    cout << ".params_done\n";
    params.resize(params.size()-$4);
    param_count=1;
    } body '}'{
    location=2;
    map<string,int>::iterator itr=vars.begin();
    while(itr!=vars.end()){
        if(itr->second==1){
            vars.erase(itr++);
        }else itr++;
    }
    cout << "\n";
};

datatype: INT | CHAR;

parameters: 
        {$$=0;}| some_parameters{$$=$1;};
    
some_parameters:  parameter{$$=1;}
                | parameter ',' some_parameters{$$=1+$3;};

parameter: datatype VAR{
            params.push_back(string($2));
        } | datatype VAR '[' optional_exp ']'{
            params.push_back(string($2));
};

optional_exp: | exp;

arguments:
        {$$=0;}| some_arguments{$$=$1;};

some_arguments:   one_arg{$$=1;}
                | one_arg ',' some_arguments{$$=1+$3;};

one_arg: exp{
            exp_buff+=".t" + to_string(t_count) + " = " + string($1) + "\n";
            string s=".t";
            s+=to_string(t_count);
            t_count++;
            args.push_back(s);
        } | TEXT{
            exp_buff+=".t" + to_string(t_count) + " = " + string($1) + "\n";
            string s=".t";
            s+=to_string(t_count);
            t_count++;
            args.push_back(s);
};

exp:  exp '+' exp{
        exp_buff+=".t" + to_string(t_count) + " = " + string($1) + " + " + string($3) + "\n";
        free($1);
        free($3);
        $$=create_t();
    } | exp '-' exp{
        exp_buff+=".t" + to_string(t_count) + " = " + string($1) + " - " + string($3) + "\n";
        free($1);
        free($3);
        $$=create_t();
    } | exp MD exp{
        exp_buff+=".t" + to_string(t_count) + " = " + string($1) + " " + $2 + " " + string($3) + "\n";
        free($1);
        free($3);
        $$=create_t();
    } | exp PWR exp{
        exp_buff+=".t" + to_string(t_count) + " = " + string($1) + " ** " + string($3) + "\n";
        free($1);
        free($3);
        $$=create_t();
    } | unary_exp{$$=$1;}
      | '+' unary_exp{
        $$=$2;
    } | '-' unary_exp{
        exp_buff+=".t" + to_string(t_count) + " = " + "-" + string($2) + "\n";
        free($2);
        $$=create_t();
    };

unary_exp:   CONST{
                exp_buff+=".t" + to_string(t_count) + " = " + to_string($1) + "\n";
                $$=create_t();
            } | SOME_CHAR{
                exp_buff+=".t" + to_string(t_count) + " = " + string($1) + "\n";
                free($1);
                $$=create_t();
            } | access_var{
                exp_buff+=".t" + to_string(t_count) + " = " + string($1) + "\n";
                free($1);
                $$=create_t();
            } | VAR '(' arguments ')'{
                for(int i=args.size()-$3;i<args.size();i++){
                    exp_buff+=".param" + to_string(param_count) + " = " + args[i] + "\n";
                    param_count++;
                }
                exp_buff+=".call " + string($1) + "\n";
                free($1);
                args.resize(args.size()-$3);
                param_count=1;
                $$=create_t();
                exp_buff+=string($$) + " = .retval\n";
            } | '(' exp ')'{$$=$2;};

access_var: VAR{
            if(vars.find($1)==vars.end()){
                string s="undefined variable " + string($1);
                yyerror(s.c_str());
            }
            $$=$1;
        } | VAR '[' exp ']'{
            if(vars.find($1)==vars.end()){
                string s="undefined variable " + string($1);
                yyerror(s.c_str());
            }
            string s=string($1) + "[" + string($3) + "]";
            $$=strdup(s.c_str());
};

condition: one_cond{
            $$=$1;
         }| condition OR condition{
            $$=new cond((cond *)$1,"||",(cond *)$3);
         }| condition AND condition{
            $$=new cond((cond *)$1,"&&",(cond *)$3);
};

one_cond: exp COMP exp{
            $$=new cond(string($1)+string($2)+string($3),exp_buff);
            exp_buff.clear();
        }| not_cond{
            $$=$1;
};

not_cond: '(' condition ')'{
            $$=$2;
          }| NOT not_cond{
            $$=new cond((cond *)$2,"!",NULL);
};

body: 
    | line body
    | '{' body '}' body;

line: exp ';'{cout << exp_buff; exp_buff.clear();}
    | declaration ';'
    | decl_assign ';'
    | assignment ';'{cout << exp_buff; exp_buff.clear();}
    | if_statement
    | for_loop
    | while_loop
    | RET exp ';'{cout << exp_buff; exp_buff.clear(); cout << ".retval = " << $2 << "\n"; cout << "return\n";}
    | RET condition ';'{
        cond* ptr=((cond*)$2);
        int t_state=l_count++,f_state=l_count++;
        ptr->set_state(t_state,f_state);
        cout << ptr->get_code();
        cout << ".L" << t_state << ":\n";
        char *t= create_t();
        cout << t << " = 1\n";
        cout << ".retval = " << t << "\n";
        string fnl = ".L"+to_string(l_count++);
        cout << "goto " << fnl << "\n";
        cout << ".L" << f_state << ":\n";
        t= create_t();
        cout << t << " = 0\n";
        cout << ".retval = " << t << "\n";
        cout << fnl << ":\nreturn\n";
};
    
poss_lines_1: 
            {$$= new string(exp_buff); exp_buff.clear();}| assignment{$$= new string(exp_buff); exp_buff.clear();};

one_or_more_lines: line | '{' body '}';

if_statement: base_line {
                cout << ".L" << $1[0] << ":\n";
            }| base_line ELSE{
                l_count++;
                cout << "goto .L" << $1[1] << "\n";
                cout << ".L" << $1[0] << ":\n";
} one_or_more_lines{
                cout << ".L" << $1[1] << ":\n";
};

base_line: IF '(' condition ')'{
    l_count++;
    ((cond*)$3)->set_state($1,$1+1);
    cout << ((cond*)$3)->get_code();
    delete((cond*)$3);
    cout << ".L" << $1 << ":\n";
} one_or_more_lines{
    $$[0]=$1+1;
    $$[1]=l_count;
};

for_loop: FOR '(' poss_lines_1 ';' condition ';' poss_lines_1 ')'{
    cout << (*((string*)$3));
    delete((string*)$3);
    cout << ".L" << $1 << ":\n";
    l_count+=2;
    ((cond*)$5)->set_state($1+1,$1+2);
    cout << ((cond*)$5)->get_code();
    cout << ".L" << $1+1 << ":\n";
    delete((cond*)$5);
} one_or_more_lines{
    cout << (*((string*)$7));
    delete((string*)$7);
    cout << "goto .L" << $1 << "\n";
    cout << ".L" << $1+2 << ":\n";
};

while_loop: WHILE '(' condition ')'{
    l_count+=2;
    ((cond*)$3)->set_state($1+1,$1+2);
    cout << ".L" << $1 << ":\n";
    cout << ((cond*)$3)->get_code();
    delete((cond*)$3);
    cout << ".L" << $1+1 << ":\n";
}one_or_more_lines{
    cout << "goto .L" << $1 << "\n";
    cout << ".L" << $1+2 << ":\n";
};

declaration: simple_declaration
            | declaration ',' make_var;

simple_declaration: datatype make_var;

make_var: VAR{
        if(location==2) cout << ".global " << $1 << "\n";
        vars.insert({string($1),location});
    }| VAR '[' exp ']'{
        cout << exp_buff;
        exp_buff.clear();
        if(location==2) cout << ".global " << $1 << "[" << $3 << "]\n";
        else cout << ".local " << $1 << "[" << $3 << "]\n";
        vars.insert({string($1),location});
};

assignment: access_var '=' exp{
    exp_buff+=string($1) + " = " + string($3) + "\n";
};

decl_assign: datatype VAR '=' exp{
    cout << exp_buff;
    exp_buff.clear();
    if(location==2) cout << ".global " << $2 << "\n";
    vars.insert({string($2),location});
    cout << $2 << " = " << $4 << "\n";
};

%%

void yyerror(const char *c){
    cout << c << " " << yylineno << " " << yytext << "\n";
    exit(1);
}

int main(void){
    yyparse();
    return 0;
}