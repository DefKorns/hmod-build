MOD_CREATOR ?= DefKorns
MOD_DIR     ?= mod
OUT         ?= out
MOD_VER     ?= $(patsubst v%,%,$(or $(shell git describe --tags --match 'v[0-9]*' 2>/dev/null),v0.0.0))
GIT_COMMIT  := $(shell git describe --always --dirty=.dirty 2>/dev/null)
HMOD        := $(OUT)/$(MOD_ID).hmod
HMOD_STAGE  := $(OUT)/.stage-$(MOD_ID)

hmod: $(HMOD)

$(HMOD): $(MOD_DEPS) FORCE
	@[ -n "$(MOD_ID)" ] && [ -n "$(MOD_NAME)" ] && [ -n "$(MOD_CATEGORY)" ] || { echo "hmod.mk: set MOD_ID, MOD_NAME and MOD_CATEGORY" >&2; exit 1; }
	rm -rf "$(HMOD_STAGE)" "$@"
	mkdir -p "$(HMOD_STAGE)"
	cd "$(MOD_DIR)" && tar -cf - $(if $(MOD_EXCLUDE),--exclude-from="$(CURDIR)/$(HMOD_STAGE).exclude") * | (cd "$(CURDIR)/$(HMOD_STAGE)" && tar -xf -)
	printf '%s\n' "---" "Name: $(MOD_NAME)" "Creator: $(MOD_CREATOR)" "Category: $(MOD_CATEGORY)" \
	  "Version: $(MOD_VER)" "Built on: $$(date -u +'%Y-%m-%d %H:%M UTC')" "Git commit: $(GIT_COMMIT)" "---" > "$(HMOD_STAGE)/readme.md"
	[ ! -f "$(MOD_DIR)/readme.md" ] || sed '1{/^# /d}' "$(MOD_DIR)/readme.md" >> "$(HMOD_STAGE)/readme.md"
	(cd "$(HMOD_STAGE)" && tar -czf - *) > "$@"
	rm -rf "$(HMOD_STAGE)" "$(HMOD_STAGE).exclude"
	@echo "$@ ($(MOD_VER))"

ifneq ($(MOD_EXCLUDE),)
$(HMOD): $(HMOD_STAGE).exclude
$(HMOD_STAGE).exclude: $(MOD_EXCLUDE) FORCE
	mkdir -p "$(OUT)"
	sed -e 's#/*$$##' -e '/^$$/d' "$<" > "$@"
endif

hmod-version:
	@echo $(MOD_VER)

FORCE:
.PHONY: hmod hmod-version FORCE
