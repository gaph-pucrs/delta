onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider RS5
add wave -noupdate -color Red -radix hexadecimal {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/instruction_address}
add wave -noupdate -color Red -radix hexadecimal {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/instruction}
add wave -noupdate -color Red {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/enable_imem}
add wave -noupdate -color Red {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/busy}
add wave -noupdate -color Red {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/mem_operation_enable}
add wave -noupdate -color Red -radix hexadecimal {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/mem_data_read}
add wave -noupdate -color Red {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/stall}
add wave -noupdate -color Red {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/enable_rtc}
add wave -noupdate -color Red {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/enable_plic}
add wave -noupdate -color Red {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/enable_tb}
add wave -noupdate -divider {$I CONTROLLER}
add wave -noupdate -color Blue {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/icache_ctrl/current_state}
add wave -noupdate -color Blue {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/icache_ctrl/miss}
add wave -noupdate -color Blue {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/imem_ce}
add wave -noupdate -color Blue -radix hexadecimal {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/imem_addr}
add wave -noupdate -color Blue -radix hexadecimal {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/imem_data}
add wave -noupdate -divider {$D CONTROLLER}
add wave -noupdate -color {Orange Red} {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/dcache_ctrl/current_state}
add wave -noupdate -color {Orange Red} {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/dcache_ctrl/miss}
add wave -noupdate -color {Orange Red} {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/dcache_ctrl/is_dirty}
add wave -noupdate -color {Orange Red} {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/dcache_busy}
add wave -noupdate -color {Orange Red} {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/dmem_ce}
add wave -noupdate -color {Orange Red} -radix hexadecimal {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/dmem_addr}
add wave -noupdate -color {Orange Red} -radix hexadecimal {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/dmem_we}
add wave -noupdate -color {Orange Red} -radix hexadecimal {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/dmem_dataW}
add wave -noupdate -color {Orange Red} -radix hexadecimal {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/data_ram}
add wave -noupdate -divider CNI
add wave -noupdate -color Yellow {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/cni/state}
add wave -noupdate -color Yellow {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/tx_o}
add wave -noupdate -color Yellow {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/eop_o}
add wave -noupdate -color Yellow {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/credit_i}
add wave -noupdate -color Yellow -radix hexadecimal {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/data_o}
add wave -noupdate -color Yellow {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/rx_i}
add wave -noupdate -color Yellow {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/eop_i}
add wave -noupdate -color Yellow {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/credit_o}
add wave -noupdate -color Yellow -radix hexadecimal {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/data_i}
add wave -noupdate -color Yellow {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/cni_working}
add wave -noupdate -color Yellow {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/cni_with_data}
add wave -noupdate -color Yellow {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/cni_ce}
add wave -noupdate -color Yellow {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/cni_busy}
add wave -noupdate -color Yellow -radix hexadecimal {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/cni_we}
add wave -noupdate -color Yellow -radix hexadecimal {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/cni_addr}
add wave -noupdate -divider {0g. ME (MNI + MEMORY)}
add wave -noupdate -color Magenta /testbench/noc/me/mni/state
add wave -noupdate -color Magenta /testbench/noc/me/me_rx_i
add wave -noupdate -color Magenta /testbench/noc/me/me_eop_i
add wave -noupdate -color Magenta -radix hexadecimal /testbench/noc/me/me_data_i
add wave -noupdate -color Magenta /testbench/noc/me/me_tx_o
add wave -noupdate -color Magenta /testbench/noc/me/me_eop_o
add wave -noupdate -color Magenta -radix hexadecimal /testbench/noc/me/me_data_o
add wave -noupdate -color Magenta /testbench/noc/me/enA
add wave -noupdate -color Magenta -radix hexadecimal /testbench/noc/me/weA
add wave -noupdate -color Magenta -radix hexadecimal /testbench/noc/me/addrA
add wave -noupdate -color Magenta -radix hexadecimal /testbench/noc/me/dataAi
add wave -noupdate -color Magenta -radix hexadecimal /testbench/noc/me/dataAo
add wave -noupdate -divider {1. MEM_COPY D$ -> SCPAD}
add wave -noupdate -radix hexadecimal {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/mem_address}
add wave -noupdate -radix hexadecimal {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/mem_write_enable}
add wave -noupdate -radix hexadecimal {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/mem_data_write}
add wave -noupdate {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/enable_ram}
add wave -noupdate {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/enable_scpad}
add wave -noupdate -divider {2. DMNI CONFIG}
add wave -noupdate {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/enable_dmni}
add wave -noupdate -radix hexadecimal {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/data_dmni}
add wave -noupdate {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/dmni_irq}
add wave -noupdate -divider {3. DMNI READS SCPAD (PORT B)}
add wave -noupdate {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/dmni_mem_en}
add wave -noupdate -radix hexadecimal {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/dmni_mem_addr}
add wave -noupdate -radix hexadecimal {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/dmni_mem_data_r}
add wave -noupdate -divider {4. DMNI -> NoC}
add wave -noupdate {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/dmni_tx_o}
add wave -noupdate {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/dmni_eop_o}
add wave -noupdate {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/dmni_credit_i}
add wave -noupdate -radix hexadecimal {/testbench/noc/gen_x_pe[0]/gen_y_pe[0]/gen_pe/pe/dmni_data_o}
add wave -noupdate -divider RALO
add wave -noupdate -label {Entrada Sul Roteador 0,0} {/testbench/noc/rx[0][0][3]}
add wave -noupdate -label {Credito Entrada Sul Roteador 0,0} {/testbench/noc/credit_rx[0][0][3]}
add wave -noupdate -label {Dado Entrada Sul Roteador 0,0} -radix hexadecimal {/testbench/noc/data_rx[0][0][3]}
add wave -noupdate -label {Saida Norte Roteador 0,0} {/testbench/noc/tx[0][0][2]}
add wave -noupdate -label {Dado Saida Norte Roteador 0,0} -radix hexadecimal {/testbench/noc/data_tx[0][0][2]}
add wave -noupdate -label {EOP Saida Norte Roteador 0,0} {/testbench/noc/eop_tx[0][0][2]}
add wave -noupdate -label {Saida Norte Roteador 0,1} {/testbench/noc/tx[0][1][2]}
add wave -noupdate -label {Dado Saida Norte Roteador 0,1} -radix hexadecimal {/testbench/noc/data_tx[0][1][2]}
add wave -noupdate -label {EOP Saida Norte Roteador 0,1} {/testbench/noc/eop_tx[0][1][2]}
add wave -noupdate -label {Saida Norte Roteador 0,2} {/testbench/noc/tx[0][2][2]}
add wave -noupdate -label {Dado Saida Norte Roteador 0,2} -radix hexadecimal {/testbench/noc/data_tx[0][2][2]}
add wave -noupdate -label {EOP Saida Norte Roteador 0,2} {/testbench/noc/eop_tx[0][2][2]}
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {171492 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 483
configure wave -valuecolwidth 100
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
configure wave -timelineunits ns
update
WaveRestoreZoom {171487 ns} {171584 ns}
