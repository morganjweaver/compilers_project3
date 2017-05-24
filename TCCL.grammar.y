%namespace ASTBuilder
%partial
%parsertype TCCLParser
%visibility internal
%tokentype Token
%YYSTYPE AbstractNode

//%union {
	//	public AbstractNode a;
	  // }

%start CompilationUnit

%token STATIC, STRUCT, QUESTION, RSLASH, MINUSOP, NULL, INT, OP_EQ, OP_LT, COLON, OP_LOR
%token ELSE, PERCENT, THIS, CLASS, PIPE, PUBLIC, PERIOD, HAT, COMMA, VOID, TILDE
%token LPAREN, RPAREN, OP_GE, SEMICOLON, IF, NEW, WHILE, PRIVATE, BANG, OP_LE, AND 
%token LBRACE, RBRACE, LBRACKET, RBRACKET, BOOLEAN, INSTANCEOF, ASTERISK, EQUALS, PLUSOP
%token RETURN, OP_GT, OP_NE, OP_LAND, INT_NUMBER, IDENTIFIER, LITERAL, SUPER

%right EQUALS
%left  OP_LOR
%left  OP_LAND
%left  PIPE
%left  HAT
%left  AND
%left  OP_EQ, OP_NE
%left  OP_GT, OP_LT, OP_LE, OP_GE
%left  PLUSOP, MINUSOP
%left  ASTERISK, RSLASH, PERCENT
%left  UNARY 

%%

CompilationUnit		:	ClassDeclaration {$$ = new Nodes.CompilationUnit($1);}
					;

ClassDeclaration	:	Modifiers CLASS Identifier ClassBody {$$ = new Nodes.ClassDeclaration($1, $3, $4);}
					;

Modifiers			:	PUBLIC                  {$$ = new Nodes.Modifiers(Nodes.modType.PUBLIC);}
					|	PRIVATE                 {$$ = new Nodes.Modifiers(Nodes.modType.PRIVATE);}
					|	STATIC                  {$$ = new Nodes.Modifiers(Nodes.modType.STATIC);}
					|	Modifiers PUBLIC        {$$ = new Nodes.Modifiers(Nodes.modType.PUBLIC, $1);} //new node will be RIGHTMOST in "public static"
					|	Modifiers PRIVATE       {$$ = new Nodes.Modifiers(Nodes.modType.PRIVATE, $1);}
					|	Modifiers STATIC        {$$ = new Nodes.Modifiers(Nodes.modType.STATIC, $1);}
					;
ClassBody			:	LBRACE FieldDeclarations RBRACE  {$$ = new Nodes.ClassBody($2);}
					|	LBRACE RBRACE			{$$ = new Nodes.ClassBody();}
					;

FieldDeclarations	:	FieldDeclaration        {$$ = new Nodes.FieldDecls($1);}
					|	FieldDeclarations FieldDeclaration  {$1.adoptChildren($2);} //handle sib and child
					;

FieldDeclaration	:	FieldVariableDeclaration SEMICOLON  {$$ = $1;} 
					|	MethodDeclaration                   {$$ = $1;}
					|	ConstructorDeclaration              //{$$ = $1;}
					|	StaticInitializer                   //{$$ = $1;}
					|	StructDeclaration                   //{$$ = $1;}
					;

StructDeclaration	:	Modifiers STRUCT Identifier ClassBody
					;



/*
 * This isn't structured so nicely for a bottom up parse.  Recall
 * the example I did in class for Digits, where the "type" of the digits
 * (i.e., the base) is sitting off to the side.  You'll have to do something
 * here to get the information where you want it, so that the declarations can
 * be suitably annotated with their type and modifier information.
 */
FieldVariableDeclaration	:	Modifiers TypeSpecifier FieldVariableDeclarators  {$$ = new Nodes.FieldVarDecl($1, $2, $3);}
							;

TypeSpecifier				:	TypeName           {$$ = new Nodes.TypeSpec($1, false);}
							| 	ArraySpecifier     {$$ = new Nodes.TypeSpec($1, true);}
							;

TypeName					:	PrimitiveType	 {$$ = $1;}
							|   QualifiedName     {$$ = $1;}
							;

ArraySpecifier				: 	TypeName LBRACKET RBRACKET  {$$ = $1;}
							;
							
PrimitiveType				:	BOOLEAN    {$$ = new Nodes.Primitive(Nodes.primType.BOOLEAN);}
							|	INT      {$$ = new Nodes.Primitive(Nodes.primType.INT);}
							|	VOID     {$$ = new Nodes.Primitive(Nodes.primType.VOID);}
							;

FieldVariableDeclarators	:	FieldVariableDeclaratorName									{$$ = new Nodes.FieldVarDeclarators($1);}
							|   FieldVariableDeclarators COMMA FieldVariableDeclaratorName  {$$ = new Nodes.FieldVarDeclarators($3, $1);}
							;


MethodDeclaration			:	Modifiers TypeSpecifier MethodDeclarator MethodBody          {$$ = new Nodes.MethodDeclaration($1, $2, $3, $4);}
							;

MethodDeclarator			:	MethodDeclaratorName LPAREN ParameterList RPAREN             {$$ = new Nodes.MethodDeclarator($1, $3);}
							|   MethodDeclaratorName LPAREN RPAREN							  {$$ = new Nodes.MethodDeclarator($1);}
							;

ParameterList				:	Parameter                                                  {$$ = $1;}
							|   ParameterList COMMA Parameter							   {$1.makeSibling($3);}
							;

Parameter					:	TypeSpecifier DeclaratorName                               {$$ = new Nodes.Parameter($1, $2);}
							;
							 
QualifiedName				:	Identifier						  {$$ = new Nodes.QualName($1);}
							|	QualifiedName PERIOD Identifier   {$$ = $1; ((Nodes.QualName)$1).append($3);}
							;

DeclaratorName				:	Identifier              {$$ = $1;}
							;

MethodDeclaratorName		:	Identifier              {$$ = $1;}
							;

FieldVariableDeclaratorName	:	Identifier				{$$ = $1;}				
							;

LocalVariableDeclaratorName	:	Identifier              {$$ = $1;}
							;

MethodBody					:	Block					{$$ = $1;}
							;

ConstructorDeclaration		:	Modifiers MethodDeclarator Block
							;

StaticInitializer			:	STATIC Block
							;
		
/*
 * These can't be reorganized, because the order matters.
 * For example:  int i;  i = 5;  int j = i;
 */
Block						:	LBRACE LocalVariableDeclarationsAndStatements RBRACE    {$$ = new Nodes.Locals_and_Stmts($2);}
							|   LBRACE RBRACE										    {$$ = new Nodes.Empty();}
							;

LocalVariableDeclarationsAndStatements	:	LocalVariableDeclarationOrStatement {$$ = new Nodes.LocalFDOS($1);}
										|   LocalVariableDeclarationsAndStatements LocalVariableDeclarationOrStatement {$1.adoptChildren($2);}
										;

LocalVariableDeclarationOrStatement	:	LocalVariableDeclarationStatement {$$ = $1;}
									|   Statement {$$ = $1;}
									;

LocalVariableDeclarationStatement	:	TypeSpecifier LocalVariableDeclarators SEMICOLON {$$ = new Nodes.LocalVDS($1, $2);}
									|   StructDeclaration                 //IGNORED     						
									;

LocalVariableDeclarators	:	LocalVariableDeclaratorName                                  {$$ = $1;}
							|   LocalVariableDeclarators COMMA LocalVariableDeclaratorName   {$1.makeSibling($3);} 
							;

							

Statement					:	EmptyStatement                        {$$ = $1;}
							|	ExpressionStatement SEMICOLON         {$$ = $1;}
							|	SelectionStatement                    {$$ = $1;}
							|	IterationStatement                    {$$ = $1;}
							|	ReturnStatement                       {$$ = $1;}
							|   Block                                 {$$ = $1;}
							;

EmptyStatement				:	SEMICOLON                             {$$ = new Nodes.Empty();}
							;

ExpressionStatement			:	Expression
							;

/*
 *  You will eventually have to address the shift/reduce error that
 *     occurs when the second IF-rule is uncommented.
 *
 */

SelectionStatement			:	IF LPAREN Expression RPAREN Statement ELSE Statement {$$ = new Nodes.IfNode($3, $5, $7);}
//							|   IF LPAREN Expression RPAREN Statement
							;


IterationStatement			:	WHILE LPAREN Expression RPAREN Statement  {$$ = new Nodes.While($3, $5);}
							;

ReturnStatement				:	RETURN Expression SEMICOLON
							|   RETURN            SEMICOLON {$$ = new Nodes.Empty();}
							;

ArgumentList				:	Expression                       {$$ = $1;}
							|   ArgumentList COMMA Expression    {$$ = $1.makeSibling($3);}
							;


Expression					:	QualifiedName EQUALS Expression                            {$$ = new Nodes.Expression($1, "EQUALS", $3);}
							|   Expression OP_LOR Expression   /* short-circuit OR */
							|   Expression OP_LAND Expression   /* short-circuit AND */
							|   Expression PIPE Expression
							|   Expression HAT Expression
							|   Expression AND Expression
							|	Expression OP_EQ Expression                                 {$$ = new Nodes.Expression($1, "OP_EQ", $3);}
							|   Expression OP_NE Expression                                 {$$ = new Nodes.Expression($1, "OP_NE", $3);}
							|	Expression OP_GT Expression                                 {$$ = new Nodes.Expression($1, "OP_GT", $3);}
							|	Expression OP_LT Expression                                 {$$ = new Nodes.Expression($1, "OP_LT", $3);}
							|	Expression OP_LE Expression                                 {$$ = new Nodes.Expression($1, "OP_LE", $3);}
							|	Expression OP_GE Expression                                 {$$ = new Nodes.Expression($1, "OP_GE", $3);}
							|   Expression PLUSOP Expression                                 {$$ = new Nodes.Expression($1, "PLUSOP", $3);}
							|   Expression MINUSOP Expression                                {$$ = new Nodes.Expression($1, "MINUSOP", $3);}
							|	Expression ASTERISK Expression                               
							|	Expression RSLASH Expression
							|   Expression PERCENT Expression	/* remainder */
							|	ArithmeticUnaryOperator Expression  %prec UNARY             {$$ = new Nodes.Expression(((Nodes.Arith)$1).op, $2);}
							|	PrimaryExpression                                            {$$ = $1;}
							;

ArithmeticUnaryOperator		:	PLUSOP    {$$ = new Nodes.Arith("PLUSOP");}
							|   MINUSOP   {$$ = new Nodes.Arith("MINUSOP");}
							;
							
PrimaryExpression			:	QualifiedName    {$$ = $1;}
							|   NotJustName      {$$ = $1;}
							;

NotJustName					:	SpecialName       {$$ = $1;}
							|   ComplexPrimary    {$$ = $1;}
							;

ComplexPrimary				:	LPAREN Expression RPAREN     {$$ = $1;}
							|   ComplexPrimaryNoParenthesis  {$$ = $1;}
							;

ComplexPrimaryNoParenthesis	:	LITERAL          {$$ = new Nodes.Literal(yytext);}
							|   Number           {$$ = $1;}
							|	FieldAccess      {$$ = $1;}
							|	MethodCall       {$$ = $1;}
							;

FieldAccess					:	NotJustName PERIOD Identifier
							;		

MethodCall					:	MethodReference LPAREN ArgumentList RPAREN  {$$ = new Nodes.MethodCall($1, $3);}
							|   MethodReference LPAREN RPAREN                {$$ = new Nodes.MethodCall($1);} 
							;

MethodReference				:	ComplexPrimaryNoParenthesis {$$ = $1;}
							|	QualifiedName               {$$ = $1;}
							|   SpecialName                 {$$ = $1;}
							;

SpecialName					:	THIS       {$$ = new Nodes.Special("THIS");}
							|	NULL	   {$$ = new Nodes.Special("NULL");}
							;

Identifier					:	IDENTIFIER {$$ = new Nodes.Identifier(yytext);}
							;

Number						:	INT_NUMBER {$$ = new Nodes.Number(yytext);}
							;

%%

public string yytext
{
	get { return((TCCLScanner)Scanner).yytext; }
}