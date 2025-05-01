##################################################
#  Modelsim do file to run simuilation
##################################################

vlib work 
vmap work work

# include netlist and testbench files
vlog +acc -incr ../docker-yosys/workdir/testbenches/top_tb.v
vlog +acc -incr ../docker-yosys/workdir/verilog/*.v


# run simulation 
vsim +acc -t ps -lib work top_tb
do waveformat.do   
run -all
