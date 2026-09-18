#
# Makefile for managing installation and cleanup.
#
# Copyright (C) 1996-2026 under GPLv3, Fredrik Jonsson
#
TARGET=/usr/local/bin/
PROJECT=texrenumber

define run_and_check
	@$(1); \
	exit_code=$$?; \
	if [ $$exit_code -eq 1 ]; then \
		echo "Error: '$(1)' failed with exit code 1."; \
		echo "Suggestion: Try running 'sudo make install'."; \
	fi; \
	exit $$exit_code
endef

get_formatted_date = $(shell \
	if date +"%e" >/dev/null 2>&1; then \
		day=$$(date +"%e" | tr -d ' '); \
	else \
		day=$$(date +"%d" | sed 's/^0//'); \
	fi; \
	month=$$(date +"%B"); \
	weekday=$$(date +"%A"); \
	year=$$(date +"%Y"); \
	case $$day in \
	    1|21|31) suffix="st" ;; \
	    2|22)    suffix="nd" ;; \
	    3|23)    suffix="rd" ;; \
	    *)       suffix="th" ;; \
	esac; \
	printf "%s %s:%s (%s), %s\n" "$$month" "$$day" "$$suffix" "$$weekday" "$$year" \
)

all:
	@echo "Run '' to install the "$(PROJECT)".sh script."

install:
	@echo "Installing the "$(PROJECT)" script at "$(TARGET)" as $$USER"
	$(call run_and_check, rm -Rf $(TARGET)/$(PROJECT).sh $(TARGET)/$(PROJECT))
	$(call run_and_check, cp $(PROJECT).sh $(TARGET))
	$(call run_and_check, chmod +x $(TARGET)/$(PROJECT).sh)
	$(call run_and_check, ln -s $(TARGET)/$(PROJECT).sh $(TARGET)/$(PROJECT))
	@echo "Successfully installed the script "$(PROJECT)" at "$(TARGET)" as $$USER"

clean:
	-rm -Rf *~
