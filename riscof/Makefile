WORK_DIR     ?= .
BRANCHPRED   ?= 1
FORWARDING   ?= 1
DUALPORT_MEM ?= 1
IQUEUE_SIZE  ?= 2
DELAY_CYCLES ?= 0
TRIPLET      ?= riscv64-elf

ENV_VARS = \
	TRIPLET=$(TRIPLET)\
	BRANCHPRED=$(BRANCHPRED)\
	FORWARDING=$(FORWARDING)\
	DUALPORT_MEM=$(DUALPORT_MEM)\
	IQUEUE_SIZE=$(IQUEUE_SIZE) \
	DELAY_CYCLES=$(DELAY_CYCLES)

default: baseline

all: baseline 

report-all: report-baseline

baseline: arch-test-update
	@$(ENV_VARS) riscof run --suite=riscv-arch-test/riscv-test-suite --env=riscv-arch-test/riscv-test-suite/env --work-dir=$(WORK_DIR)/baseline_work --no-browser --config=baseline.ini

arch-test-update: riscv-arch-test
	@riscof arch-test --update --get-version 3.9.1

riscv-arch-test:
	@riscof arch-test --clone --get-version 3.9.1

report-baseline: $(WORK_DIR)/baseline_work/report.html
	@xdg-open $^

$(WORK_DIR)/baseline_work/report.html:
	@make baseline


clean:
	@echo "Cleaning..."
	@rm -rf $(WORK_DIR)/baseline_work riscv-arch-test

.PHONY: all default baseline arch-test-update clean
