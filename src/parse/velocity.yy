%left '||' '&&'
%left '>' '==' '<'
%left '+' '-'
%left '*' '/' 
%left '!'
%left UMINUS

%start root

%%

root
  : program EOF 
      { return $1; }
  ;

program
  : statements 
      { $$ = $1; }
  ;

statements
  : statement 
      { $$ = [$1]; }
  | statements statement 
      { $$ = [].concat($1, $2); }
  ;

statement
  : references 
      { $$ = $1; }
  | directives 
      { $$ = $1; }
  | content 
      { $$ = $1; }
  | COMMENT
      { $$ = {type: 'comment', value: $1}; }
  ;

directives
  : set 
      { $$ = $1; }
  | if 
      { $$ = $1; }
  | elseif
      { $$ = $1; }
  | else 
      { $$ = $1; }
  | end
      { $$ = $1; }
  | foreach
      { $$ = $1; }
  | break
      { $$ = $1; }
  | include
      { $$ = $1; }
  | parse
      { $$ = $1; }
  | evaluate
      { $$ = $1; }
  | define
      { $$ = $1; }
  | macro
      { $$ = $1; }
  | macro_call
      { $$ = $1; }
  ;

set
  : HASH SET PARENTHESIS equal CLOSE_PARENTHESIS 
      { $$ = {type: $2, equal: $4}; }
  ;

if
  : HASH IF PARENTHESIS expression CLOSE_PARENTHESIS
      { $$ = {type: $2, condition: $4}; }
  ;

elseif
  : HASH ELSEIF PARENTHESIS expression CLOSE_PARENTHESIS
      { $$ = {type: 'elseif', condition: $4}; }
  ;

else
  : HASH ELSE
      { $$ = {type: 'else'}; }
  ;

end
  : HASH END
      { $$ = {type: 'end'}; }
  ;

foreach
  : HASH FOREACH PARENTHESIS DOLLAR ID IN references CLOSE_PARENTHESIS
      { $$ = {type: 'foreach', to: $5, from: $7}; }
  | HASH FOREACH PARENTHESIS DOLLAR ID IN array CLOSE_PARENTHESIS
      { $$ = {type: 'foreach', to: $5, from: $7}; }
  ;

break
  : HASH BREAK
      { $$ = {type: $2}; }
  ;

include
  : HASH INCLUDE PARENTHESIS params CLOSE_PARENTHESIS
      { $$ = {type: 'include', args: $4}; }
  ;

parse
  : HASH PARSE PARENTHESIS string CLOSE_PARENTHESIS
      { $$ = {type: 'parse', id: $4}; }
  ;

evaluate
  : HASH EAVL PARENTHESIS DOLLAR ID CLOSE_PARENTHESIS
      { $$ = {type: 'evaluate', id: $5}; }
  ;

define
  : HASH DEFINE PARENTHESIS DOLLAR ID CLOSE_PARENTHESIS
      { $$ = {type: 'define', id: $5}; }
  ;

macro
  : HASH MACRO PARENTHESIS ID macro_args CLOSE_PARENTHESIS
      { $$ = {type: 'macro', id: $4, args: $5}; }
  | HASH MACRO PARENTHESIS ID CLOSE_PARENTHESIS
      { $$ = {type: 'macro', id: $4}; }
  ;

macro_args
  : references
      { $$ = [$1]; }
  | macro_args references
      { $$ = [].concat($1, $2); }
  ;

macro_call
  : HASH ID PARENTHESIS macro_call_args CLOSE_PARENTHESIS
      { $$ = {type:"macro_call", id: $2, args: $4}; }
  | HASH ID PARENTHESIS CLOSE_PARENTHESIS
      { $$ = {type:"macro_call", id: $2}; }
  ;

/**
 * 空格被忽略了，references array 无法和references自身区分开，比如$name[1],
 * $name [1]两者是一样的，可以是references array，也可以是references 此处处理，
 * 让macro_call_args和velocity解释有差异 
 */
macro_call_args
  : literal
      { $$ = [$1]; }
  | array
      { $$ = [$1]; }
  | references
      { $$ = [$1]; }
  | macro_call_args literal
      { $$ = [].concat($1, $2); }
  | macro_call_args references
      { $$ = [].concat($1, $2); }
  ;

arguments
  : DOLLAR ID
      { $$ = $2; }
  | arguments DOLLAR ID
      { $$ = [].concat($1, $3); }
  ;

equal
  : references EQUAL expression 
      { $$ = [$1, $3]; }
  ;

expression
  : array
      { $$ = $1; }
  | map
      { $$ = $1; }
  | math
      { $$ = $1; }
  ;

math
  : math '||' math
      { $$ = {type: 'math', expression: [$1, $3], operator: $2}; }
  | math '&&' math
      { $$ = {type: 'math', expression: [$1, $3], operator: $2}; }
  | math '+' math
      { $$ = {type: 'math', expression: [$1, $3], operator: $2}; }
  | math '-' math
      { $$ = {type: 'math', expression: [$1, $3], operator: $2}; }
  | math '*' math
      { $$ = {type: 'math', expression: [$1, $3], operator: $2}; }
  | math '/' math
      { $$ = {type: 'math', expression: [$1, $3], operator: $2}; }
  | math '>' math
      { $$ = {type: 'math', expression: [$1, $3], operator: $2}; }
  | math '<' math
      { $$ = {type: 'math', expression: [$1, $3], operator: $2}; }
  | math '==' math
      { $$ = {type: 'math', expression: [$1, $3], operator: $2}; }
  | PARENTHESIS math CLOSE_PARENTHESIS
      { $$ = {type: 'math', expression: [$2], operator: 'parenthesis'}; }
  | '!' math
      { $$ = {type: 'math', expression: [$2], operator: 'not'}; }
  | '-' references %prec UMINUS
      { $$ = {type: 'math', expression: [$2], operator: 'minus'}; }
  | references
      { $$ = $1; }
  | literal
      { $$ = $1; }
  ;

references
  : DOLLAR VAR_BEGIN ID attributes VAR_END 
      { $$ = {type: "references", id: $3, path: $4, isWraped: true, leader: $1}; }
  | DOLLAR ID attributes 
      { $$ = {type: "references", id: $2, path: $3, leader: $1}; }
  | DOLLAR ID 
      { $$ = {type: "references", id: $2, leader: $1}; }
  | DOLLAR VAR_BEGIN ID VAR_END 
      { $$ = {type: "references", id: $3, isWraped: true, leader: $1}; }
  ;

attributes
  : attribute 
      { $$ = [$1]; }
  | attributes attribute 
      { $$ = [].concat($1, $2); }
  ;

attribute
  : method 
      { $$ = {type:"method", id: $1.id, args: $1.args}; }
  | index 
      { $$ = {type: "index", id: $1}; }
  | property 
      { $$ = {type: "property", id: $1}; }
  ;

method
  : DOT ID PARENTHESIS params CLOSE_PARENTHESIS 
      { $$ = {id: $2, args: $4}; }
  | DOT ID PARENTHESIS CLOSE_PARENTHESIS 
      { $$ = {id: $2, args: false}; }
  ;

params
  : literals 
      { $$ = [$1]; }
  | references 
      { $$ = [$1]; }
  | params COMMA literals 
      { $$ = [].concat($1, $3); }
  | params COMMA references 
      { $$ = [].concat($1, $3); }
  ;

property
  : DOT ID 
      { $$ = $2; }
  | DOT CONTENT 
      { $$ = '<<<' + $1 + $2; }
  ;

index
  : BRACKET literal CLOSE_BRACKET 
      { $$ = $2; } 
  | BRACKET references CLOSE_BRACKET 
      { $$ = $2; } 
  | BRACKET literal CONTENT 
      { $$ = "<<<" + $1 + $2 + $3; } 
  | BRACKET CONTENT 
      { $$ = "<<<" + $1 + $2; } 
  | BRACKET CLOSE_BRACKET 
      { $$ = "<<<" + $1 + $2; } 
  ;

literal
  : string 
      { $$ = $1; }
  | integer
      { $$ = {type: 'integer', value: $1}; }
  ;

integer
  : INTEGER
      { $$ = $1; }
  | '-' INTEGER
      { $$ = - parseInt($2, 10); }
  ;

string
  : STRING
      { $$ = {type: 'string', value: $1}; }
  | EVAL_STRING
      { $$ = {type: 'string', value: $1, isEval: true}; }
  ;

literals
  : array 
      { $$ = $1;}
  | map
      { $$ = $1;}
  | literal 
      { $$ = $1; }
  ;

array
  : BRACKET params CLOSE_BRACKET 
      { $$ = {type: 'array', value: $2}; }
  | BRACKET integer RANGE integer CLOSE_BRACKET 
      { $$ = {type: 'array', isRange: true, value: [$2, $4]}; }
  | BRACKET CLOSE_BRACKET 
      { $$ = {type: 'array', value: []}; }
  ;

map
  : MAP_BEGIN map_item MAP_END
      { $$ = {type: 'map', value: $2}; }
  ;

map_item
  : string MAP_SPLIT literal
      { $$ = {}; $$[$1.value] = $3; }
  | string MAP_SPLIT references
      { $$ = {}; $$[$1.value] = $3; }
  | map_item COMMA string MAP_SPLIT references
      { $$ = $1; $$[$3.value] = $5; }
  | map_item COMMA string MAP_SPLIT literal
      { $$ = $1; $$[$3.value] = $5; }
  ;
    
content
  : CONTENT 
      { $$ = $1; }
  | ID 
      { $$ = $1; }
  | HASH CONTENT
      { $$ = $1 + $2; }
  | HASH ID CONTENT
      { $$ = $1 + $2 + $3; }
  | HASH ID EOF
      { $$ = $1 + $2; }
  ;
