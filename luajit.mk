# Include before hmod.mk. LUAJIT_FILES lists <source.lua>:<output> pairs; each output is built
# with luajit-bc.sh and added to MOD_DEPS, and `make compile` builds them all.
LUAJIT_BC ?= $(dir $(lastword $(MAKEFILE_LIST)))luajit-bc.sh

define luajit_rule
$(2): $(1)
	sh $$(LUAJIT_BC) $$< $$@
endef

$(foreach p,$(LUAJIT_FILES),$(eval $(call luajit_rule,$(word 1,$(subst :, ,$(p))),$(word 2,$(subst :, ,$(p))))))
LUAJIT_OUT := $(foreach p,$(LUAJIT_FILES),$(word 2,$(subst :, ,$(p))))
MOD_DEPS   += $(LUAJIT_OUT)

compile: $(LUAJIT_OUT)
.PHONY: compile
