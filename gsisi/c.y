// in this example everything is passed around as a string 
// and converted to and from other types when needed

%baseclass-preinclude Util.h
%stype Return

%token  PREPROCESSOR_INCLUDE FOR WHILE IF ELSE ELSE_IF 
%token ID FLOAT ASSIGN_OP COMP_OP INSERT_OP ADSUB_OP MULDIV_OP 
%token COMMA EOL LBRACKET RBRACKET LCURLY RCURLY STRING MAIN
%token RETURN INCDEC_OP DO BOOL_OP LSQUARE RSQUARE UN_INT
%token BIT_AND BIT_XOR BIT_OR BIT_NOT STRUCT PTR CHAR 
%token CASE SWITCH DEFAULT BREAK COLON TYPEDEF SIZEOF

%%

// A file has code before main, main, and code after main
file  : not_main file
      | main after_main
      | main
      ;

after_main : not_main after_main
           | not_main
           ;

// Code before main consists of includes, function definitions, functions declarations
// Struct declarations and typedefs
not_main :  include {
            int f = ($1.d).find("<");
            std::string str;

            // Returns the name, in quotes, of the file included 
            if(f != -1){ // if '<' is found
              int len = ($1.d).find(">") - (f+1); // find '<'
                                                  // and calculate the length of the string to cut
              str = "\"" + ($1.d).substr(f+1, len) + "\""; // cut the string and put it in quotes
            } else {
              str = ($1.d).substr(9); // if the name is already in quotes, just select the name
            }

            if (str == "\"stdio.h\"") {
             incl_Stdio = true; // if the include is library stdio, set the flag
           }else if (str == "\"stdlib.h\"") {
             incl_Stdlib = true; // if the include is library stdlib, set the flag
           } else {
             code.push_back(".include " + str); // else, include the file in ARM
           }

        }
	    | func_def
      | func_decl
	    | var_decl
      | typedef
	    ;

include : PREPROCESSOR_INCLUDE {$$.d = lexer.YYText();}
        ;


// Typedef of pointer and non-pointer types
typedef : TYPEDEF id id EOL {
              int i = find_type($2.d); // find type
              typel[i].names.push_back(Name($3.d)); // insert the name into the list of names for the type
          }
        | TYPEDEF id PTR id EOL {
              int i = find_type($2.d); // find type
              typel[i].names.push_back(Name($4.d, true)); // insert the name into the list of names for the type
                                                          // set that it's a pointer type
        }
        ;


/////////////////////////////////////////STRUCTS/////////////////////////////////////////////

// Struct declaration
var_decl : STRUCT id var_decl_r EOL {
  std::vector<DataInt*> v;

// Inserts into a vector all the elements in the stack
  for (std::vector<DataInt*>::iterator it=stack.begin(); it!=stack.end(); ++it){
    Var* tt = (Var*) (*it);
    Var* temp = new Var(tt->name, $1.d, tt->reg, tt->lbl, tt->isPointer);
    v.push_back(temp);    
  }

// Creates a new struct with the vector as the members of the struct
  Struct* temp = new Struct("struct "+ $2.d, "struct", v);
  typel.push_back(Type("struct " + $2.d, c_int($3.lbl))); // inserts the name of the type into the type list
                                                          // as well as its size, calculated from its members
  stack.erase(stack.begin(), stack.end()); // erases the stack

// if the struct has already been created, returns an error, else, it creates the struct
  if(!findvar(temp->str(),0)){
      varl.insert(std::pair<int,DataInt*>(scope-1, temp));
  } else {
    error("Name already taken");
  }
}
        ;

var_decl_r : LCURLY RCURLY {$$.lbl = "0";}
          | LCURLY {scope++;} elements RCURLY {delete_lvl(varl, scope);}
          ;

elements : newvar EOL elements {
            // adds the type sizes of the two elements
            $$.lbl = convert<std::string>(get_types($1.d) + c_int($3.lbl));}
          | newvar EOL {$$.lbl = convert<std::string>(get_types($1.d));} // gets type size of element
          ;



/////////////////////////////////FUNCTION DEFINITION/////////////////////////////////////////

// Function definition
func_def : id id args {

  if($1.d == "void" || type_check($1.d)){
    std::vector<DataInt*> v;
    
    // All elements in the stack are arguments of the function, and are inserted into vector v
    for (std::vector<DataInt*>::iterator it=stack.begin(); it!=stack.end(); ++it){
      Var* tt = (Var*) (*it);
      Var* temp = new Var(tt->name, $1.d, tt->reg, tt->lbl, tt->isPointer);
      v.push_back(temp);    
    }

  Funct* temp = new Funct($2.d, $1.d, v);
  currentFunc = temp; // set the current function
  stack.erase(stack.begin(), stack.end());

  // if function is not found, it is inserted into the variable map
  // otherwise, the current position in the code is saved
  // and later inserted where the label for the function declaration was
  if(!findvar(temp->str(), 0)){
      varl.insert(std::pair<int,DataInt*>(scope, temp));
      code.push_back("\n"+ $2.d + ":");
  } else {
    // saves the current position in the code
    std::vector<std::string>::iterator it = code.end();
    pos.push_back(--it);
    $2.lbl = "declared";
  }

  code.push_back( "STMFD sp!, {r4-r12, lr}" );
  if(v.size()>4){
    code.push_back( "LDMFD sp!, {r4-r" + convert<std::string>(v.size()-1) +", lr}" );
  }

}
} func_body {
  code.push_back( "LDMFD sp!, {r4-r12, pc}" );
  stack.erase(stack.begin(), stack.end());

  if($2.lbl == "declared"){ // if function was declared, insert the saved code in the correct place
   save_code();

   std::vector<std::string>::iterator temp = std::find(code.begin(), code.end(), ($2.d+":"));
   code.insert(--temp, tcode.begin(), tcode.end());
  }

  // if type is not void, check whether there has been a return
  if(currentFunc->type != "void" && currentFunc->hasReturned == 0){
    warning("Function has no return value");
  }

  emptyRegisters(); // empty all registers

}
  ;


//////////////////////////////////FUNCTION DECLARATION///////////////////////////////////////

// Function declaration
func_decl : id id args EOL {

if($1.d == "void" || type_check($1.d)){
  std::vector<DataInt*> v;

  // All elements in stack are arguments to the function, and are inserted into a vector
  for (std::vector<DataInt*>::iterator it=stack.begin(); it!=stack.end(); ++it){
    Var* tt = (Var*) (*it);
    Var* temp = new Var(tt->name, $1.d, tt->reg, tt->lbl, tt->isPointer);
    v.push_back(temp);    
  }

// Function is inserted into the variable map if it hasn't already been declared
  Funct* temp = new Funct($2.d, $1.d, v);
  if(!findvar(temp->str(), 0)){
    varl.insert(std::pair<int,DataInt*>(scope, temp));
    code.push_back("\n"+$2.d + ":");
    code.push_back("MOV pc, lr");
  } else {
    warning("Function has already been declared");
  }

  stack.erase(stack.begin(), stack.end());
  delete_lvl(varl, scope+1); 
}
}
  ;

args : LBRACKET {scope++; lblcc =0; stack.erase(stack.begin(), stack.end());} args_n 
        {scope--; lblcc=0;}
      RBRACKET
      | LBRACKET RBRACKET
  ;

args_n :  funcvar COMMA args_n
        | funcvar
    ;


///////////////////////////////////////FUNCTION CALL/////////////////////////////////////////
// Function call 
func_call: id call_args {

  std::vector<DataInt*> v;

  // All elements in the stack are arguments of the function and are saved into vector v
  for (std::vector<DataInt*>::iterator it=stack.begin(); it!=stack.end(); ++it){
    Var* tt = (Var*) (*it);
    Var* temp = new Var(tt->name, tt->type, tt->reg, tt->lbl, tt->isPointer);
    v.push_back(temp); 
  }

 int i, j = v.size()-1;
 std::string str = "";

 // if there are more than three arguments, store the rest in memory
 if(j>3){
  str = "STMFD sp!, {r";
 }

// store the rest in registers r0-r3
  for (i = v.size()-1; i>=0; i--){
    if(i==4){
      str += use() + "}";
    } else if(i>3){
      str += use() + ", r";
    } else{
      code.push_back("MOV r" + convert<std::string>(i) + ", r" +use());
    }

  }

  if(j>3){
   code.push_back(str);
  }

// If printf, check the correct library has been included
 if($1.d == "printf"){
      if (!incl_Stdio) return warning("Undefined reference to 'printf'. Might be referring to built-in function 'printf', not currently included.");
      $$.d = "int";
 } else if ($1.d == "malloc"){
  // If malloc, check the correct library has been included
	if (!incl_Stdlib) return warning("Undefined reference to 'malloc'. Might be referring to built-in function 'malloc', not currently included.");
      //error("Function malloc takes only 1 argument");
      Funct* temp = new Funct($1.d, "int", v);
      $$.lbl = "ptr";
      $$.d = "void";
} else if ($1.d == "free"){ 
  // If free, check the correct library has been included
     if (!incl_Stdlib) return warning("Undefined reference to 'free'. Might be referring to built-in function 'free', not currently included.");
     //error("Function free takes only 1 argument");
     Funct* temp = new Funct($1.d, "int", v);
     $$.lbl = "ptr";
     $$.d = "void";	 	

} else {
  // Else, check the function has been declared or defined, and has been called with the right arguments
      std::string temp_type = get_type($1.d, 0);
      Funct* temp = new Funct($1.d, temp_type, v);
      if(!findvar(temp->str(), 0)){
        error("Wrong arguments provided to function");
      }
      $$.d = temp_type;
  }

  code.push_back("BL " + $1.d );
  stack.erase(stack.begin(), stack.end());

}
;


call_args : LBRACKET {stack.erase(stack.begin(), stack.end());
    } call_args_n RBRACKET
    | LBRACKET RBRACKET
    ;

call_args_n: param COMMA call_args_n 
	         | param
	;


////////////////////////////////////////MAIN////////////////////////////////////////////////

main  : id MAIN main_args {
        currentFunc=NULL;
        if($1.d != "int"){
          error("Type of main must be int");
        }
        code.push_back( "\nmain:");
        code.push_back( "STMFD sp!, {lr}" );
      } func_body {
        stack.erase(stack.begin(), stack.end());
        code.push_back( "LDMFD sp!, {pc}" );
      }
    ;

main_args : LBRACKET {scope++;} newvar COMMA newvar {scope--;}RBRACKET
                  { 
                    // checks the arguments of main
                    type_compare ($3.d, "int");
                    type_compare ($5.d, "char");
                  }
  	       | LBRACKET RBRACKET
  ;


///////////////////////////////////FUNCTION BODY//////////////////////////////////////////////

func_body : LCURLY {scope++; stack.erase(stack.begin(), stack.end());} // increase scope, delete stack
            func_body_u RCURLY 
              // delete current scope, decrease scope
              // delete stack
              {stack.erase(stack.begin(), stack.end());
              delete_lvl(varl, scope);
              scope--;}
	         | LCURLY RCURLY
;

func_body_u  : line {
                    // after every line, delete stack and tempvar
                    tempvar.erase(tempvar.begin(), tempvar.end());
                    stack.erase(stack.begin(), stack.end());
	                  code.push_back("");} 
              func_body_u
             | line
    ;

////////////////////////////////CONTROL STATEMENTS///////////////////////////////////////////

loop :  FOR LBRACKET for_cond {
            		  tempvar.erase(tempvar.begin(), tempvar.end());
            		  stack.erase(stack.begin(), stack.end());
                  save_code(); // remove the assignment from the code and save it into
                              // a temporary vector
                  // Set a branch to the end of the loop if the condition is not met
                  code.push_back( select_b($3.d) + "for_end"+ convert<std::string>(lblc) );
                  }
        RBRACKET func_body {
                  code.insert(code.end(), tcode.begin(), tcode.end());
                  tcode.erase(tcode.begin(), tcode.end());
                  code.push_back( "B for"+ convert<std::string>(lblc) );
                  code.push_back( "for_end" + convert<std::string>(lblc) + ":" );
                  lblc++;}
       | WHILE { // Label for the start of the loop
                code.push_back( "while" + convert<std::string>(lblc) + ":" );} 
       LBRACKET bool_check {
                  // Set a branch to the end of the loop if the condition is not met
                  code.push_back( select_b($4.d) + "while_end"+ convert<std::string>(lblc) );}
       RBRACKET func_body {
                  // Branch back to the beginning of the loop
                  code.push_back( "B while"+ convert<std::string>(lblc) );
                  // Label signifying the end of the loop
                  code.push_back( "while_end" + convert<std::string>(lblc) + ":" );
                  lblc++; // increase the label counter
                  }
       | DO {
            // Label for the start of the loop
            code.push_back( "do_while" + convert<std::string>(lblc) + ":" );} 
       func_body WHILE LBRACKET bool_check RBRACKET EOL 
       {// Branch to the start of the loop if the condition is met
        code.push_back( "B" + select_cond($6.d) + "dowhile"+ convert<std::string>(lblc) ); 
        lblc++; // increase the label counter
       }
      ;


select :  IF LBRACKET bool_check RBRACKET {
            // Branches to the first else if the condition is not met
            code.push_back( select_b($3.d) + "else" + convert<std::string>(lblc) + convert<std::string>(lblcc) );
          } func_body {
            // Branches to the end of the whole if/elseif/else statement
            code.push_back( "B end" + convert<std::string>(lblc) );
            // Label for the first else
            code.push_back( "else" + convert<std::string>(lblc) + convert<std::string>(lblcc) + ":" );}  
          else_l {
            // Branches to the end of the whole if/elseif/else statement
            code.push_back( "end" + convert<std::string>(lblc) + ":" );
            lblc++; lblcc=0; // Increases the label count, resets the secondary label count
                            // which keeps track of the number of elses for the current if
            }
          | SWITCH LBRACKET extended_id RBRACKET LCURLY switch_body RCURLY 
          ;

switch_body : CASE COLON switch_body_u switch_body
            | DEFAULT COLON switch_body_u
            ;

// A function body is optional for the switch
switch_body_u : func_body_u 
              |
              ;

// An else is optional
else_l : else_loop
        | 
        ;

else_loop : ELSE_IF LBRACKET bool_check RBRACKET 
              {lblcc++; // increases the number of elses there currently are for the current if
              // Branches to the next else if the condition is not met
              code.push_back( select_b($3.d) + "else"+ convert<std::string>(lblc) + convert<std::string>(lblcc) );}
            func_body { 
              // Branches to the end of the if/elseif/else statement
              code.push_back( "B end" + convert<std::string>(lblc) );
              // Label for the next else
              code.push_back( "else"+ convert<std::string>(lblc) + convert<std::string>(lblcc) +":" );} 
            else_l
           | ELSE func_body
             ;



for_cond : for_assign {
              // Label for the start of the loop
              code.push_back( "for" + convert<std::string>(lblc) + ":" );  
              }
          EOL bool EOL {
              // Save the current position in the code, to be able to move the assignment
              // to the end of the the for loop
              std::vector<std::string>::iterator it = code.end();
              pos.push_back(--it);}
          id_assign_ext {$$=$4;}
          | newvar assign {
              if($2.d != ""){
                type_compare($1.d,$2.d);
                code.push_back( "STR r" + use() + ", [r" + use() + "]");
              }
                // Label for the start of the loop
                code.push_back( "for" + convert<std::string>(lblc) + ":" );
              }
          EOL bool EOL {
              // Save the current position in the code, to be able to move the assignment
              // to the end of the the for loop
                std::vector<std::string>::iterator it = code.end();
                pos.push_back(--it);}
          id_assign_ext {$$=$5;}
          
          ;


for_assign : id_assign // can be an assignment
            | a_id  // or just a variable
            ;

id_assign_ext : increment // can be an increment
              | id_assign // or an assignment
              ;


id_assign : a_id ASSIGN_OP expr {
  if($1.reg == -1 || $3.reg == -1){
    error("Unexpected error"); // checks whether the registers are a valid value
  }

  if($1.reg<4){ // this happens only for function arguments
    type_compare($1.reg,$3.reg); // compares the types of the LHS and the RHS
    // Moves the value into the register
    code.push_back( "MOV r" + convert<std::string>($1.reg) + ", r" + convert<std::string>($3.reg));
  } else {
    type_compare($1.reg,$3.reg); // compares the types of the LHS and the RHS
    std::string str1 = convert<std::string>($1.reg), str2 = convert<std::string>($3.reg);
    // The LHS contains the address of the variable, since this is not a function argument
    // We store the value into the address
    code.push_back( "STR r" + str2 + ", [r" + str1 + "]" );
  }
}
;


/////////////////////////////////////////STATEMENTS///////////////////////////////////////////


// Statements to be executed
line   : BREAK EOL
        |  expr line_p EOL {
          // Line_p is optional, if it is there ($2.d is not empty), perform a comparison
          if($2.d != ""){
            type_compare($1.reg,$2.reg);
            code.push_back( "CMP r" + convert<std::string>($1.reg) + ", r" + convert<std::string>($2.reg) );
            Var* temp = new Var(convert<std::string>(regn), $1.d, regn);
            tempvar.push_back(temp);
            code.push_back( "MOV" + select_cond($1.d) + "r"+convert<std::string>(save_reg(temp)) + ", #1" );
          }
        }
       | a_id ASSIGN_OP expr EOL {
        if($1.reg == -1 || $3.reg == -1){
          error("Unexpected error"); // checks whether the registers are a valid value
        }
        if($1.reg<4){ // this happens only for function arguments
          type_compare($1.reg,$3.reg); // compares the types of the LHS and the RHS
          // Moves the value into the register
          code.push_back( "MOV r" + use() + ", r" + use());
        } else {
          type_compare($1.reg,$3.reg); // compares the types of the LHS and the RHS
          // The LHS contains the address of the variable, since this is not a function argument
          // We store the value into the address
          std::string str1 = convert<std::string>($3.reg), str2 = convert<std::string>($1.reg);
          code.push_back( "STR r" + str1 + ", [r" + str2 + "]" );
        }
        }
       | newvar assign {
         if($2.d != ""){
          if($2.reg != -1 && $1.reg != -1){
            // Store value into variable address
            type_compare($1.reg,$2.reg);
            code.push_back( "STR r" + convert<std::string>($2.reg) + ", [r" + convert<std::string>($1.reg) + "]");
            stack.pop_back();

          } else {
           error("Unexpected register error");
         }
       }
       } assign_cont
       {
        
        bool isPtr = false;   
        if($1.val == "ptr"){
         isPtr = true; // sets a flag to save the variables as pointers
        }

        // Gets all variables saved into stack, and stores them into the variable multimap
       for (std::vector<DataInt*>::iterator it=stack.begin(); it!=stack.end(); ++it){
        Var* tt = (Var*) (*it);   
        if(!findvar((*it)->name), scope){ // checks whether the variable already exists
          Var* temp = new Var(tt->name, $1.d, tt->reg, tt->lbl, isPtr);
          varl.insert(std::pair<int,DataInt*>(scope, temp));
        } else {
          error("Variable already defined");
        }
      }

      stack.erase(stack.begin(), stack.end()); // erases the stack
      } 
       | loop
       | select
       | func_body
       | RETURN return_param EOL {
        if(currentFunc!=NULL){ // if not in main, check the type of the return is correct
          type_compare(currentFunc->type, $2.d);
        } else {
          type_compare("int", $2.d); // if in main, compare with int
        }

        if($2.d != "void"){ // if not a void return, move a value into the return register
          code.push_back( "MOV r0, r" + convert<std::string>($2.reg));
        }

        if(currentFunc!=NULL){
          currentFunc->hasReturned=1; // set a flag that the functions has returned
          code.push_back( "LDMFD sp!, {r4-r12, pc}" );
        } else {
          code.push_back( "LDMFD sp!, {pc}" );
        }
      }
       ;

return_param : expr
              |{$$.d = "void";} // void if just return, with no parameter
              ;

// comparison optional
line_p : {$$.d = "";}
       | comp_op expr {$$ = $2;}
       ;

// List of variable declaration
assign_cont : COMMA varlist {$$ = $2;}
            | EOL
            ;

varlist : decl_id assign {
                  // if there was an assignment, store value into variable address
                  if($2.d!=""){
                  stack.pop_back();
                  type_compare($1.reg, $2.reg);
                  code.push_back( "STR r" + convert<std::string>($2.reg) + ", [r" + convert<std::string>($1.reg) + "]");
                  }
                  }COMMA varlist 
        | decl_id assign EOL {
                  // if there was an assignment, store value into variable address
                  if($2.d!=""){
                  stack.pop_back();
                  type_compare($1.reg, $2.reg);
                  code.push_back( "STR r" + convert<std::string>($2.reg) + ", [r" + convert<std::string>($1.reg)+ "]");
                  }
                  }
        ;

// assignment is optional
assign : ASSIGN_OP expr {$$ = $2;}
	     | {$$.d=""; $$.reg = -1;}
	;


//////////////////////////////////////////EXPRESSIONS//////////////////////////////////////////


expr   : expr ad_sub_or term {
        $$ = $1;
        stack.pop_back(); // removes the last two elements of the stack
        stack.pop_back();
      	//type_compare($1.reg,$3.reg); // compare types
        std::string reg_n = convert<std::string>(regn);
        std::string reg = convert<std::string>($1.reg);
        Var* temp = new Var(reg_n, $1.d, regn); // declare a new tempvar to store the operation

        // if any of the two are function arguments, do not store the result of the addition in them
        // to avoid overwriting of the values
        if($1.reg < 4){
          if($3.reg < 4){ // if both are function arguments, store addition in a new register
          reg = reg_n;
          save_reg(temp);
          tempvar.push_back(temp);
          stack.push_back(temp);
          } else {
          reg = convert<std::string>($3.reg);
          } 
        } 

        $$.reg = c_int(reg);

        // different ARM instructions depending on operator
        if ($2.d == "+"){
          code.push_back( "ADD r" + reg + ", r" + convert<std::string>($1.reg) + ", r" + convert<std::string>($3.reg) );
          $$.val = convert<std::string>(c_int($1.val) + c_int($3.val)); // return value of expr
        } else if($2.d == "-"){
          code.push_back( "SUB r" + reg + ", r" +convert<std::string>($1.reg)+ ", r" + convert<std::string>($3.reg));
          $$.val = convert<std::string>(c_int($1.val) - c_int($3.val)); // return value of expr
        } else {
          code.push_back( "ORR "+ reg + ", r" +convert<std::string>($1.reg)+ ", r" + convert<std::string>($3.reg) );
          $$.val = convert<std::string>(c_int($1.val) | c_int($3.val)); // return value of expr
        }
      }
       | middle
       ;

middle : expr BIT_XOR term {
          $$ = $1;
          //type_compare($1.reg,$3.reg); // compare types
        	stack.pop_back(); // removes the last two elements of the stack
          stack.pop_back();

          std::string reg_n = convert<std::string>(regn);
          Var* temp = new Var(reg_n, $1.d, regn);  // declare a new tempvar to store the operation

          std::string reg = convert<std::string>($1.reg);
          // if any of the two are function arguments, do not store the result of the addition in them
          // to avoid overwriting of the values
            if($1.reg < 4){
            if($3.reg < 4){ // if both are function arguments, store addition in a new register
              reg = reg_n;
              save_reg(temp);
              tempvar.push_back(temp);
              stack.push_back(temp);
            } else {
              reg = convert<std::string>($3.reg);
            } 
          } 
          $$.reg = c_int(reg);
          code.push_back( "XOR r" + reg + ", r" + convert<std::string>($1.reg) + " , r" + convert<std::string>($3.reg) );
          $$.val = convert<std::string>(c_int($1.val) ^ c_int($3.val)); // return value of expr
        }
        | term
        ;

term   : term mul_div_and factor {
          $$ = $1;
          //type_compare($1.reg,$3.reg); // compare types
        	stack.pop_back(); // remove the last two elements of the stack
          stack.pop_back();

          std::string reg_n = convert<std::string>(regn);
          Var* temp = new Var(reg_n, $1.d, regn); // declare a new tempvar to store the operation

          std::string reg = convert<std::string>($1.reg);
          // if any of the two are function arguments, do not store the result of the addition in them
          // to avoid overwriting of the values
            if($1.reg < 4){
            if($3.reg < 4){ // if both are function arguments, store addition in a new register
              reg = reg_n;
              save_reg(temp);
              tempvar.push_back(temp);
              stack.push_back(temp);
            } else {
              reg = convert<std::string>($3.reg);
            } 
          } 

         $$.reg = c_int(reg);

          if ($2.d == "*"){
            code.push_back( "MUL r" + reg + ", r" + convert<std::string>($1.reg) + " , r" + convert<std::string>($3.reg) );
            $$.val = convert<std::string>(c_int($1.val) * c_int($3.val));
          } else if($2.d == "/"){
            warning("Division not implemented");
            //code.push_back( "DIV r" + reg + ", r" +convert<std::string>($1.reg)+ " , r" + convert<std::string>($3.reg));
            $$.val = convert<std::string>(c_int($1.val) / c_int($3.val));
          } else if ($2.d == "%"){
            code.push_back( "MOD r" + reg + ", r" +convert<std::string>($1.reg)+ " , r" + convert<std::string>($3.reg));
            $$.val = convert<std::string>(c_int($1.val) % c_int($3.val));
          } else if ($2.d == "&"){
            code.push_back( "AND r"+ reg + ", r" +convert<std::string>($1.reg)+ " , r" + convert<std::string>($3.reg) );
            $$.val = convert<std::string>(c_int($1.val) & c_int($3.val));
          } else if ($2.d == "<<"){
           code.push_back( "MOV r"+ reg + ", r" +convert<std::string>($1.reg)+ " , lsl r" + convert<std::string>($3.reg) );
           $$.val = convert<std::string>(c_int($1.val) << c_int($3.val));
         } else {
           code.push_back( "MOV r"+ reg + ", r" +convert<std::string>($1.reg)+ " , lsr r" + convert<std::string>($3.reg) );
           $$.val = convert<std::string>(c_int($1.val) >> c_int($3.val));
         }

        }
       | factor
       ;

factor : LBRACKET expr RBRACKET { $$.d = $2.d;}
       | type
       | BIT_NOT type 
          {$$.d = $2.d;
          code.push_back( "MVN r"+ convert<std::string>($2.reg) + ", r" +convert<std::string>($2.reg));
          $$.val = convert<std::string>(!c_int($2.val));
          }

       ;

// Types of arguments in an expression
type : FLOAT {$$.d = "float"; $$.val = lexer.YYText();
        warning("Floats not implemented");
      }
      | STRING {$$.d = "string";

       // Saves string into memory
       std::string txt = "string"+convert<std::string>(lbld);
       $$.lbl = txt+"_str";
       std::string str = lexer.YYText();

       Var* temp = new Var(convert<std::string>(regn), "string", regn);
       tempvar.push_back(temp);
       $$.reg = save_reg(temp);

       data.insert(data.begin(), "");
       data.insert(data.begin(), txt+":\t.word " + txt+"_str");

       data.push_back(txt+"_str:\t.asciz "+ str);
       data.push_back("");

       // Loads the memory address into a register
       code.push_back( "LDR r" + convert<std::string>(temp->reg) + ", " + txt );


       stack.push_back(temp);
       lbld++; // increases the label counter
       $$.val = lexer.YYText();
     }
     | int { 

      $$.d = $1.d;
      // Moves the value into a register
      Var* temp = new Var(convert<std::string>(regn), $1.d, regn);
      $$.reg = save_reg(temp);
      tempvar.push_back(temp);
      stack.push_back(temp);
      code.push_back( "MOV r" + temp->name + ", #" + $1.lbl );
      $$.val = $1.lbl;
    }
    | func_call {
      // Moves the return value into a register
      // If function returns a pointer, set the flag that value is a pointer
      $$ = $1;
      Var* temp;
      if ($1.lbl == ""){
        temp = new Var(convert<std::string>(regn), $1.d, regn);
      } else {
       temp = new Var(convert<std::string>(regn), $1.d, regn, "", true);
      }
     $$.reg = save_reg(temp);
     tempvar.push_back(temp);
     code.push_back( "MOV r" + convert<std::string>(temp->reg) + ", r0");
     stack.push_back(temp);


   }
   | extended_id
   | CHAR  {
     $$.d = "char";
     std::string txt = "char"+convert<std::string>(lbld);
     $$.lbl = txt+"_str";

    // Saves char into memory
     Var* temp = new Var(lexer.YYText(), "char", regn);
     $$.reg = save_reg(temp);
     tempvar.push_back(temp);

     data.insert(data.begin(), "");
     data.insert(data.begin(), txt+":\t.word " + txt+"_str");

     data.push_back(".balign 1");
     data.push_back(txt+"_str:\t.byte "+convert<std::string>(lexer.YYText()));
     data.push_back("");

     // Load char into a register
     code.push_back( "LDR r" + convert<std::string>(temp->reg) + ", " + txt );
     code.push_back( "LDR r" + convert<std::string>(temp->reg) + ", [r" + convert<std::string>(temp->reg) + "]");

     stack.push_back(temp);
     lbld++;
     $$.val = lexer.YYText();

 }

 ;

int : adsub un_int {$$.d = "int"; $$.lbl = $1.d + $2.d;}
    | un_int {$$.d = "int"; $$.lbl = $1.d;}
    | SIZEOF LBRACKET id RBRACKET { 
      $$.d = "int"; // type of size is int
      if($3.d == "void"){
	    $$.lbl = "1"; // size of void is 1
      }
      $$.lbl = convert<std::string>(get_types($3.d)); // gets the size of the type
                                                      // and returns it as $$.lbl
    }
    ;

un_int : UN_INT {$$.d = lexer.YYText();}
        ;

id: ID {$$.d = lexer.YYText();}
    ;

param :	newvar
	    | expr 
	    ;


// Incrementing an lvalue, for 'for' loops

increment : incdec a_id {
    $$ = $2; 
    // Loads value of variable into a register
    // Adds/subs one, and then stores the value again
    // Returns the incremented value
    if($1.d == "++"){
      Var* temp = new Var(convert<std::string>(regn), $2.d, regn);
      code.push_back("LDR r" + convert<std::string>(regn) + ", [r" + use() + "]");
      code.push_back( "ADD r" + convert<std::string>(regn) + ", r" + convert<std::string>(regn) + ", #1" );
      code.push_back( "STR r" + convert<std::string>(regn) + ", [r" + convert<std::string>($2.reg) +"]");
      tempvar.push_back(temp);
      save_reg(temp);
    } else {
              Var* temp = new Var(convert<std::string>(regn), $2.d, regn);
      code.push_back("LDR r" + convert<std::string>(regn) + ", [r" + use() + "]");
      code.push_back( "SUB r" + convert<std::string>(regn) + ", r" + convert<std::string>(regn) + ", #1" );
      code.push_back( "STR r" + convert<std::string>(regn) + ", [r" + convert<std::string>($2.reg) +"]");
      tempvar.push_back(temp);
      save_reg(temp);
    }
            }
    | a_id incdec {$$=$1;
    // Loads value of variable into a register
    // Adds/subs one, and then stores the value again
    if($2.d == "++"){
      Var* temp = new Var(convert<std::string>(regn), $1.d, regn);
      code.push_back("LDR r" + convert<std::string>(regn) + ", [r" + use() + "]");
      code.push_back( "ADD r" + convert<std::string>(regn) + ", r" + convert<std::string>(regn) + ", #1" );
      code.push_back( "STR r" + convert<std::string>(regn) + ", [r" + convert<std::string>($1.reg) +"]");

    } else {
      Var* temp = new Var(convert<std::string>(regn), $1.d, regn);
      code.push_back("LDR r" + convert<std::string>(regn) + ", [r" + use() + "]");
      code.push_back( "SUB r" + convert<std::string>(regn) + ", r" + convert<std::string>(regn) + ", #1" );
      code.push_back( "STR r" + convert<std::string>(regn) + ", [r" + convert<std::string>($1.reg) +"]");

  }
}
;


//////////////////////////////////////////COMPARISONS//////////////////////////////////////////


// A bool comparison can be only one comparison statement
// Or a series of them
bool_check : bool bool_op {
             $1.reg = regn;

              // Save a register, and set it to 1 if the condition is true
             Var* temp = new Var(convert<std::string>(regn), "int", regn);
             tempvar.push_back(temp);
             code.push_back( "MOV" + select_cond($1.d) + "r"+convert<std::string>(save_reg(temp)) + ", #1" ); 
            }
            bool_check
            {
              // Save a register, and set it to 1 if the condition is true
              Var* temp = new Var(convert<std::string>(regn), "int", regn);
              tempvar.push_back(temp);
              code.push_back( "MOV" + select_cond($4.d) +"r" + convert<std::string>(save_reg(temp)) + ", #1" );
              save_reg(temp);
              tempvar.push_back(temp);

              // Depending on operator, AND/OR the two registers that were set to 1
              if($2.d == "||"){
                code.push_back( "ORR r" + convert<std::string>(regn) + ", r"+ convert<std::string>($1.reg) +  ", r" + temp->name );
              } else {
                code.push_back( "AND r" + convert<std::string>(regn) + ", r"+ convert<std::string>($1.reg) +  ", r" + temp->name );
              }

              // Compare the result with 1. If 1, both conditions are held
              code.push_back( "CMP r" + convert<std::string>(regn) + ", #1" );
              tempvar.push_back(temp);
              save_reg(temp);
              $$.d = "==";
            }
            | bool
;  

bool: param {
            // Having only one parameter is equivalent to doing 'param != 0'
            code.push_back( "CMP r" + convert<std::string>($1.reg) + ", #0");
            $$.d = "!=";
            }
	   | param comp_op param {
            // Compare the two parameters
            code.push_back( "CMP r" + convert<std::string>($1.reg) + ", r" + convert<std::string>($3.reg) );
            $$ = $2;
            }
	   ;



///////////////////////////////////VARIABLE DECLARATION////////////////////////////////////////

newvar : id id {

    $$.d = $1.d;
    if(type_check($1.d)){ // check whether the type exists
    if (type_isPointer($1.d)){ // if type is a pointer, set a flag
      $$.val = "ptr";
    }

    std::string txt = "var"+convert<std::string>(lbld);
    $$.lbl = txt+"_addr";
    Var* temp = new Var($2.d, $1.d, regn, $$.lbl, type_isPointer($1.d));
    if(!findvar(temp->str(), scope)){ // if the variable hasn't already been declared in this scope

      // Save the variable into memory, creating labels for the address and the actual value
      data.insert(data.begin(), "");
      data.insert(data.begin(), txt+"_addr:\t.word " + txt);

      // Select the size to save into memory with balign
      // Get the size of the type with get_types()
      data.push_back(".balign "+convert<std::string>(get_types($1.d)));
      data.push_back(txt+":\t.word 0");
      lbld++;
      data.push_back("");

      // Insert into the variable multimap
      varl.insert(std::pair<int,DataInt*>(scope, temp));
      $$.reg = save_reg(temp);
      stack.push_back(temp);

      // Load the address of the variable into a register
      code.push_back( "LDR r" + convert<std::string>($$.reg) + ", " + $$.lbl);

    } else {
      error("Variable already declared");
    }

  }
  }
      | id id LSQUARE expr RSQUARE {
    $$.d = $1.d;
    $$.val = "ptr"; // set a flag to say it's a pointer
    if(type_check($1.d)){ // check whether type exists
;
    std::string txt = "var"+convert<std::string>(lbld);
    $$.lbl = txt+"_addr";
    Var* temp = new Var($2.d, $1.d, regn, $$.lbl, true);
    if(!findvar(temp->str(), scope)){ // if variable hasn't already been declared in this scope

      // Save the variable into memory, creating labels for the address and the actual value
      data.insert(data.begin(), "");
      data.insert(data.begin(), txt+"_addr:\t.word " + txt);

      data.push_back(".balign "+convert<std::string>(get_types($1.d))); // make the size change depending on type, ok?

      // Skip the number of bytes*4 of the expression inside the square brackets
      data.push_back(txt+":\t.skip "+ convert<std::string>(4*c_int($4.val)));
      data.push_back("");
      lbld++;

      // Insert variable into variable map
      varl.insert(std::pair<int,DataInt*>(scope, temp));
      $$.reg = save_reg(temp);
      stack.pop_back();
      stack.push_back(temp);

      // Load the address of the variable into a register
      code.push_back( "LDR r" + convert<std::string>($$.reg) + ", " + $$.lbl);

    } else {
      error("Variable already declared");
    }

  }
  }
      | id PTR id {
     $$.val = "ptr"; // set a flag to say it's a pointer
    $$.d = $1.d;
    if(type_check($1.d)){

    std::string txt = "var"+convert<std::string>(lbld);
    $$.lbl = txt+"_addr";
    Var* temp = new Var($3.d, $1.d, regn, $$.lbl, true);
    if(!findvar(temp->str(), scope)){ 

      // Save the variable into memory, creating labels for the address and the actual value
      data.insert(data.begin(), "");
      data.insert(data.begin(), txt+"_addr:\t.word " + txt);

      data.push_back(".balign 4"); // size of addresses is always 4 bytes
      data.push_back(txt+":\t.word 0");
      data.push_back("");
      lbld++;

      // Insert variable into variable map
      varl.insert(std::pair<int,DataInt*>(scope, temp)); 
      $$.reg = save_reg(temp);
      stack.push_back(temp);

      // Load the address of the variable into a register
      code.push_back( "LDR r" + convert<std::string>($$.reg) + ", " + $$.lbl);

    } else {
      error("Variable already declared");
    }

  }
  }
      ;


funcvar : id id {
    $$.d = $1.d;
    if(type_check($1.d)){ // check whether type exists

    // type_isPointer gets whether the type is a pointer type
    Var* temp = new Var($2.d, $1.d, lblcc, "", type_isPointer($1.d));
    if(!findvar(temp->str())){ // find whether variable has already been declared
      
      // inserts variable into map and saves a register
      varl.insert(std::pair<int,DataInt*>(scope, temp));

      // variable is stored in register lblcc, which starts at 0 and increases
      // with every function argument
      $$.reg = save_reg(temp, lblcc);
      stack.push_back(temp);
      lblcc++;
    } else {
      error("Variable already declared");
    }
        }

    }
    | id PTR id {

    $$.d = $1.d;
    if(type_check($1.d)){ // check whether type exists
    Var* temp = new Var($3.d, $1.d, lblcc, "", true); // is a pointer
    if(!findvar(temp->str())){ // find whether variable has already been declared
      
      // inserts variable into map and saves a register
      varl.insert(std::pair<int,DataInt*>(scope, temp));
      
      // variable is stored in register lblcc, which starts at 0 and increases
      // with every function argument
      $$.reg = save_reg(temp, lblcc);
      stack.push_back(temp);
      lblcc++;
    } else {
      error("Variable already declared");
    }
  }
  }
        | id id LSQUARE expr RSQUARE {
    $$.d = $1.d;
    if(type_check($1.d)){ // check whether type exists
    Var* temp = new Var($2.d, $1.d, lblcc, "", true); // is a pointer
    if(!findvar(temp->str())){ // find whether variable has already been declared
      
      // inserts variable into map and saves a register
      varl.insert(std::pair<int,DataInt*>(scope, temp));
      
      // variable is stored in register lblcc, which starts at 0 and increases
      // with every function argument
      $$.reg = save_reg(temp, lblcc);
      stack.push_back(temp);
      lblcc++;
    } else {
      error("Variable already declared");
    }
    }

    }
        ;


// Used for variable lists, when you have to declare variables
// you dont know the type of yet

decl_id : id {
  $$.d = $1.d;
  std::string txt = "var"+convert<std::string>(lbld);
  $$.lbl = txt+"_addr";
  Var* temp = new Var($1.d, "", regn, $$.lbl);
  if(!findvar(temp->str())){ // checks whether variable has already been declared

    // The last element inserted into the stack has the type of the current variable
    std::string tt = (stack.back())->type;
    temp->type = tt;

    $$.reg = save_reg(temp);
    stack.push_back(temp);

    // Creates labels to store the variable in memory
    data.insert(data.begin(), "");
    data.insert(data.begin(), txt+"_addr:\t.word " + txt);

    data.push_back(".balign " + convert<std::string>(get_types(tt)));
    data.push_back(txt+":\t.word 0");
    data.push_back("");
    lbld++;

    // Load the address of the variable into a register
    code.push_back( "LDR r" + convert<std::string>($$.reg) + ", " + $$.lbl);
  } else {
    error("Variable already declared");
  }

}
        ;


//////////////////////////////////////VARIABLE USE/////////////////////////////////////////////


extended_id : incdec s_id {$$ = $2;
          // In the RHS of the expression, the value of the variable itself is loaded into a register
          // Not only its address, which is the only thing that is loaded on the LHS

          // add one to the value in the register
          // and store it into the variable by getting the register the address is stored in, using the label
          if($1.d == "++"){
            code.push_back( "ADD r" + convert<std::string>($2.reg) + ", r" + convert<std::string>($2.reg) + ", #1" );
            code.push_back( "STR r" + convert<std::string>($2.reg) + ", [r" + convert<std::string>(getlbl_reg($2.lbl))+"]");
          } else {
            code.push_back( "SUB r" + convert<std::string>($2.reg) + ", r" + convert<std::string>($2.reg) + ", #1" );
            code.push_back( "STR r" + convert<std::string>($2.reg) + ", [r" + convert<std::string>(getlbl_reg($2.lbl))+"]");
          }
        }
        | s_id incdec {$$=$1;
          // add one to the value in the register
          // and store it into the variable by getting the register the address is stored in, using the label
          // this returns the value before the increment
          if($2.d == "++"){
            code.push_back( "ADD r" + convert<std::string>(regn) + ", r" + convert<std::string>($1.reg) + ", #1" );
            code.push_back( "STR r" + convert<std::string>(regn) + ", [r" + convert<std::string>(getlbl_reg($1.lbl))+"]");
          } else {
            code.push_back( "SUB r" + convert<std::string>(regn) + ", r" + convert<std::string>($1.reg) + ", #1" );
            code.push_back( "STR r" + convert<std::string>(regn) + ", [r" + convert<std::string>(getlbl_reg($1.lbl))+"]");
          }
        }
        | PTR s_id {$$ = $2;

        // If variable is a pointer, loads into a register
        // the variable whose address is stored into s_id
          if(isPointer($2.reg)){
            Var* temp = new Var(convert<std::string>(regn), $2.d, regn);
            code.push_back( "LDR r" + temp->name + ", [r" + use() + "]");
            tempvar.push_back(temp);
            stack.pop_back();
            stack.push_back(temp);
            $$.reg = save_reg(temp);
          }
        }

        | BIT_AND s_id {$$ = $2; $$.d = "int";

        // Loads the address of a variable into a register
        Var* temp = new Var(convert<std::string>(regn), "int", regn, "", true);
        $$.reg = save_reg(temp);
        code.push_back( "LDR r" + temp->name + ", " +  $2.lbl);
        tempvar.push_back(temp);
        stack.push_back(temp);

        }

      | s_id
      ;


//------RHS variables---------//

// For operations with variables in the RHS of an equation, the value of the variable itself
// has to be loaded into a register


s_id : id {
          std::string temp_type = get_type($1.d); // gets type of the variable using its name
          int reg = get_reg($1.d); // gets register of the variable using its name
          $$.lbl = get_lbl(reg); // gets label of the variable using its register
          
          if(reg<4){ // if register is r0-r3, this is a function argument and variable does not need to be loaded
          Var* temp = new Var(convert<std::string>(reg), temp_type, reg, $$.lbl, get_isPointer(reg));
          tempvar.push_back(temp);
          $$.reg = reg;

          stack.push_back(temp);
          } else if(get_inReg($1.d)){ // else, if the variable is in a register, load value of the variable 
                                      // from the register its address is stored in
          Var* temp = new Var(convert<std::string>(regn), temp_type, regn, $$.lbl, get_isPointer(reg));
          tempvar.push_back(temp);
          code.push_back( "LDR r" + convert<std::string>(regn) + ", [r" + convert<std::string>(reg) + "]");
          $$.reg = regn;
          save_reg(temp);
          stack.push_back(temp);

          } else { // if it's not in a register, save in a register, and then load both address and value
          set_inReg($1.d);
          Var* temp = new Var(convert<std::string>(regn), temp_type, regn, $$.lbl, get_isPointer(reg));
          code.push_back( "LDR r" + convert<std::string>(regn) + ", " + $$.lbl);
          code.push_back( "LDR r" + convert<std::string>(regn) + ", [r" + convert<std::string>(regn) + "]");
          
          tempvar.push_back(temp);
          stack.push_back(temp);
          $$.reg = regn;
          save_reg(temp);
          }
          $$.d = temp_type;
          $$.val = get_val(reg);
        
        }
      | id LSQUARE expr RSQUARE {
          std::string temp_type = get_type($1.d); // gets type of the variable using its name
          int reg = get_reg($1.d); // gets register of the variable using its name
          $$.lbl = get_lbl(reg); // gets label of the variable using its register
          isPointer(reg); // gets whether the variable is a pointer, returns an error if false
          stack.pop_back(); // removes the expr from the stack
          
          if(reg<4){ // if register is r0-r3, this is a function argument and variable does not need to be loaded
          Var* temp = new Var(convert<std::string>(regn), temp_type, reg, $$.lbl);
          tempvar.push_back(temp);
          $$.reg = reg;

          stack.push_back(temp);
          } else if(get_inReg($1.d)){ // else, if the variable is in a register, load value of the variable 
                                      // from the register its address is stored in
          Var* temp = new Var(convert<std::string>(regn), temp_type, regn, $$.lbl);

          // Address is offset by an amount expr multiplied by 4 (to get number of bytes)
          code.push_back( "LDR r" + convert<std::string>(regn) + ", [r" + convert<std::string>(reg) + ", r" + use() + ", lsl #2]");
          tempvar.push_back(temp);
          $$.reg = regn;
          save_reg(temp);

          stack.push_back(temp);
          } else { // if it's not in a register, save in a register, and then load both address and value
          set_inReg($1.d);
          Var* temp = new Var(convert<std::string>(regn), temp_type, regn, $$.lbl);
          code.push_back( "LDR r" + convert<std::string>(regn) + ", " + $$.lbl);

          // Address is offset by an amount expr multiplied by 4 (to get number of bytes)
          code.push_back( "LDR r" + convert<std::string>(regn) + ", [r" + convert<std::string>(regn) + ", r" + use() + ", lsl #2]");
          tempvar.push_back(temp);
          stack.push_back(temp);
          $$.reg = regn;
          save_reg(temp);
          }
          $$.d = temp_type;
          $$.val = get_val(reg);
        
        }
;

//------LHS variables---------//

// For operations with variables in the LHS of an equation, there is no need to load
// the value of the variable into a register
// it is only necessary to load the address (if it has not been previously loaded)

a_id :   PTR a_id {$$ = $2;
          if(isPointer($2.reg)){ // if variable is not a pointer, returns error
          Var* temp = new Var(convert<std::string>(regn), $2.d, regn);
          // Loads the value of the variable into a new register
          // Since variable is a pointer, its value will be the address of another variable
          code.push_back( "LDR r" + temp->name + ", [r" + convert<std::string>($2.reg) + "]");
          
          $$.reg = save_reg(temp);
          tempvar.push_back(temp);
          stack.push_back(temp);
          }
        }

        |  id {
          std::string temp_type = get_type($1.d); // gets type of the variable using its name
          int reg = get_reg($1.d); // gets register of the variable using its name
          $$.lbl = get_lbl(reg); // gets label of the variable using its register

          
          if(reg<4){ // if variable is a function argument, no loading has to be done
          Var* temp = new Var(convert<std::string>(reg), temp_type, reg, $$.lbl, get_isPointer(reg));
          tempvar.push_back(temp);
          $$.reg = reg;
          } else if(get_inReg($1.d)){ // if variable is not a fung arg, but its address is already
                                      // loaded into a register, no loading has to be done
          $$.reg = reg;
          Var* temp = new Var(convert<std::string>($$.reg), temp_type, reg, $$.lbl, get_isPointer(reg));
          tempvar.push_back(temp);
          } else { // else, load address into a register, and set that the variable is in a register
          $$.reg = regn;
          set_inReg($1.d);
          Var* temp = new Var(convert<std::string>($$.reg), temp_type, regn, $$.lbl, get_isPointer(reg));
          code.push_back( "LDR r" + convert<std::string>($$.reg) + ", " + $$.lbl);
          }

          $$.d = temp_type;

        }
        | id LSQUARE expr RSQUARE {
          std::string temp_type = get_type($1.d); // gets type of the variable using its name
          int reg = get_reg($1.d); // gets register of the variable using its name
          $$.lbl = get_lbl(reg); // gets label of the variable using its register
          isPointer(reg); // gets whether the variable is a pointer, returns an error if false
          
          // if variable is a func arg, or its address is already in a register,
          // we just add an offset to the address, 4 times the amount of expression
          if(reg<4 || get_inReg($1.d)){
          Var* temp = new Var(convert<std::string>(regn), temp_type, regn, $$.lbl);
          code.push_back( "ADD r" + convert<std::string>(regn) + ", r" + convert<std::string>(reg) + ", r" + use() + ", lsl #2");
          tempvar.push_back(temp);
          stack.push_back(temp);
          $$.reg = regn;
          save_reg(temp);

          // else, load the address and apply the offset to it
          } else {
          code.push_back( "LDR r" + convert<std::string>(regn) + ", " + $$.lbl);
          set_inReg($1.d);
          Var* temp = new Var(convert<std::string>(regn), temp_type, regn, $$.lbl);
          code.push_back( "ADD r" + convert<std::string>(regn) + ", r" + convert<std::string>(regn) + ", r" + use() + ", lsl #2");
    
          tempvar.push_back(temp);
          stack.push_back(temp);
          $$.reg = regn;
          save_reg(temp);
          }

          $$.d = temp_type;
          $$.val = get_val(reg);
        
        }
;


///////////////////////////////////OPERATORS//////////////////////////////////////////////////

ad_sub_or : adsub
          | BIT_OR {$$.d = lexer.YYText();}
          ;

adsub : ADSUB_OP {$$.d = lexer.YYText();}
      ; 

mul_div_and : muldiv
            | BIT_AND {$$.d = lexer.YYText();}
            | INSERT_OP {$$.d = lexer.YYText();}
            ;

muldiv:  MULDIV_OP {$$.d = lexer.YYText();}
       // | PTR {$$.d = lexer.YYText();} // uncomment for multiplication
                                         // not working at the moment
      ;    

bool_op : BOOL_OP {$$.d =lexer.YYText();}
        ;

comp_op : COMP_OP {$$.d = lexer.YYText();}
        ;

incdec : INCDEC_OP {$$.d = lexer.YYText();}
       ;