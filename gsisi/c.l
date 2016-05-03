%{
#include "Parserbase.h"
// this include is necessary because
// in class ParserBase (declared in ParserBase.h)
// there is the declaration of the tokens used
// in the return values below
%}

%option noyywrap yylineno

%{
#include <iostream>
using namespace std;
%}

DIGIT    [0-9]
ID       [a-zA-Z]([a-zA-Z0-9]|"_")*
STRING	"\"".*"\""
ASSIGN_OP	"="
INSERT_OP	"<<"|">>"
COMP_OP		("<"["="]?)|(">"["="]?)|"=="|"!="
BOOL_OP     "&&"|"||"
ADSUB_OP		"+"|"-"
INCDEC_OP		"++"|"--"
MULDIV_OP		 "%"|"/"
PREPROCESSOR_INCLUDE	"#include"[" "+]?(("<".+">")|("\"".+"\""))
COMMENT		("\/\/".*\n)|("\/\*"(.*[\n]?)*"\*\/")
FOR			"for"
WHILE		"while"
IF			"if"
ELSE		"else"
ELSE_IF		"else if"	
MAIN		"main"
DO          "do"
CHAR		"'"."'"



%%



{PREPROCESSOR_INCLUDE}	{ return ParserBase::PREPROCESSOR_INCLUDE; }
{MAIN}			{ return ParserBase::MAIN; }
"return"		{ return ParserBase::RETURN;}
"sizeof"		{ return ParserBase::SIZEOF;}
"case"			{ return ParserBase::CASE;}
"switch"		{ return ParserBase::SWITCH;}
"default"		{ return ParserBase::DEFAULT;}
"break"			{ return ParserBase::BREAK;}
"typedef"		{ return ParserBase::TYPEDEF;}
":"				{ return ParserBase::COLON;}
{DO}			{ return ParserBase::DO;}
{COMMENT}		
"struct"		{ return ParserBase::STRUCT; }
"*"			{ return ParserBase::PTR; }
{CHAR}			{ return ParserBase::CHAR; }
{FOR}			{ return ParserBase::FOR; }
{WHILE}			{ return ParserBase::WHILE; }
{IF}			{ return ParserBase::IF; }
{ELSE_IF}		{ return ParserBase::ELSE_IF; }
{ELSE}			{ return ParserBase::ELSE; }
{ID}			{ return ParserBase::ID; }
{DIGIT}+        { return ParserBase::UN_INT; }
{DIGIT}+"."{DIGIT}*     { return ParserBase::FLOAT; }
{INCDEC_OP}		{ return ParserBase::INCDEC_OP; }
{ASSIGN_OP}		{ return ParserBase::ASSIGN_OP; }
"&"				{ return ParserBase::BIT_AND; }
"^"				{ return ParserBase::BIT_XOR; }
"|"				{ return ParserBase::BIT_OR; }
"!"				{ return ParserBase::BIT_NOT; }
{BOOL_OP}		{ return ParserBase::BOOL_OP; }
{COMP_OP}		{ return ParserBase::COMP_OP; }
{INSERT_OP}		{ return ParserBase::INSERT_OP; }
{ADSUB_OP}		{ return ParserBase::ADSUB_OP; }
{MULDIV_OP}		{ return ParserBase::MULDIV_OP; }
","			{ return ParserBase::COMMA; }
";"			{ return ParserBase::EOL; }
"("             	{ return ParserBase::LBRACKET; }
")"             	{ return ParserBase::RBRACKET; }
"{"             	{ return ParserBase::LCURLY; }
"}"             	{ return ParserBase::RCURLY; }
"["             	{ return ParserBase::LSQUARE; }
"]"             	{ return ParserBase::RSQUARE; }
{STRING}		{ return ParserBase::STRING; }
" "		        
\n                     
\t			
