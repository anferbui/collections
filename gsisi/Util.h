#ifndef UTIL_H
#define UTIL_H

#include <sstream>

// The return type used for the grammar
class Return {
    public:
      Return(std::string t="", int r =-1, std::string label="", std::string v=""):d(t), reg(r), lbl(label), val(v){}
      std::string d; // general description, used for type
      int reg; // register, if it applies
      std::string lbl; // label, if it applies
      std::string val; // value, if it applies

};


template<typename T, typename T2>
T convert(const T2& in)
{
    std::stringstream buf;
    buf << in;
    T result;
    buf >> result;
    return result;
}

#endif // UTIL_H
