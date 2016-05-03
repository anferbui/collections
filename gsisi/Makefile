# each line of the Makefile is a rule 

# the first rule is executed if we don't specify a label:
# in this case we can execute the rule calc either as 
# make calc
# or as just
# make

gsisi: parse.o lex.yy.o c.o
	g++ -o gsisi c.o parse.o lex.yy.o 
	
# each rule has on the left hand side of the colon the target (what we want to achieve)
# and on the rhs the list of dependencies needed in order to achieve it

# right afterwards (always preceded by a tab) there is the command
# which achieves the result 

# (compare this structure with BNF grammars)

# for instance in order to obtain the executable calc
# we need the .o files of each of the components... 

parse.o: parse.cc Parser.h
	g++ -c parse.cc
	
# ...and we obtain each .o file compiling each source file with the option -c

# the idea is that the rule related to a dependency is triggered only
# if the dependency doesn't exist or has changed since the last time

# for instance if we call make, afterwards we change only the main in calc.cpp 
# (dependency for calc.o) and finally we call make again, 
# parse.cc and lex.yy.cc are not compiled again  in order to obtain
# the respective .o (because they haven't changed)

lex.yy.o: lex.yy.cc Parserbase.h
	g++ -c lex.yy.cc
	
c.o: c.cpp Parser.h Util.h
	g++ -c c.cpp
	
Parserbase.h: parse.cc

parse.cc : c.y
	bisonc++ c.y
	
# sometimes it's not a matter of compiling:
# we get the source parse.cc from bisonc++
	
lex.yy.cc: c.l
	flex++ c.l 
	
# make clean 
# executes this rule which deletes the generated files

clean:
	rm -f lex.yy.cc parse.cc Parserbase.h Parser.ih *.o gsisi
