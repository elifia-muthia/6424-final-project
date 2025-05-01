onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /top_tb/*
add wave -noupdate /top_tb/dut/*
add wave -noupdate /top_tb/dut/producer_inst/*
add wave -noupdate /top_tb/dut/pipeline_inst/*
add wave -noupdate /top_tb/dut/consumer_inst/*
add wave -noupdate /top_tb/dut/pipeline_inst/arbiter_inst/*
add wave -noupdate /top_tb/dut/pipeline_inst/shared_resource_inst/*
add wave -noupdate /top_tb/dut/pipeline_inst/pipeline_1/*
add wave -noupdate /top_tb/dut/pipeline_inst/pipeline_2/*
add wave -noupdate /top_tb/dut/pipeline_inst/pipeline_1/pipeline_unit_inst/*
add wave -noupdate /top_tb/dut/pipeline_inst/pipeline_1/buffer_slots_inst/*
add wave -noupdate /top_tb/dut/pipeline_inst/pipeline_1/stall_mgmt_inst/*
add wave -noupdate /top_tb/dut/pipeline_inst/pipeline_2/pipeline_unit_inst/*
add wave -noupdate /top_tb/dut/pipeline_inst/pipeline_2/buffer_slots_inst/*
add wave -noupdate /top_tb/dut/pipeline_inst/pipeline_2/stall_mgmt_inst/*


TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {3 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 223
configure wave -valuecolwidth 89
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ns} {12 ns}


