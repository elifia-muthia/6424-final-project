##################################################
#  Modelsim do file to run simuilation
##################################################

if {![info exists MODULE]} {
    echo "❌ Error: MODULE variable not set"
    quit -f
}

echo "✅ Running simulation for: $MODULE"

vlib work
vmap work work

vlog +acc -incr ../workdir/verilog/${MODULE}.v
vlog +acc -incr ../workdir/testbenches/${MODULE}_tb.v

vsim -c work.${MODULE}_tb -do {
    run -all
    quit
}

