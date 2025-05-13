Global stall contains the global stall code and testbenches

Pipeline stall contains the pipeline stall code and testbenches

The code for the projects can be run either using a docker environment or modelsim. Within 6424-final-project/project1 you will find two folders global_stall and pipeline_stall which contain the respective pipeline versions. The general folder structure of each is the same.
	To run the modelsim testbench go to 6424-final-project/project1/(pipeline_version)/pipeline-code/modelsim and run the run.sh script. This script will run the testbench in 6424-final-project/project1/(pipeline_version)/pipeline-code/docker-yosys/workdir/testbenches on the code in 6424-final-project/project1/(pipeline_version)/pipeline-code/docker-yosys/workdir/verilog.
	To run the yosys based testbench you will need to start up docker and then go to 6424-final-project/project1/pipelined_stall/pipeline-code/docker-yosys and do make run-tb. Please note that if you previously did make run-synth please manually remove the generated gate netlist file to avoid redefinition conflicts.
