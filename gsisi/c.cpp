#include <iostream>
#include "Parser.h"

using namespace std;

int main(){
    Parser p;
    p.parse();
    p.printC(); // prints the code
    return 0;
}
