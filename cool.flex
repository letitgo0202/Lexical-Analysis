/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;
static int line_num = 1;
static int deepth = 0;

static int null_char_present;
static std::string current_string;

/*
 *  Add Your own definitions here
 */

%}

/*
 * Define names for regular expressions here.
 */

DARROW          =>
ASSIGN          <-
LE              <=
CLASS		(?i:class)
INHERITS	(?i:inherits)
IF 		(?i:if)
THEN		(?i:then)
ELSE		(?i:else)
FI		(?i:fi)
WHILE		(?i:while)
LOOP		(?i:loop)
POOL		(?i:pool)
LET		(?i:let)
IN		(?i:in)
FALSE		(?i:false)
TRUE		(?i:true)
ISVOID		(?i:isvoid)
CASE		(?i:case)
ESAC		(?i:esac)
NEW		(?i:new)
OF 		(?i:of)
NOT		(?i:not)
ESCAPE 		\\
NEWLINE		\n
NULL_CHAR	\0
QUOTE      	\"

%x	 COMMENT STRING

%%

 /*
  *  Nested comments
  */


 /*
  *  The multiple-character operators.
  */
{DARROW}		{ return (DARROW); }
{ASSIGN}		{ return (ASSIGN); }
{LE}			{ return (LE);     }
{CLASS}			{ return (CLASS);  }
{INHERITS}		{ return (INHERITS);}
{IF}			{ return (IF);     }
{THEN}			{ return (THEN);   }
{ELSE}			{ return (ELSE);   }
{FI}			{ return (FI);     }
{WHILE}			{ return (WHILE);  }
{LOOP}			{ return (LOOP);   }
{POOL}			{ return (POOL);   }
{LET}			{ return (LET);    }
{IN}			{ return (IN);     }
{FALSE}  		{  
             	 cool_yylval.boolean = false;
	     	 return BOOL_CONST;				
 }
{TRUE}			{   
		cool_yylval.boolean = true;
		return BOOL_CONST;
 }
{ISVOID}		{ return (ISVOID); }
{CASE}			{ return (CASE);   }
{ESAC}			{ return (ESAC);   }
{NEW}			{ return (NEW);    }
{OF}			{ return (OF);     }
{NOT}			{ return (NOT);    }

[0-9]+			{
		cool_yylval.symbol = inttable.add_string(yytext);
		return INT_CONST;
}
[A-Z][A-Za-z0-9_]*	{
		cool_yylval.symbol = idtable.add_string(yytext);
		return TYPEID;
}
[a-z][a-zA-Z0-9_]*	{
		cool_yylval.symbol = idtable.add_string(yytext);
		return OBJECTID;
}

[\.@~]			{
		return yytext[0];
}
[\+\-\*\/\=\<]		{ return yytext[0];  }

[\;\,\:\{\}\(\)]	{ return yytext[0];  }





 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */


 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */
\n		{ line_num++; curr_lineno = line_num;  }

[ \t\r\f\v]	/*  -----skip------*/


--.*            /* ----skip-----*/
"(*"            { deepth = 1; BEGIN(COMMENT);  }
<COMMENT><<EOF>> 	{
		cool_yylval.error_msg = "EOF IN COMMENT";
		BEGIN(INITIAL);
		return ERROR;
}
<COMMENT>"(*"  { deepth++;}
<COMMENT>"*)"	{
			deepth--;
			if(deepth==0)
				BEGIN(INITIAL);
}
<COMMENT>\\.
<COMMENT>\n     {
                  line_num++;
}
<COMMENT>"*"[^\)\*\n]	/*  eat-anything   */
<COMMENT>.  		/*  eat-anything   */
\*\)            {
		cool_yylval.error_msg = "Unmatched *)";
		return ERROR;
}


{QUOTE}		{
			BEGIN(STRING);
			current_string="";
			null_char_present=0;
}
<STRING>{QUOTE}	{
			BEGIN(INITIAL);
			if(current_string.size()>=MAX_STR_CONST){
				cool_yylval.error_msg="String constant too long";
				return ERROR;
			}
			if(null_char_present){
				cool_yylval.error_msg="String contains null character";
				return ERROR;
			}
			cool_yylval.symbol = stringtable.add_string((char*)current_string.c_str());
			return STR_CONST;
}
<STRING>{ESCAPE}{NEWLINE} 	{
					current_string+='\n';
}
<STRING>{NEWLINE}	{
				BEGIN(INITIAL);
				curr_lineno++;
				cool_yylval.error_msg="String untermined constant";
				return ERROR;
}
<STRING>{NULL_CHAR}	{
				null_char_present=1;
}
<STRING>{ESCAPE}.	{
				char ch;
				switch(ch=yytext[1]){
					case 'b':
						current_string+='\b';
						break;
					case 't':
						current_string+='\t';
						break;
					case 'n':
						current_string+='\n';
						break;
					case 'f':
						current_string+='\f';
						break;
					case '\0':
						null_char_present=1;
						break;
					default:
						current_string+=ch;
						break;
				}
}
<STRING><<EOF>>		{
				BEGIN(INITIAL);
				cool_yylval.error_msg=" EOF IN STRING";
				return ERROR;
}
<STRING>.	{
			current_string+=yytext;
}
					



.		{
	cool_yylval.error_msg = yytext;
	return ERROR;
}

%%











































































