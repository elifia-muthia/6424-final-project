# Makefile for running Yosys and Icarus Verilog inside a Docker container


# Variables
DOCKER_IMAGE := yosys-iverilog
DOCKER_CONTAINER := yosys_iverilog_container
workdir_DIR := workdir


# Default target
all: run-synth run-tb


# Create the Docker container
.build-container:
	docker build -t $(DOCKER_IMAGE) .
	touch .build-container
	cd workdir/libs && unzip asap7-std-cells-lib-merged.lib.zip


# Ensure the workdir directory exist
.ensure-dirs:
	@mkdir -p $(workdir_DIR)


# Run synthesis with Yosys inside the container
run-synth: .build-container .ensure-dirs
	docker run --rm -v $(shell pwd)/$(workdir_DIR):/workspace/workdir \
			$(DOCKER_IMAGE) bash -c "cd /workspace/workdir/verilog && yosys -c synth.tcl"


# Run testbench with Icarus Verilog inside the container
run-tb: .build-container .ensure-dirs
    docker run --rm -v $(shell pwd)/$(workdir_DIR):/workspace/workdir \
            $(DOCKER_IMAGE) bash -c "cd /workspace/workdir/testbenches && iverilog *.v ../verilog/*.v -o tb_run && ./tb_run"




# Clean up
.PHONY: clean
clean:
	@rm -f .build-container
	@echo "Cleaned up build files and directories."

.PHONY: clean_exe

clean_exe:
	@echo "Cleaning simulation and ModelSim-generated files in ../modelsim..."
	rm -f ../modelsim/transcript \
		  ../modelsim/top_tb.vcd \
		  ../modelsim/vsim.wlf \
		  ../modelsim/_info \
		  ../modelsim/tb_run \
		  ../modelsim/simulation_output.txt \
	@rm -rf ../modelsim/work
	@echo "Clean complete."



# Help target
.PHONY: help
help:
	@echo "Available targets:"
	@echo "  all            - Build the container and run synthesis and testbench."
	@echo "  run-synth      - Run synthesis with Yosys inside the container."
	@echo "  run-tb         - Run a testbench with Icarus Verilog inside the container."
	@echo "  clean          - Clean up build files and directories."


MODULE ?= arbiter


%.run:
    docker run --rm -v $(shell pwd)/$(workdir_DIR):/workspace/workdir \
        $(DOCKER_IMAGE) bash -c "\
            cd /workspace/workdir && \
            iverilog -g2012 -o tb_run testbenches/$*_tb.v verilog/$*.v && \
            ./tb_run"


%.out:
	cd ../../modelsim && vsim -c -do "set MODULE $*; do runsim.do"


