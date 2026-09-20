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

all:
	@echo "Run '' to install the "$(PROJECT)".sh script."

install:
	@echo "Installing the "$(PROJECT)" script at "$(TARGET)" as $$USER"
	$(call run_and_check, rm -Rf $(TARGET)/$(PROJECT).sh $(TARGET)/$(PROJECT))
	$(call run_and_check, cp $(PROJECT).sh $(TARGET))
	$(call run_and_check, chmod +x $(TARGET)/$(PROJECT).sh)
	$(call run_and_check, ln -s $(TARGET)/$(PROJECT).sh $(TARGET)/$(PROJECT))
	@echo "Successfully installed the script "$(PROJECT)" at "$(TARGET)" as $$USER"

example:
	./texrenumber.sh example.tex example-renumbered.tex
	tex example-renumbered.tex
	tex example-renumbered.tex
	dvips -D1200 -ta4 example-renumbered.dvi -o example-renumbered.ps
	ps2pdf example-renumbered.ps example-renumbered.pdf

clean:
	-rm -Rf *~ example-renumbered*
