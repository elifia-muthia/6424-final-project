##################################################
#  Modelsim do file to run simulation (Flexible Module Testing)
##################################################

vlib work 
vmap work work

# Choose the module and testbench you want to test
set test_module "producer_fsm_tb"      ;# Set your testbench module name here
set dut_module "producer_fsm" ;# Set the DUT module you want to test here

# Clean and recompile
vdel -lib work -all
vlib work
vmap work work

# Include all Verilog files and the chosen testbench
vlog +acc -incr ../docker-yosys/workdir/testbenches/$test_module.v
vlog +acc -incr ../docker-yosys/workdir/verilog/*.v

# Run simulation for the chosen testbench
transcript on "simulation_output_${test_module}_${dut_module}.txt"
vsim -c -lib work $test_module -t ps -L work -do "run -all; quit"
transcript off

# Display the output file location
echo "Simulation finished. Output saved to simulation_output_${test_module}_${dut_module}.txt"