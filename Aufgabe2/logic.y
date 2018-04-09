 /* 
     First parser
 */

%{
	#include <stdio.h>
	#include "structs.h"
	extern int yyerror(char* err);
	extern int yylex(void);
	extern char* strdup(char*);
	extern char* strcat(char*, char*);
	void addToList(termSequence* head, termSequence* tail);
	void debugPrintTermsequence(termSequence* tlist);
	void printFormula(formula* f,int indent);
	formula* createFormula(fType t,char* name);
	char* termsequenceToStr(termSequence* tlist);
	char* indentStr(int n);
   
	formula* result; 
	
%}

/*todo idee: alle kontruktoren durch (term*)malloc(sizeof(term)) ersetzen Dann mus man nicht mehr kopieren*/

%union { /*for yylval*/
   char* name;
   struct formula* f;
   struct termSequence* list;
}


%start result

%token OPENPAR
%token CLOSEPAR
%token COMMA
%token TOP
%token BOTTOM
%token VARIABLE
%precedence EQUIVALENCE
%precedence IMPLICATION
%left  OR
%left  AND
%precedence  NOT
%precedence ALL EXIST
%precedence PREDICATE
%precedence FUNCTION
%precedence ERROR


%%
result: formula {
					puts("bison: Reached End");
					result=$<f>1;
					printFormula(result,0);
};

formula:  atom {
					puts("bison: formula = atom");
					$<f>$=$<f>1;
					}
		| NOT formula {
					puts("bison: formula = not formula");
					formula* f=createFormula(E_NOT,strdup("NOT"));
					f->leftFormula=$<f>1;
					$<f>$=f;
					puts(f->name);
					}
		| OPENPAR formula CLOSEPAR {
					puts("bison: formula = ( formula )");
					$<f>$=$<f>1;		
			}
		| TOP {
					puts("bison: formula = top");
					formula* f=createFormula(E_TOP,strdup("TOP"));
					$<f>$=f;
					puts(f->name);
			}
		| BOTTOM {
					puts("bison: formula = bottom");
					formula* f=createFormula(E_BOTTOM,strdup("BOTTOM"));
					$<f>$=f;
					puts(f->name);
			}
		| ALL term formula {
					puts("bison: formula = all variable formula");
					formula* f=createFormula(E_ALL,strdup("ALL"));
					f->list=$<list>1;
					f->leftFormula=$<f>3;
					$<f>$=f;
					puts(f->name);
					}
		| EXIST term formula {
					puts("bison: formula = exist variable formula");
					formula* f=createFormula(E_EXIST,strdup("EXIST"));
					f->list=$<list>1;
					f->leftFormula=$<f>3;
					$<f>$=f;
					puts(f->name);
					}
		| formula AND formula {
					puts("bison: formula = formula and formula");
					formula* f=createFormula(E_AND,strdup("AND"));
					f->leftFormula=$<f>1;
					f->rightFormula=$<f>3;
					$<f>$=f;
					puts(f->name);
					}
		| formula OR formula {
					puts("bison: formula = formula or formula");
					formula* f=createFormula(E_OR,strdup("OR"));
					f->leftFormula=$<f>1;
					f->rightFormula=$<f>3;
					$<f>$=f;
					puts(f->name);
					}
		| formula IMPLICATION formula {
					puts("bison: formula = formula implication formula");
					formula* f=createFormula(E_IMPLICATION,strdup("IMPLICATION"));
					f->leftFormula=$<f>1;
					f->rightFormula=$<f>3;
					$<f>$=f;
					puts(f->name);
					}
		| formula EQUIVALENCE formula {
					puts("bison: formula = formula equivalence formula");
					formula* f=createFormula(E_EQUIVALENCE,strdup("EQUIVALENCE"));
					f->leftFormula=$<f>1;
					f->rightFormula=$<f>3;
					$<f>$=f;
					puts(f->name);
					};
  
termsequence: term {puts("bison: termsequence = term");
					struct termSequence* t =$<list>1;
					puts(t->name);
					$<list>$=t;
					}
			|termsequence COMMA term {puts("bison: termsequence = termsequence comma term");
					struct termSequence* t=$<list>1; /*first term that was read?*/
					addToList(t,$<list>3); /*x->y */						
					$<list>$=t;
					debugPrintTermsequence(t);
		};
		
term:     VARIABLE {puts("term = variable:");
					struct termSequence* t=(termSequence*)malloc(sizeof(termSequence));
					t->name=$<name>1;
					puts(t->name);
					t->list=NULL;
					$<list>$=t;
					}
		| FUNCTION {puts("bison: term = function");  /*Constant, no paramter list*/
					struct termSequence* func=(termSequence*)malloc(sizeof(termSequence));
					func->name=$<name>1;
					func->list=NULL;
					puts(func->name);
					$<list>$=func;
					}
		| FUNCTION OPENPAR termsequence CLOSEPAR {puts("bison: term = function(termsequence)");
					struct termSequence* func=(termSequence*)malloc(sizeof(termSequence));
					func->name=$<name>1;
					puts(func->name);
					func->list=$<list>3;
					debugPrintTermsequence(func->list);
					$<list>$=func;
		};
		
atom:     PREDICATE {
					puts("bison: atom= predicate");
					struct formula* atom=createFormula(E_ATOM,$<name>1);
					$<f>$=atom;
					puts(atom->name);
					}
		| PREDICATE OPENPAR termsequence CLOSEPAR {
					puts("bison: atom = predicate(termsequence)");
					struct formula* atom=createFormula(E_ATOM,$<name>1);
					atom->list=$<list>3;
					$<f>$=atom;	
					puts(atom->name);
					}
		| term {
					puts("bison: atom = term");
					struct formula* atom=createFormula(E_ATOM,$<list>1->name);
					$<f>$=atom;	
					puts(atom->name);
					};
%%

int yyerror(char* err)
{
   printf("Error: %s", err);
   return 0;
}

void printFormula(formula* f,int indent){
	/*puts(f->name);*/
	if(f!=NULL){
		printf("%s%s\n",indentStr(indent),f->name);
		indent++;
		
		switch(f->type){
			case E_ATOM:
				if(f->list!=NULL)
					printf("%s ts: %s\n",indentStr(indent),termsequenceToStr(f->list));
				break;
			case E_AND:
				printFormula(f->leftFormula,indent);
				printFormula(f->rightFormula,indent);
				break;
			case E_ALL:
				if(f->list!=NULL)
					printf("%s%s\n",indentStr(indent),termsequenceToStr(f->list));
				printFormula(f->leftFormula,indent);
				printFormula(f->rightFormula,indent);
				break;
			case E_BOTTOM:
				break;
			case E_EQUIVALENCE:
				printFormula(f->leftFormula,indent);
				printFormula(f->rightFormula,indent);
				break;
			case E_EXIST:
				if(f->list!=NULL)
					printf("%s%s\n",indentStr(indent),termsequenceToStr(f->list));
				printFormula(f->leftFormula,indent);
				printFormula(f->rightFormula,indent);
				break;
			case E_IMPLICATION:
				printFormula(f->leftFormula,indent);
				printFormula(f->rightFormula,indent);
				break;
			case E_NOT:
				printFormula(f->leftFormula,indent);
				break;
			case E_OR:
				printFormula(f->leftFormula,indent);
				printFormula(f->rightFormula,indent);
				break;
			case E_TOP:
				break;
		}
	}	
}

char* indentStr(int n)
{
	char* result="";
	
	for (int i=0;i<n;i++)
	{
		result=strcat(result,"\t");
	}
	return strdup(result);
}

void addToList(termSequence* head, termSequence* tail){
	termSequence* pointer = head;
	while(pointer->list!=NULL){
		/*puts(pointer->name);*/
		pointer=pointer->list;
	}
	pointer->list=tail;
}

char* termsequenceToStr(termSequence* tlist){
	char* result="";
	while(tlist!=NULL){
		if(result!="") result=strcat(strcat(result,","),strdup(tlist->name));
		else result=tlist->name;
		tlist=tlist->list;
	}
	return strdup(result);
}

void debugPrintTermsequence(termSequence* tlist){
	puts("bison: termSequence:");
	puts(termsequenceToStr(tlist)); 
}

formula* createFormula(fType t,char* name)
{
	struct formula* f=(formula*)malloc(sizeof(formula));
	f->type=t;
	f->name=name;
	f->list=NULL;
	f->leftFormula=NULL;
	f->rightFormula=NULL;
	return(f);
}

int main (int argc, char* argv[])
{
	
  puts("bison: Starting");
  return yyparse();
}