
typedef struct termSequence{
	char* name; /*variable or function name*/
	struct termSequence* list;
	struct termSequence* args;
}termSequence;
//				0		1	2     3 		4			5			6	  7		 8		9	
typedef enum {E_ATOM,E_AND,E_OR,E_NOT,E_IMPLICATION,E_EQUIVALENCE,E_ALL,E_EXIST,E_TOP,E_BOTTOM} fType;

typedef struct formula{
	fType type;
	char* name;
	termSequence* list;
	struct formula *leftFormula;
	struct formula *rightFormula;
}formula;

