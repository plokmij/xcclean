# Makefile for xcclean

PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin
LIBDIR = $(PREFIX)/lib/xcclean
BASH_COMPLETION_DIR = $(PREFIX)/etc/bash_completion.d
ZSH_COMPLETION_DIR = $(PREFIX)/share/zsh/site-functions
FISH_COMPLETION_DIR = $(PREFIX)/share/fish/vendor_completions.d

.PHONY: all install uninstall clean test

all:
	@echo "xcclean - Xcode Storage Cleaner CLI"
	@echo ""
	@echo "Usage:"
	@echo "  make install    Install xcclean to $(PREFIX)"
	@echo "  make uninstall  Remove xcclean from $(PREFIX)"
	@echo "  make test       Run basic tests"
	@echo ""

install:
	@echo "Installing xcclean to $(PREFIX)..."
	@mkdir -p $(BINDIR)
	@mkdir -p $(LIBDIR)
	@cp lib/*.sh $(LIBDIR)/
	@cp bin/xcclean $(BINDIR)/
	@chmod +x $(BINDIR)/xcclean
	@echo "✓ Installed xcclean to $(BINDIR)/xcclean"
	@echo "✓ Installed libraries to $(LIBDIR)/"
	@# Install completions
	@if [ -d "$(BASH_COMPLETION_DIR)" ] || mkdir -p "$(BASH_COMPLETION_DIR)" 2>/dev/null; then \
		cp completions/xcclean.bash $(BASH_COMPLETION_DIR)/xcclean; \
		echo "✓ Installed bash completions"; \
	fi
	@if [ -d "$(ZSH_COMPLETION_DIR)" ] || mkdir -p "$(ZSH_COMPLETION_DIR)" 2>/dev/null; then \
		cp completions/xcclean.zsh $(ZSH_COMPLETION_DIR)/_xcclean; \
		echo "✓ Installed zsh completions"; \
	fi
	@if [ -d "$(FISH_COMPLETION_DIR)" ] || mkdir -p "$(FISH_COMPLETION_DIR)" 2>/dev/null; then \
		cp completions/xcclean.fish $(FISH_COMPLETION_DIR)/xcclean.fish; \
		echo "✓ Installed fish completions"; \
	fi
	@echo ""
	@echo "Installation complete! Run 'xcclean --help' to get started."

uninstall:
	@echo "Uninstalling xcclean..."
	@rm -f $(BINDIR)/xcclean
	@rm -rf $(LIBDIR)
	@rm -f $(BASH_COMPLETION_DIR)/xcclean
	@rm -f $(ZSH_COMPLETION_DIR)/_xcclean
	@rm -f $(FISH_COMPLETION_DIR)/xcclean.fish
	@echo "✓ xcclean uninstalled"

test:
	@echo "Running tests..."
	@echo ""
	@echo "→ Testing --version"
	@./bin/xcclean --version
	@echo ""
	@echo "→ Testing --help"
	@./bin/xcclean --help | head -20
	@echo "..."
	@echo ""
	@echo "→ Testing status"
	@./bin/xcclean status
	@echo ""
	@echo "→ Testing scan"
	@./bin/xcclean scan
	@echo ""
	@echo "→ Testing scan --json"
	@./bin/xcclean scan --json | head -10
	@echo "..."
	@echo ""
	@echo "✓ All tests passed"

clean:
	@echo "Nothing to clean"
