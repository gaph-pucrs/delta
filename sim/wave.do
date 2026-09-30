onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group TESTBENCH /testbench/*
add wave -noupdate -group PE /testbench/pe/*
add wave -noupdate -group CORE /testbench/pe/core/*
add wave -noupdate -group ICACHE_CTRL /testbench/pe/icache_ctrl/*
add wave -noupdate -group DCACHE_CTRL /testbench/pe/dcache_ctrl/*
add wave -noupdate -group CNI /testbench/pe/cni/*
add wave -noupdate -group MNI /testbench/mni/*
TreeUpdate [SetDefaultTree]
configure wave -namecolwidth 250
configure wave -valuecolwidth 100
configure wave -timelineunits ns
update
