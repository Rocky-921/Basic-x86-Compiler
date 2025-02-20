%{
   #include "get_x86_assembly.tab.h"
   #include <bits/stdc++.h>
   using namespace std;
   extern void yyerror(const char* c);
%}

%%
".retval"                       {return RETVAL;}
".global"                       {return GLOBAL;}
".local"                        {return LOCAL;}
".params_done"                  {return PARAMS_DONE;}
"=="|"!="|"<="|">="|"<"|">"     {yylval.str=strdup(yytext); return RELOP;}
"["                             {return *yytext;}
"]"                             {return *yytext;}
"("                             {return *yytext;}
")"                             {return *yytext;}
"{"                             {return *yytext;}
"}"                             {return *yytext;}
","                             {return *yytext;}
";"                             {return *yytext;}
"="                             {return *yytext;}
"goto"                          {return GOTO;}
"if"                            {return IF;}
"return"                        {return RET;}
".param"[0-9]+                  {yylval.str=strdup(yytext); return PARAM;}
".call"                         {return CALL;}
\'([^\']|\\\'|\\0|\\\\|\\n)\'   {yylval.str=strdup(yytext); return SOME_CHAR;}
\"([^\"]|\\\")*\"               {yylval.str=strdup(yytext); return TEXT;}
".L"[0-9]+                      {yylval.str=strdup(yytext); return GOTO_LABEL;}
".L"[0-9]+":"                   {yylval.str=strdup(yytext); return LABEL;}
[a-zA-Z_][a-zA-Z_0-9]*":"       {yylval.str=strdup(yytext); return F_ID;}
[a-zA-Z_][a-zA-Z_0-9]*          {yylval.str=strdup(yytext); return ID;}
".t"[0-9]+                      {yylval.str=strdup(yytext); return ID;}
[0-9]+                          {yylval.val=stoi(yytext); return NUM;}
[-+/*]                          {return *yytext;}
[\n]                            {yylineno++;}
[ \t\r\f]                       {}
.                               {yyerror(strdup("Unknown Character"));}
%%

int yywrap(void){
   return 1;
}