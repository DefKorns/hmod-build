HMOD_BUILD  := $(dir $(lastword $(MAKEFILE_LIST)))
MOD_CREATOR ?= DefKorns
MOD_DIR     ?= mod
OUT         ?= out
MOD_VER     ?= $(patsubst v%,%,$(or $(shell git describe --tags --match 'v[0-9]*' 2>/dev/null),v0.0.0))
GIT_COMMIT  := $(shell git describe --always --dirty=.dirty 2>/dev/null)
SOURCE_DATE_EPOCH ?= $(shell git log -1 --format=%ct 2>/dev/null || date +%s)
HMOD        := $(OUT)/$(MOD_ID).hmod
HMOD_STAGE  := $(OUT)/.stage-$(MOD_ID)

hmod: $(HMOD)

$(HMOD): $(MOD_DEPS) FORCE
	@[ -n "$(MOD_ID)" ] && [ -n "$(MOD_NAME)" ] && [ -n "$(MOD_CATEGORY)" ] || { echo "hmod.mk: set MOD_ID, MOD_NAME and MOD_CATEGORY" >&2; exit 1; }
	rm -rf "$(HMOD_STAGE)" "$@"
	mkdir -p "$(HMOD_STAGE)"
	cd "$(MOD_DIR)" && tar -cf - $(if $(MOD_EXCLUDE),--exclude-from="$(CURDIR)/$(HMOD_STAGE).exclude") * | (cd "$(CURDIR)/$(HMOD_STAGE)" && tar -xf -)
	printf '%s\n' "---" "Name: $(MOD_NAME)" "Creator: $(MOD_CREATOR)" $(if $(MOD_BUILD_BY),"Build by: $(MOD_BUILD_BY)") "Category: $(MOD_CATEGORY)" \
	  "Version: $(MOD_VER)" "Built on: $$(date -u -d @$(SOURCE_DATE_EPOCH) +'%Y-%m-%d %H:%M UTC')" "Git commit: $(GIT_COMMIT)" $(if $(MOD_EMULATED_SYSTEM),"Emulated System: $(MOD_EMULATED_SYSTEM)") "---" > "$(HMOD_STAGE)/readme.md"
ifneq ($(findstring -,$(MOD_VER)),)
	prev=$$(git describe --tags --abbrev=0 --match 'v[0-9]*' HEAD^ 2>/dev/null) && \
	  { printf '%s\n' "" "## Changes since $$prev" ""; git log --no-merges --reverse --format='- %s' "$$prev..HEAD"; echo; } >> "$(HMOD_STAGE)/readme.md" || true
endif
	[ ! -f "$(MOD_DIR)/readme.md" ] || sed '1{/^# /d}' "$(MOD_DIR)/readme.md" >> "$(HMOD_STAGE)/readme.md"
	@for dep in $(patsubst $(MOD_DIR)/%,%,$(filter $(MOD_DIR)/%,$(MOD_DEPS))); do \
	  [ -s "$(HMOD_STAGE)/$$dep" ] || { echo "hmod.mk: $$dep is missing or empty in the hmod" >&2; exit 1; }; \
	done
	sh "$(HMOD_BUILD)hmod-check.sh" "$(HMOD_STAGE)" "$(MOD_ID)"
	cd "$(HMOD_STAGE)" && find . -type d -exec chmod 755 {} + && find . -type f -exec chmod 644 {} + && 	  find . -type f \( -name install -o -name uninstall -o -exec sh -c 'head -c 4 "$$1" | grep -aq "^#!\|^.ELF"' _ {} \; \) -exec chmod 755 {} +
	cd "$(HMOD_STAGE)" && find . -mindepth 1 | sed 's,^./,,' | LC_ALL=C sort | tar --no-recursion --owner=0 --group=0 --numeric-owner --mtime=@$(SOURCE_DATE_EPOCH) -cf ../.tmp-$(MOD_ID).tar -T -
	gzip -n < "$(OUT)/.tmp-$(MOD_ID).tar" > "$@" && rm -f "$(OUT)/.tmp-$(MOD_ID).tar"
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
