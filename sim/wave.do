onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group TESTBENCH /testbench/clk
add wave -noupdate -group TESTBENCH /testbench/reset_n
add wave -noupdate -group TESTBENCH /testbench/char
add wave -noupdate -group TESTBENCH /testbench/fd
add wave -noupdate -expand -group PE /testbench/noc/pe/clk
add wave -noupdate -expand -group PE /testbench/noc/pe/rx_i
add wave -noupdate -expand -group PE /testbench/noc/pe/tx_o
add wave -noupdate -expand -group PE /testbench/noc/pe/eop_i
add wave -noupdate -expand -group PE /testbench/noc/pe/eop_o
add wave -noupdate -expand -group PE /testbench/noc/pe/credit_i
add wave -noupdate -expand -group PE /testbench/noc/pe/credit_o
add wave -noupdate -expand -group PE /testbench/noc/pe/data_i
add wave -noupdate -expand -group PE /testbench/noc/pe/data_o
add wave -noupdate -expand -group PE -expand -group CNI /testbench/noc/pe/cni/cni_cr_i
add wave -noupdate -expand -group PE -expand -group CNI /testbench/noc/pe/cni/cni_cr_o
add wave -noupdate -expand -group PE -expand -group CNI /testbench/noc/pe/cni/cni_data_i
add wave -noupdate -expand -group PE -expand -group CNI /testbench/noc/pe/cni/cni_data_o
add wave -noupdate -expand -group PE -expand -group CNI /testbench/noc/pe/cni/cni_eop_i
add wave -noupdate -expand -group PE -expand -group CNI /testbench/noc/pe/cni/cni_eop_o
add wave -noupdate -expand -group PE -expand -group CNI /testbench/noc/pe/cni/cni_rx_i
add wave -noupdate -expand -group PE -expand -group CNI /testbench/noc/pe/cni/cni_tx_o
add wave -noupdate -expand -group PE -expand -group CNI /testbench/noc/pe/cni/hx
add wave -noupdate -expand -group PE -expand -group CNI /testbench/noc/pe/cni/hx_origin
add wave -noupdate -expand -group PE -expand -group CNI /testbench/noc/pe/cni/hy
add wave -noupdate -expand -group PE -expand -group CNI /testbench/noc/pe/cni/hy_origin
add wave -noupdate -expand -group PE -expand -group CNI /testbench/noc/pe/cni/state
add wave -noupdate -expand -group PE -expand -group CNI /testbench/noc/pe/cni/next_state
add wave -noupdate -expand -group ME /testbench/noc/me/mni/mni_cr_i
add wave -noupdate -expand -group ME /testbench/noc/me/mni/mni_cr_o
add wave -noupdate -expand -group ME /testbench/noc/me/mni/mni_data_i
add wave -noupdate -expand -group ME /testbench/noc/me/mni/mni_data_o
add wave -noupdate -expand -group ME /testbench/noc/me/mni/mni_eop_i
add wave -noupdate -expand -group ME /testbench/noc/me/mni/mni_eop_o
add wave -noupdate -expand -group ME /testbench/noc/me/mni/mni_rx_i
add wave -noupdate -expand -group ME /testbench/noc/me/mni/mni_tx_o
add wave -noupdate -expand -group ME /testbench/noc/me/mni/state
add wave -noupdate -expand -group ME /testbench/noc/me/mni/next_state
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {145 ns} 1} {{Cursor 2} {235 ns} 1}
quietly wave cursor active 1
configure wave -namecolwidth 250
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {110 ns} {241 ns}
