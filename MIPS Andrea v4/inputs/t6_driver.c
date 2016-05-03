#include "mips.h"

#include "driver_helper.h"

// This is the function which the simulator is running
#include "t6_input.c"

int main(int argc,char *argv[])
{	
	unsigned i;
	
	if(argc>2){
		fprintf(stderr, "Usage: %s [file.bin]\n", argv[0]);
		exit(1);
	}
	
	unsigned cbMem=1<<20; // size of memory (2^20)
	uint8_t *pMem=(uint8_t*)malloc(cbMem); // we dinamically create the memory
	
	Driver_LoadInstructions(argc>1 ? argv[0] : "t6_input-mips.bin", (uint32_t*)pMem); // we load the instructions from the binary file to our memory
	
	struct mips_state_t *state=mips_create( // we create our state
		0,	// pc
		cbMem,
		pMem
	);
	
	int fail=0;
	
	for(i=0;i<100;i++){ // can be modified
		uint32_t a=rand(), b=rand(); // two random numbers
		uint64_t res_correct1, res_sim1, res_correct2, res_sim2, res_correct3, res_sim3, res_correct4, res_sim4; // four different answers to check


		// Run the program from the beginning
		mips_reset(state, 0);
		
		// Return to nothing (cause simulator to fail)
		mips_set_register(state, R_ra, 0xFFFFFFFFu);	
	
		// This is setting up the arguments
		mips_set_register(state, R_at, a);
		mips_set_register(state, R_v1, b);
	
		while(!mips_step(state)){
			// Keep stepping till it attempts to return to 0xFFFFFFFF
		}


		// Pull the result out
		res_sim1= mips_get_register(state, R_a0);
		res_sim1 = (res_sim1 << 32) + mips_get_register(state, R_a1);

		res_sim2= mips_get_register(state, R_v0);

		res_sim3= mips_get_register(state, R_a2);
		res_sim3 = (res_sim3 << 32) + mips_get_register(state, R_a3);

		res_sim4= mips_get_register(state, R_t0);
		res_sim4 = (res_sim4 << 32) + mips_get_register(state, R_t1);

		// Get the true result
		res_correct1=t6_F1(a,b);
		res_correct2=t6_F2(a,b);
		res_correct3=t6_F3(a,b);
		res_correct4=t6_F4(a,b);
	
		if(res_sim1!=res_correct1){
			fprintf(stdout, "F1(%u,%u), sim=%d, correct=%d\n", a, b, (int)res_sim1, (int)res_correct1);
			fail=1;
		}

		if(res_sim2!=res_correct2){
			fprintf(stdout, "F2(%u,%u), sim=%d, correct=%d\n", a, b, (int)res_sim2, (int)res_correct2);
			fail=1;
		}

		if(res_sim3!=res_correct3){
			fprintf(stdout, "F3(%u,%u), sim=%d, correct=%d\n", a, b,(int)res_sim3, (int)res_correct3);
			fail=1;
		}

		if(res_sim4!=res_correct4){
			fprintf(stdout, "F4(%u,%u), sim=%d, correct=%d\n", a, b,(int)res_sim4, (int)res_correct4);
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
