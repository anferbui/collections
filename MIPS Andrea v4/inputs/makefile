SIM_AUX_SOURCES := $(wildcard ../mips_simulator_*.c) $(wildcard ../mips_simulator_*.cpp)
SIM_OBJECTS := ../mips_simulator.o $(subst .c,,$(subst .cpp,,$(SIM_AUX_SOURCES)))

# This sets the include directory to pick up mips.h from the driver program
CPPFLAGS += -I..
CC = g++
# Turn on all warnings
CPPFLAGS += -W -Wall

ifeq ($(OS),Windows_NT)
# Needed to bring in endian-ness conversion on MinGW
LDLIBS += -lws2_32
endif


%_driver : %_driver.o $(SIM_OBJECTS)
	$(CC) -o $@ $(LDFLAGS) $^ $(LDLIBS)

%_run : %_driver
	./$*_driver

# Will build then run all the test programs
all : t6_driver t7_driver t8_driver t9_driver t10_driver t11_driver t12_driver
	./t6_driver
	./t7_driver
	./t8_driver
	./t9_driver
	./t10_driver
	./t11_driver
	./t12_driver
