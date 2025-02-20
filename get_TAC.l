%{
   #include "get_TAC.tab.h"
   #include <bits/stdc++.h>
   using namespace std;
   extern void yyerror(const char* c);
   extern int l_count;
%}

%%

"//".*\n                         ;
"/*"([^*]|\*+[^*/])*\*+"/"       ;
\#include[ ]*\<stdio.h\>         {return START;}
int                              {return INT;}
char                             {return CHAR;}
"["                              {return *yytext;}
"]"                              {return *yytext;}
"("                              {return *yytext;}
")"                              {return *yytext;}
"{"                              {return *yytext;}
"}"                              {return *yytext;}
","                              {return *yytext;}
";"                              {return *yytext;}
"="                              {return *yytext;}
if                               {yylval.val=l_count++; return IF;}
else                             {return ELSE;}
for                              {yylval.val=l_count++; return FOR;}
while                            {yylval.val=l_count++; return WHILE;}
return                           {return RET;}
[a-zA-Z_][a-zA-Z0-9_]*           {yylval.str=strdup(yytext); return VAR;}
\'([^\']|\\\'|\\0|\\\\|\\n)\'    {yylval.str=strdup(yytext); return SOME_CHAR;}
\"([^\"]|\\\")*\"                {yylval.str=strdup(yytext); return TEXT;}
[0-9]+                           {yylval.val=stoi(yytext); return CONST;}
"=="|"!="|"<="|">="|"<"|">"      {yylval.str=strdup(yytext); return COMP;}
"**"                             {return PWR;}
"!"                              {return NOT;}
"||"                             {return OR;}
"&&"                             {return AND;}
"-"                              {return *yytext;}
"+"                              {return *yytext;}
[*/]                             {yylval.c=*yytext; return MD;}
[\n]                             {yylineno++;}
[ \t\r\f]                        {}
.                                {yyerror(strdup("Unknown Character"));}
%%

int yywrap(void){
   return 1;
}