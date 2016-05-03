#include "mips.h"

#include "driver_helper.h"

// This is the function which the simulator is running
#include "t7_input.c"

using namespace std;

int main(int argc,char *argv[])
{	
	unsigned i;
	
	if(argc>2){
		fprintf(stderr, "Usage: %s [file.bin]\n", argv[0]);
		exit(1);
	}
	
	unsigned cbMem=1<<20;
	uint8_t *pMem=(uint8_t*)malloc(cbMem);
	
	Driver_LoadInstructions(argc>1 ? argv[0] : "t7_input-mips.bin", (uint32_t*)pMem);
	
	struct mips_state_t *state=mips_create(
		0,	// pc
		cbMem,
		pMem
	);
	
	int fail=0;
	
	for(i=0;i<100;i++){
		uint32_t a=rand(), b=rand(), c =rand(), res_correct, res_sim;
		
		// Run the program from the beginning
		mips_reset(state, 0);
		
		// Return to nothing (cause simulator to fail)
		mips_set_register(state, R_ra, 0xFFFFFFFFu);

		// This is setting up the arguments
		mips_set_register(state, R_at, a);
		mips_set_register(state, R_v1, b);
		mips_set_register(state, R_a0, c);
	
		while(!mips_step(state)){
			// Keep stepping till it attempts to return to 0xFFFFFFFF
		}
		
		// Pull the result out
		res_sim=mips_get_register(state, R_v0);
		
		// Get the true result
		res_correct=t7_F(a,b,c);
	
		if(res_sim!=res_correct){
			fprintf(stdout, "F(%u,%u, %u), sim=%u, correct=%u\n", a, b, c, res_sim, res_correct);
			fail=1;
		}

	}		
	
	if (fail){
		fprintf(stdout, "Sorry, you failed! :(\n");
	} else {
		fprintf(stdout, "Congrats! Test passed.\n");
	}

	mips_free(state);	
	free(pMem);
	pMem=0;
	
	return fail;
}
