onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -group TESTBENCH /testbench/clk
add wave -noupdate -group TESTBENCH /testbench/reset_n
add wave -noupdate -group TESTBENCH /testbench/enable_tb
add wave -noupdate -group TESTBENCH /testbench/mem_operation_enable
add wave -noupdate -group TESTBENCH /testbench/mem_address
add wave -noupdate -group TESTBENCH /testbench/mem_data_write
add wave -noupdate -group TESTBENCH /testbench/mem_write_enable
add wave -noupdate -group TESTBENCH /testbench/char
add wave -noupdate -group TESTBENCH /testbench/data_tb
add wave -noupdate -group TESTBENCH /testbench/enable_tb_r
add wave -noupdate -group TESTBENCH /testbench/periph_sel
add wave -noupdate -group TESTBENCH /testbench/periph_data
add wave -noupdate -group TESTBENCH /testbench/iack_periph
add wave -noupdate -group TESTBENCH /testbench/cni_tx
add wave -noupdate -group TESTBENCH /testbench/cni_eop
add wave -noupdate -group TESTBENCH /testbench/cni_data_o
add wave -noupdate -group TESTBENCH /testbench/mni_cr
add wave -noupdate -group TESTBENCH /testbench/cni_rx
add wave -noupdate -group TESTBENCH /testbench/cni_eop_i
add wave -noupdate -group TESTBENCH /testbench/cni_data_i
add wave -noupdate -group TESTBENCH /testbench/cni_cr_o
add wave -noupdate -group TESTBENCH /testbench/icache_ce
add wave -noupdate -group TESTBENCH /testbench/icache_we
add wave -noupdate -group TESTBENCH /testbench/icache_addr
add wave -noupdate -group TESTBENCH /testbench/icache_dataW
add wave -noupdate -group TESTBENCH /testbench/icache_dataR
add wave -noupdate -group TESTBENCH /testbench/dcache_ce
add wave -noupdate -group TESTBENCH /testbench/dcache_we
add wave -noupdate -group TESTBENCH /testbench/dcache_addr
add wave -noupdate -group TESTBENCH /testbench/dcache_dataW
add wave -noupdate -group TESTBENCH /testbench/dcache_dataR
add wave -noupdate -group TESTBENCH /testbench/mni_mem_ce
add wave -noupdate -group TESTBENCH /testbench/mni_mem_data_i
add wave -noupdate -group TESTBENCH /testbench/mni_mem_we
add wave -noupdate -group TESTBENCH /testbench/mni_mem_data_o
add wave -noupdate -group TESTBENCH /testbench/mni_mem_addr
add wave -noupdate -group TESTBENCH /testbench/enA
add wave -noupdate -group TESTBENCH /testbench/weA
add wave -noupdate -group TESTBENCH /testbench/addrA
add wave -noupdate -group TESTBENCH /testbench/dataAi
add wave -noupdate -group TESTBENCH /testbench/dataAo
add wave -noupdate -group TESTBENCH /testbench/fd
add wave -noupdate -group PE /testbench/pe/clk
add wave -noupdate -group PE /testbench/pe/reset_n
add wave -noupdate -group PE /testbench/pe/irq_i
add wave -noupdate -group PE /testbench/pe/iack_o
add wave -noupdate -group PE /testbench/pe/bus_en_o
add wave -noupdate -group PE /testbench/pe/bus_addr_o
add wave -noupdate -group PE /testbench/pe/bus_we_o
add wave -noupdate -group PE /testbench/pe/bus_data_o
add wave -noupdate -group PE /testbench/pe/periph_sel_i
add wave -noupdate -group PE /testbench/pe/periph_data_i
add wave -noupdate -group PE /testbench/pe/icache_ce_o
add wave -noupdate -group PE /testbench/pe/icache_we_o
add wave -noupdate -group PE /testbench/pe/icache_addr_o
add wave -noupdate -group PE /testbench/pe/icache_data_i
add wave -noupdate -group PE /testbench/pe/icache_data_o
add wave -noupdate -group PE /testbench/pe/dcache_ce_o
add wave -noupdate -group PE /testbench/pe/dcache_we_o
add wave -noupdate -group PE /testbench/pe/dcache_addr_o
add wave -noupdate -group PE /testbench/pe/dcache_data_i
add wave -noupdate -group PE /testbench/pe/dcache_data_o
add wave -noupdate -group PE /testbench/pe/tx_o
add wave -noupdate -group PE /testbench/pe/eop_o
add wave -noupdate -group PE /testbench/pe/data_o
add wave -noupdate -group PE /testbench/pe/credit_i
add wave -noupdate -group PE /testbench/pe/rx_i
add wave -noupdate -group PE /testbench/pe/eop_i
add wave -noupdate -group PE /testbench/pe/data_i
add wave -noupdate -group PE /testbench/pe/credit_o
add wave -noupdate -group PE /testbench/pe/instruction_address
add wave -noupdate -group PE /testbench/pe/instruction
add wave -noupdate -group PE /testbench/pe/busy
add wave -noupdate -group PE /testbench/pe/stall
add wave -noupdate -group PE /testbench/pe/enable_imem
add wave -noupdate -group PE /testbench/pe/enable_ram
add wave -noupdate -group PE /testbench/pe/enable_rtc
add wave -noupdate -group PE /testbench/pe/enable_plic
add wave -noupdate -group PE /testbench/pe/enable_rtc_r
add wave -noupdate -group PE /testbench/pe/enable_plic_r
add wave -noupdate -group PE /testbench/pe/mem_operation_enable
add wave -noupdate -group PE /testbench/pe/mem_address
add wave -noupdate -group PE /testbench/pe/mem_data_read
add wave -noupdate -group PE /testbench/pe/mem_data_write
add wave -noupdate -group PE /testbench/pe/mem_write_enable
add wave -noupdate -group PE /testbench/pe/data_ram
add wave -noupdate -group PE /testbench/pe/dmem_dataR
add wave -noupdate -group PE /testbench/pe/data_rtc
add wave -noupdate -group PE /testbench/pe/data_plic
add wave -noupdate -group PE /testbench/pe/mtime
add wave -noupdate -group PE /testbench/pe/mti
add wave -noupdate -group PE /testbench/pe/mei
add wave -noupdate -group PE /testbench/pe/interrupt_ack
add wave -noupdate -group PE /testbench/pe/imem_busy
add wave -noupdate -group PE /testbench/pe/imem_ce
add wave -noupdate -group PE /testbench/pe/imem_addr
add wave -noupdate -group PE /testbench/pe/imem_data
add wave -noupdate -group PE /testbench/pe/dmem_busy
add wave -noupdate -group PE /testbench/pe/dmem_ce
add wave -noupdate -group PE /testbench/pe/dmem_we
add wave -noupdate -group PE /testbench/pe/dmem_addr
add wave -noupdate -group PE /testbench/pe/dmem_dataW
add wave -noupdate -group PE /testbench/pe/dcache_busy
add wave -noupdate -group PE /testbench/pe/cni_ce
add wave -noupdate -group PE /testbench/pe/cni_we
add wave -noupdate -group PE /testbench/pe/cni_addr
add wave -noupdate -group PE /testbench/pe/cni_cache_data_i
add wave -noupdate -group PE /testbench/pe/cni_cache_data_o
add wave -noupdate -group PE /testbench/pe/cni_busy
add wave -noupdate -group PE /testbench/pe/cni_working
add wave -noupdate -group PE /testbench/pe/cni_with_data
add wave -noupdate -group PE /testbench/pe/dcache_working
add wave -noupdate -expand -group CORE /testbench/pe/core/clk
add wave -noupdate -expand -group CORE /testbench/pe/core/reset_n
add wave -noupdate -expand -group CORE /testbench/pe/core/sys_reset_i
add wave -noupdate -expand -group CORE /testbench/pe/core/stall
add wave -noupdate -expand -group CORE /testbench/pe/core/busy_i
add wave -noupdate -expand -group CORE /testbench/pe/core/tip_i
add wave -noupdate -expand -group CORE /testbench/pe/core/eip_i
add wave -noupdate -expand -group CORE /testbench/pe/core/interrupt_ack_o
add wave -noupdate -expand -group CORE /testbench/pe/core/mtime_i
add wave -noupdate -expand -group CORE /testbench/pe/core/imem_operation_enable_o
add wave -noupdate -expand -group CORE /testbench/pe/core/instruction_address_o
add wave -noupdate -expand -group CORE /testbench/pe/core/instruction_i
add wave -noupdate -expand -group CORE /testbench/pe/core/dmem_operation_enable_o
add wave -noupdate -expand -group CORE /testbench/pe/core/mem_write_enable_o
add wave -noupdate -expand -group CORE /testbench/pe/core/mem_address_o
add wave -noupdate -expand -group CORE /testbench/pe/core/mem_data_o
add wave -noupdate -expand -group CORE /testbench/pe/core/mem_data_i
add wave -noupdate -expand -group CORE /testbench/pe/core/hold
add wave -noupdate -expand -group CORE /testbench/pe/core/fetch_hazard
add wave -noupdate -expand -group CORE /testbench/pe/core/enable_fetch
add wave -noupdate -expand -group CORE /testbench/pe/core/jump
add wave -noupdate -expand -group CORE /testbench/pe/core/ctx_switch
add wave -noupdate -expand -group CORE /testbench/pe/core/should_jump
add wave -noupdate -expand -group CORE /testbench/pe/core/jump_target
add wave -noupdate -expand -group CORE /testbench/pe/core/ctx_switch_target
add wave -noupdate -expand -group CORE /testbench/pe/core/bp_take_fetch
add wave -noupdate -expand -group CORE /testbench/pe/core/jump_rollback
add wave -noupdate -expand -group CORE /testbench/pe/core/bp_ack
add wave -noupdate -expand -group CORE /testbench/pe/core/bp_target
add wave -noupdate -expand -group CORE /testbench/pe/core/instruction_address
add wave -noupdate -expand -group CORE /testbench/pe/core/decode_ctrl
add wave -noupdate -expand -group CORE /testbench/pe/core/instruction_decode
add wave -noupdate -expand -group CORE /testbench/pe/core/pc_decode
add wave -noupdate -expand -group CORE /testbench/pe/core/privilege
add wave -noupdate -expand -group CORE /testbench/pe/core/mmu_en
add wave -noupdate -expand -group CORE /testbench/pe/core/mvmctl
add wave -noupdate -expand -group CORE /testbench/pe/core/mvmio
add wave -noupdate -expand -group CORE /testbench/pe/core/mvmis
add wave -noupdate -expand -group CORE /testbench/pe/core/mvmim
add wave -noupdate -expand -group CORE /testbench/pe/core/mmu_inst_fault
add wave -noupdate -expand -group CORE /testbench/pe/core/enable_decode
add wave -noupdate -expand -group CORE /testbench/pe/core/rs1
add wave -noupdate -expand -group CORE /testbench/pe/core/rs2
add wave -noupdate -expand -group CORE /testbench/pe/core/regbank_data1
add wave -noupdate -expand -group CORE /testbench/pe/core/regbank_data2
add wave -noupdate -expand -group CORE /testbench/pe/core/ctrl_mem_access
add wave -noupdate -expand -group CORE /testbench/pe/core/ctrl_retire
add wave -noupdate -expand -group CORE /testbench/pe/core/write_enable_exec
add wave -noupdate -expand -group CORE /testbench/pe/core/rd_mem_access
add wave -noupdate -expand -group CORE /testbench/pe/core/rd_retire
add wave -noupdate -expand -group CORE /testbench/pe/core/result_exec
add wave -noupdate -expand -group CORE /testbench/pe/core/result_mem_access
add wave -noupdate -expand -group CORE /testbench/pe/core/regbank_data_writeback
add wave -noupdate -expand -group CORE /testbench/pe/core/ctrl_execute
add wave -noupdate -expand -group CORE /testbench/pe/core/rd_execute
add wave -noupdate -expand -group CORE /testbench/pe/core/rs1_execute
add wave -noupdate -expand -group CORE /testbench/pe/core/csr_addr
add wave -noupdate -expand -group CORE /testbench/pe/core/pc_execute
add wave -noupdate -expand -group CORE /testbench/pe/core/rs1_data_execute
add wave -noupdate -expand -group CORE /testbench/pe/core/rs2_data_execute
add wave -noupdate -expand -group CORE /testbench/pe/core/second_operand_execute
add wave -noupdate -expand -group CORE /testbench/pe/core/instruction_execute
add wave -noupdate -expand -group CORE /testbench/pe/core/jump_imm_target_exec
add wave -noupdate -expand -group CORE /testbench/pe/core/exec_valid
add wave -noupdate -expand -group CORE /testbench/pe/core/load_access_fault
add wave -noupdate -expand -group CORE /testbench/pe/core/reservation_data
add wave -noupdate -expand -group CORE /testbench/pe/core/csr_operation
add wave -noupdate -expand -group CORE /testbench/pe/core/Exception_Code
add wave -noupdate -expand -group CORE /testbench/pe/core/interrupt_pending
add wave -noupdate -expand -group CORE /testbench/pe/core/csr_read_enable
add wave -noupdate -expand -group CORE /testbench/pe/core/csr_write_enable
add wave -noupdate -expand -group CORE /testbench/pe/core/RAISE_EXCEPTION
add wave -noupdate -expand -group CORE /testbench/pe/core/MACHINE_RETURN
add wave -noupdate -expand -group CORE /testbench/pe/core/csr_data_to_write
add wave -noupdate -expand -group CORE /testbench/pe/core/csr_data_read
add wave -noupdate -expand -group CORE /testbench/pe/core/mepc
add wave -noupdate -expand -group CORE /testbench/pe/core/mtvec
add wave -noupdate -expand -group CORE /testbench/pe/core/vtype
add wave -noupdate -expand -group CORE /testbench/pe/core/vlen
add wave -noupdate -expand -group CORE /testbench/pe/core/pc_irq
add wave -noupdate -expand -group CORE /testbench/pe/core/pc_exc
add wave -noupdate -expand -group CORE /testbench/pe/core/mem_enable
add wave -noupdate -expand -group CORE /testbench/pe/core/mem_address_exec
add wave -noupdate -expand -group CORE /testbench/pe/core/mem_address
add wave -noupdate -expand -group CORE /testbench/pe/core/result_retire
add wave -noupdate -expand -group CORE /testbench/pe/core/mvmdo
add wave -noupdate -expand -group CORE /testbench/pe/core/mvmds
add wave -noupdate -expand -group CORE /testbench/pe/core/mvmdm
add wave -noupdate -expand -group ICACHE_CTRL /testbench/pe/icache_ctrl/clk
add wave -noupdate -expand -group ICACHE_CTRL /testbench/pe/icache_ctrl/rst_n
add wave -noupdate -expand -group ICACHE_CTRL /testbench/pe/icache_ctrl/ce_i
add wave -noupdate -expand -group ICACHE_CTRL /testbench/pe/icache_ctrl/we_i
add wave -noupdate -expand -group ICACHE_CTRL /testbench/pe/icache_ctrl/address_i
add wave -noupdate -expand -group ICACHE_CTRL /testbench/pe/icache_ctrl/data_i
add wave -noupdate -expand -group ICACHE_CTRL /testbench/pe/icache_ctrl/data_o
add wave -noupdate -expand -group ICACHE_CTRL /testbench/pe/icache_ctrl/busy_o
add wave -noupdate -expand -group ICACHE_CTRL /testbench/pe/icache_ctrl/cache_ce_o
add wave -noupdate -expand -group ICACHE_CTRL /testbench/pe/icache_ctrl/cache_we_o
add wave -noupdate -expand -group ICACHE_CTRL /testbench/pe/icache_ctrl/cache_addr_o
add wave -noupdate -expand -group ICACHE_CTRL /testbench/pe/icache_ctrl/cache_data_i
add wave -noupdate -expand -group ICACHE_CTRL /testbench/pe/icache_ctrl/cache_data_o
add wave -noupdate -expand -group ICACHE_CTRL /testbench/pe/icache_ctrl/mem_ce_o
add wave -noupdate -expand -group ICACHE_CTRL /testbench/pe/icache_ctrl/mem_we_o
add wave -noupdate -expand -group ICACHE_CTRL /testbench/pe/icache_ctrl/mem_addr_o
add wave -noupdate -expand -group ICACHE_CTRL /testbench/pe/icache_ctrl/mem_data_i
add wave -noupdate -expand -group ICACHE_CTRL /testbench/pe/icache_ctrl/mem_data_o
add wave -noupdate -expand -group ICACHE_CTRL /testbench/pe/icache_ctrl/mem_busy_i
add wave -noupdate -expand -group ICACHE_CTRL /testbench/pe/icache_ctrl/miss
add wave -noupdate -expand -group ICACHE_CTRL /testbench/pe/icache_ctrl/is_dirty
add wave -noupdate -expand -group ICACHE_CTRL /testbench/pe/icache_ctrl/is_write
add wave -noupdate -expand -group ICACHE_CTRL /testbench/pe/icache_ctrl/end_fill
add wave -noupdate -expand -group ICACHE_CTRL /testbench/pe/icache_ctrl/end_evict
add wave -noupdate -expand -group ICACHE_CTRL /testbench/pe/icache_ctrl/mem_valid
add wave -noupdate -expand -group ICACHE_CTRL /testbench/pe/icache_ctrl/cache_valid
add wave -noupdate -expand -group ICACHE_CTRL /testbench/pe/icache_ctrl/tag
add wave -noupdate -expand -group ICACHE_CTRL /testbench/pe/icache_ctrl/tag_r
add wave -noupdate -expand -group ICACHE_CTRL /testbench/pe/icache_ctrl/evict_tag_r
add wave -noupdate -expand -group ICACHE_CTRL /testbench/pe/icache_ctrl/next_state
add wave -noupdate -expand -group ICACHE_CTRL /testbench/pe/icache_ctrl/current_state
add wave -noupdate -expand -group ICACHE_CTRL /testbench/pe/icache_ctrl/offset
add wave -noupdate -expand -group ICACHE_CTRL /testbench/pe/icache_ctrl/line_idx
add wave -noupdate -expand -group ICACHE_CTRL /testbench/pe/icache_ctrl/line_idx_r
add wave -noupdate -expand -group ICACHE_CTRL /testbench/pe/icache_ctrl/mem_idx
add wave -noupdate -expand -group ICACHE_CTRL /testbench/pe/icache_ctrl/cache_idx
add wave -noupdate -expand -group ICACHE_CTRL /testbench/pe/icache_ctrl/address_r
add wave -noupdate -expand -group DCACHE_CTRL /testbench/pe/dcache_ctrl/clk
add wave -noupdate -expand -group DCACHE_CTRL /testbench/pe/dcache_ctrl/rst_n
add wave -noupdate -expand -group DCACHE_CTRL /testbench/pe/dcache_ctrl/ce_i
add wave -noupdate -expand -group DCACHE_CTRL /testbench/pe/dcache_ctrl/we_i
add wave -noupdate -expand -group DCACHE_CTRL /testbench/pe/dcache_ctrl/address_i
add wave -noupdate -expand -group DCACHE_CTRL /testbench/pe/dcache_ctrl/data_i
add wave -noupdate -expand -group DCACHE_CTRL /testbench/pe/dcache_ctrl/data_o
add wave -noupdate -expand -group DCACHE_CTRL /testbench/pe/dcache_ctrl/busy_o
add wave -noupdate -expand -group DCACHE_CTRL /testbench/pe/dcache_ctrl/cache_ce_o
add wave -noupdate -expand -group DCACHE_CTRL /testbench/pe/dcache_ctrl/cache_we_o
add wave -noupdate -expand -group DCACHE_CTRL /testbench/pe/dcache_ctrl/cache_addr_o
add wave -noupdate -expand -group DCACHE_CTRL /testbench/pe/dcache_ctrl/cache_data_i
add wave -noupdate -expand -group DCACHE_CTRL /testbench/pe/dcache_ctrl/cache_data_o
add wave -noupdate -expand -group DCACHE_CTRL /testbench/pe/dcache_ctrl/mem_ce_o
add wave -noupdate -expand -group DCACHE_CTRL /testbench/pe/dcache_ctrl/mem_we_o
add wave -noupdate -expand -group DCACHE_CTRL /testbench/pe/dcache_ctrl/mem_addr_o
add wave -noupdate -expand -group DCACHE_CTRL /testbench/pe/dcache_ctrl/mem_data_i
add wave -noupdate -expand -group DCACHE_CTRL /testbench/pe/dcache_ctrl/mem_data_o
add wave -noupdate -expand -group DCACHE_CTRL /testbench/pe/dcache_ctrl/mem_busy_i
add wave -noupdate -expand -group DCACHE_CTRL /testbench/pe/dcache_ctrl/miss
add wave -noupdate -expand -group DCACHE_CTRL /testbench/pe/dcache_ctrl/is_dirty
add wave -noupdate -expand -group DCACHE_CTRL /testbench/pe/dcache_ctrl/is_write
add wave -noupdate -expand -group DCACHE_CTRL /testbench/pe/dcache_ctrl/end_fill
add wave -noupdate -expand -group DCACHE_CTRL /testbench/pe/dcache_ctrl/end_evict
add wave -noupdate -expand -group DCACHE_CTRL /testbench/pe/dcache_ctrl/mem_valid
add wave -noupdate -expand -group DCACHE_CTRL /testbench/pe/dcache_ctrl/cache_valid
add wave -noupdate -expand -group DCACHE_CTRL /testbench/pe/dcache_ctrl/tag
add wave -noupdate -expand -group DCACHE_CTRL /testbench/pe/dcache_ctrl/tag_r
add wave -noupdate -expand -group DCACHE_CTRL /testbench/pe/dcache_ctrl/evict_tag_r
add wave -noupdate -expand -group DCACHE_CTRL /testbench/pe/dcache_ctrl/next_state
add wave -noupdate -expand -group DCACHE_CTRL /testbench/pe/dcache_ctrl/current_state
add wave -noupdate -expand -group DCACHE_CTRL /testbench/pe/dcache_ctrl/offset
add wave -noupdate -expand -group DCACHE_CTRL /testbench/pe/dcache_ctrl/line_idx
add wave -noupdate -expand -group DCACHE_CTRL /testbench/pe/dcache_ctrl/line_idx_r
add wave -noupdate -expand -group DCACHE_CTRL /testbench/pe/dcache_ctrl/mem_idx
add wave -noupdate -expand -group DCACHE_CTRL /testbench/pe/dcache_ctrl/cache_idx
add wave -noupdate -expand -group DCACHE_CTRL /testbench/pe/dcache_ctrl/address_r
add wave -noupdate -expand -group CNI /testbench/pe/cni/clk
add wave -noupdate -expand -group CNI /testbench/pe/cni/rst_n
add wave -noupdate -expand -group CNI /testbench/pe/cni/cache_data_o
add wave -noupdate -expand -group CNI /testbench/pe/cni/cache_ce_i
add wave -noupdate -expand -group CNI /testbench/pe/cni/cache_we_i
add wave -noupdate -expand -group CNI /testbench/pe/cni/cache_addr_i
add wave -noupdate -expand -group CNI /testbench/pe/cni/cache_data_i
add wave -noupdate -expand -group CNI /testbench/pe/cni/mem_busy_o
add wave -noupdate -expand -group CNI /testbench/pe/cni/cni_tx_o
add wave -noupdate -expand -group CNI /testbench/pe/cni/cni_cr_i
add wave -noupdate -expand -group CNI /testbench/pe/cni/cni_eop_o
add wave -noupdate -expand -group CNI /testbench/pe/cni/cni_data_o
add wave -noupdate -expand -group CNI /testbench/pe/cni/cni_cr_o
add wave -noupdate -expand -group CNI /testbench/pe/cni/cni_rx_i
add wave -noupdate -expand -group CNI /testbench/pe/cni/cni_eop_i
add wave -noupdate -expand -group CNI /testbench/pe/cni/cni_data_i
add wave -noupdate -expand -group CNI /testbench/pe/cni/flit_cnt
add wave -noupdate -expand -group CNI /testbench/pe/cni/payload_len
add wave -noupdate -expand -group CNI /testbench/pe/cni/wr_word_v
add wave -noupdate -expand -group CNI /testbench/pe/cni/wr_data_sent
add wave -noupdate -expand -group CNI /testbench/pe/cni/header
add wave -noupdate -expand -group CNI /testbench/pe/cni/hflag
add wave -noupdate -expand -group CNI /testbench/pe/cni/hservice
add wave -noupdate -expand -group CNI /testbench/pe/cni/hx
add wave -noupdate -expand -group CNI /testbench/pe/cni/hy
add wave -noupdate -expand -group CNI /testbench/pe/cni/fill_word_taken
add wave -noupdate -expand -group CNI /testbench/pe/cni/addr_r
add wave -noupdate -expand -group CNI /testbench/pe/cni/wr_r
add wave -noupdate -expand -group CNI /testbench/pe/cni/tx_rb
add wave -noupdate -expand -group CNI /testbench/pe/cni/tx_rb_ack
add wave -noupdate -expand -group CNI /testbench/pe/cni/rx_rb
add wave -noupdate -expand -group CNI /testbench/pe/cni/data_rb
add wave -noupdate -expand -group CNI /testbench/pe/cni/state
add wave -noupdate -expand -group CNI /testbench/pe/cni/next_state
add wave -noupdate -expand -group CNI /testbench/pe/cni/i
add wave -noupdate -expand -group MNI /testbench/mni/clk
add wave -noupdate -expand -group MNI /testbench/mni/rst_n
add wave -noupdate -expand -group MNI /testbench/mni/mni_mem_ce_o
add wave -noupdate -expand -group MNI /testbench/mni/mni_mem_addr_o
add wave -noupdate -expand -group MNI /testbench/mni/mni_mem_we_o
add wave -noupdate -expand -group MNI /testbench/mni/mni_mem_data_i
add wave -noupdate -expand -group MNI /testbench/mni/mni_mem_data_o
add wave -noupdate -expand -group MNI /testbench/mni/mni_tx_o
add wave -noupdate -expand -group MNI /testbench/mni/mni_eop_o
add wave -noupdate -expand -group MNI /testbench/mni/mni_data_o
add wave -noupdate -expand -group MNI /testbench/mni/mni_cr_i
add wave -noupdate -expand -group MNI /testbench/mni/mni_rx_i
add wave -noupdate -expand -group MNI /testbench/mni/mni_cr_o
add wave -noupdate -expand -group MNI /testbench/mni/mni_eop_i
add wave -noupdate -expand -group MNI /testbench/mni/mni_data_i
add wave -noupdate -expand -group MNI /testbench/mni/addr_cnt
add wave -noupdate -expand -group MNI /testbench/mni/data_cnt
add wave -noupdate -expand -group MNI /testbench/mni/mem_rd_v
add wave -noupdate -expand -group MNI /testbench/mni/base_addr_r
add wave -noupdate -expand -group MNI /testbench/mni/we_r
add wave -noupdate -expand -group MNI /testbench/mni/wr_cnt
add wave -noupdate -expand -group MNI /testbench/mni/header
add wave -noupdate -expand -group MNI /testbench/mni/hflag
add wave -noupdate -expand -group MNI /testbench/mni/hservice
add wave -noupdate -expand -group MNI /testbench/mni/hx
add wave -noupdate -expand -group MNI /testbench/mni/hy
add wave -noupdate -expand -group MNI /testbench/mni/tx_rb_ack
add wave -noupdate -expand -group MNI /testbench/mni/rx_rb
add wave -noupdate -expand -group MNI /testbench/mni/data_rb
add wave -noupdate -expand -group MNI /testbench/mni/rx_rb_ack
add wave -noupdate -expand -group MNI /testbench/mni/state
add wave -noupdate -expand -group MNI /testbench/mni/next_state
add wave -noupdate -expand -group MNI /testbench/mni/i
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {485 ns} 0} {{Cursor 2} {447 ns} 0}
quietly wave cursor active 2
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
WaveRestoreZoom {444 ns} {576 ns}
