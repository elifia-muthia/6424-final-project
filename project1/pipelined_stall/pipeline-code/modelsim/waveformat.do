onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix unsigned /top_tb/*
add wave -noupdate -color yellow -itemcolor yellow -radix unsigned /top_tb/dut/*
add wave -noupdate -color cyan -itemcolor cyan -radix unsigned /top_tb/dut/producer_inst/*
add wave -noupdate -color pink -itemcolor pink -radix unsigned /top_tb/dut/pipeline_inst/*
add wave -noupdate -color purple -itemcolor purple -radix unsigned /top_tb/dut/consumer_inst/*
add wave -noupdate -color orange -itemcolor orange -radix unsigned /top_tb/dut/pipeline_inst/resource_top/*
add wave -noupdate -color blue -itemcolor blue -radix unsigned /top_tb/dut/pipeline_inst/resource_top/buffer_1/*
add wave -noupdate -color lime -itemcolor lime -radix unsigned /top_tb/dut/pipeline_inst/resource_top/buffer_2/*
add wave -noupdate -color yellow -itemcolor yellow -radix unsigned /top_tb/dut/pipeline_inst/resource_top/arbiter_inst/*
add wave -noupdate -color pink -itemcolor pink -radix unsigned /top_tb/dut/pipeline_inst/resource_top/shared_resource_inst/*
add wave -noupdate -color red -itemcolor red -radix unsigned /top_tb/dut/pipeline_inst/pipeline_1/*
add wave -noupdate -color grey -radix unsigned /top_tb/dut/pipeline_inst/pipeline_1/pipeline_stage_1/*
add wave -noupdate -color grey -radix unsigned /top_tb/dut/pipeline_inst/pipeline_1/pipeline_stage_1/buffer/*
add wave -noupdate -color violet -itemcolor violet -radix unsigned /top_tb/dut/pipeline_inst/pipeline_1/pipeline_stage_2/*
add wave -noupdate -color violet -itemcolor violet -radix unsigned /top_tb/dut/pipeline_inst/pipeline_1/pipeline_stage_2/buffer/*
add wave -noupdate -color white -itemcolor white -radix unsigned /top_tb/dut/pipeline_inst/pipeline_1/pipeline_stage_3/*
add wave -noupdate -color white -itemcolor white -radix unsigned /top_tb/dut/pipeline_inst/pipeline_1/pipeline_stage_3/buffer/*
add wave -noupdate -color cyan -itemcolor cyan -radix unsigned /top_tb/dut/pipeline_inst/pipeline_1/pipeline_stage_4/*
add wave -noupdate -color cyan -itemcolor cyan -radix unsigned /top_tb/dut/pipeline_inst/pipeline_1/pipeline_stage_4/buffer/*
add wave -noupdate -color yellow -itemcolor yellow -radix unsigned /top_tb/dut/pipeline_inst/pipeline_2/*
add wave -noupdate -color green -itemcolor green -radix unsigned /top_tb/dut/pipeline_inst/pipeline_2/pipeline_stage_1/*
add wave -noupdate -color green -itemcolor green -radix unsigned /top_tb/dut/pipeline_inst/pipeline_2/pipeline_stage_1/buffer/*
add wave -noupdate -color teal -itemcolor teal -radix unsigned /top_tb/dut/pipeline_inst/pipeline_2/pipeline_stage_2/*
add wave -noupdate -color teal -itemcolor teal -radix unsigned /top_tb/dut/pipeline_inst/pipeline_2/pipeline_stage_2/buffer/*
add wave -noupdate -color lime -itemcolor lime -radix unsigned /top_tb/dut/pipeline_inst/pipeline_2/pipeline_stage_3/*
add wave -noupdate -color lime -itemcolor lime -radix unsigned /top_tb/dut/pipeline_inst/pipeline_2/pipeline_stage_3/buffer/*
add wave -noupdate -color red -itemcolor red -radix unsigned /top_tb/dut/pipeline_inst/pipeline_2/pipeline_stage_4/*
add wave -noupdate -color red -itemcolor red -radix unsigned /top_tb/dut/pipeline_inst/pipeline_2/pipeline_stage_4/buffer/*

TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {304341 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 579
configure wave -valuecolwidth 266
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
WaveRestoreZoom {0 ps} {21824891 ps}


