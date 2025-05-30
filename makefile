PACKAGE_TARNAME      ?= gz
PACKAGE_URL          ?= github.com/glankk/gz
target                = mips64
program_prefix        = $(target)-
AS                    = $(program_prefix)as
CCAS                  = $(program_prefix)gcc -x assembler-with-cpp
CPP                   = $(program_prefix)cpp
CC                    = $(program_prefix)gcc
CXX                   = $(program_prefix)g++
LD                    = $(program_prefix)g++
OBJCOPY               = $(program_prefix)objcopy
NM                    = $(program_prefix)nm
READELF               = $(program_prefix)readelf
GENHOOKS              = AS='$(AS)' CPP='$(CPP)' NM='$(NM)' READELF='$(READELF)' CPPFLAGS='$(subst ','\'',$(CPPFLAGS))' ./genhooks
LUAPATCH              = luapatch
GRC                   = AS='$(AS)' grc
LDSCRIPT              = gl-n64.ld
ALL_CPPFLAGS          = -DPACKAGE_TARNAME='$(PACKAGE_TARNAME)' -DPACKAGE_URL='$(PACKAGE_URL)' -DF3DEX_GBI_2 $(CPPFLAGS)
ALL_CFLAGS            = -std=gnu11 -Wall -ffunction-sections -fdata-sections $(CFLAGS)
ALL_CXXFLAGS          = -std=gnu++14 -Wall -ffunction-sections -fdata-sections $(CXXFLAGS)
ALL_LDFLAGS           = -T $(LDSCRIPT) -nostartfiles -specs=nosys.specs -Wl,--gc-sections $(LDFLAGS)
ALL_LDLIBS            = $(LDLIBS)
LUAFILE               = $(EMUDIR)/Lua/patch-data.lua
RESDESC               = $(RESDIR)/resources.json
GZ_VERSIONS           = oot-1.0 oot-1.1 oot-1.2 oot-mq-j oot-1.2-vc oot-mq-j-vc
GZ_ADDRESS            = 80400060
LDR_ADDRESS           = 80000400
SRCDIR                = src
RESDIR                = res
OBJDIR                = obj
BINDIR                = bin
ASMFILES              = *.S
CFILES                = *.c
CXXFILES              = *.cpp *.cxx *.cc *.c++

OOT-1.0               = $(OBJ-gz-oot-1.0) $(ELF-gz-oot-1.0) $(HOOKS-gz-oot-1.0)
OOT-1.1               = $(OBJ-gz-oot-1.1) $(ELF-gz-oot-1.1) $(HOOKS-gz-oot-1.1)
OOT-1.2               = $(OBJ-gz-oot-1.2) $(ELF-gz-oot-1.2) $(HOOKS-gz-oot-1.2)
OOT-MQ-J              = $(OBJ-gz-oot-mq-j) $(ELF-gz-oot-mq-j) $(HOOKS-gz-oot-mq-j)
N64                   = $(OOT-1.0) $(OOT-1.1) $(OOT-1.2) $(OOT-MQ-J)
OOT-1.2-VC            = $(OBJ-gz-oot-1.2-vc) $(ELF-gz-oot-1.2-vc) $(HOOKS-gz-oot-1.2-vc)
OOT-MQ-J-VC           = $(OBJ-gz-oot-mq-j-vc) $(ELF-gz-oot-mq-j-vc) $(HOOKS-gz-oot-mq-j-vc)
VC                    = $(OOT-1.2-VC) $(OOT-MQ-J-VC)

GZ                    = $(foreach v,$(GZ_VERSIONS),gz-$(v))
HOOKS                 = $(foreach v,$(GZ_VERSIONS),gz-$(v)-hooks)
all                   : $(GZ)
all-hooks             : $(HOOKS)
clean                 : clean-hooks
	rm -rf $(OBJDIR) $(BINDIR)
clean-hooks           : $(foreach v,$(HOOKS),clean-$(v))
distclean             :
	rm -rf patch/ups patch/*.z64 patch/*.wad
.PHONY                : all clean distclean

define bin_template
 NAME-$(1)            = $(2)
 DIR-$(1)             = $(3)
 SRCDIR-$(1)          = $(4)
 RESDIR-$(1)          = $(5)
 OBJDIR-$(1)          = $(6)
 BINDIR-$(1)          = $(7)
 OUTDIR-$(1)          = $$(OBJDIR-$(1)) $$(OBJDIR-$(1))/$$(RESDIR) $$(BINDIR-$(1))
 ADDRESS-$(1)         = $(8)
 ASMSRC-$(1)         := $$(foreach s,$$(ASMFILES),$$(wildcard $$(SRCDIR-$(1))/$$(s)))
 CSRC-$(1)           := $$(foreach s,$$(CFILES),$$(wildcard $$(SRCDIR-$(1))/$$(s)))
 CXXSRC-$(1)         := $$(foreach s,$$(CXXFILES),$$(wildcard $$(SRCDIR-$(1))/$$(s)))
 RESSRC-$(1)         := $$(wildcard $$(RESDIR-$(1))/*)
 ASMOBJ-$(1)          = $$(patsubst $$(SRCDIR-$(1))/%,$$(OBJDIR-$(1))/%.o,$$(ASMSRC-$(1)))
 COBJ-$(1)            = $$(patsubst $$(SRCDIR-$(1))/%,$$(OBJDIR-$(1))/%.o,$$(CSRC-$(1)))
 CXXOBJ-$(1)          = $$(patsubst $$(SRCDIR-$(1))/%,$$(OBJDIR-$(1))/%.o,$$(CXXSRC-$(1)))
 RESOBJ-$(1)          = $$(patsubst $$(RESDIR-$(1))/%,$$(OBJDIR-$(1))/$$(RESDIR)/%.o,$$(RESSRC-$(1)))
 OBJ-$(1)             = $$(ASMOBJ-$(1)) $$(COBJ-$(1)) $$(CXXOBJ-$(1)) $$(RESOBJ-$(1))
 DEPS-$(1)            = $$(patsubst %.o,%.d,$$(OBJ-$(1)))
 BIN-$(1)             = $$(BINDIR-$(1))/$$(NAME-$(1)).bin
 ELF-$(1)             = $$(BINDIR-$(1))/$$(NAME-$(1)).elf
 BUILD-$(1)           = $(1)
 CLEAN-$(1)           = clean-$(1)
 -include $$(DEPS-$(1))
 $$(ELF-$(1))         : ALL_LDFLAGS          += -Wl,--defsym,start=0x$$(ADDRESS-$(1))
 $$(BUILD-$(1))       : $$(BIN-$(1))
 $$(CLEAN-$(1))       :
	rm -rf $$(OUTDIR-$(1))
 .PHONY               : $$(BUILD-$(1)) $$(CLEAN-$(1))
 $$(BIN-$(1))         : $$(ELF-$(1)) | $$(BINDIR-$(1))
	$$(OBJCOPY) -S -O binary $$< $$@
 $$(ELF-$(1))         : $$(OBJ-$(1)) | $$(BINDIR-$(1))
	$$(LD) $$(ALL_LDFLAGS) $$^ $$(ALL_LDLIBS) -o $$@
 $$(ASMOBJ-$(1))      : $$(OBJDIR-$(1))/%.o: $$(SRCDIR-$(1))/% | $$(OBJDIR-$(1))
	$$(CCAS) -c -MMD -MP $$(ALL_CPPFLAGS) $$< -o $$@
 $$(COBJ-$(1))        : $$(OBJDIR-$(1))/%.o: $$(SRCDIR-$(1))/% | $$(OBJDIR-$(1))
	$$(CC) -c -MMD -MP $$(ALL_CPPFLAGS) $$(ALL_CFLAGS) $$< -o $$@
 $$(CXXOBJ-$(1))      : $$(OBJDIR-$(1))/%.o: $$(SRCDIR-$(1))/% | $$(OBJDIR-$(1))
	$$(CXX) -c -MMD -MP $$(ALL_CPPFLAGS) $$(ALL_CXXFLAGS) $$< -o $$@
 $$(RESOBJ-$(1))      : $$(OBJDIR-$(1))/$$(RESDIR)/%.o: $$(RESDIR-$(1))/% $$(RESDESC) | $$(OBJDIR-$(1))/$$(RESDIR)
	$$(GRC) $$< -d $$(RESDESC) -o $$@
 $$(OUTDIR-$(1))      :
	mkdir -p $$@

endef

define hooks_template
 HOOKS-$(1)           = $$(DIR-$(1))/hooks.gsc
 $$(HOOKS-$(1))       : $$(ELF-$(1))
	$$(GENHOOKS) $$< >$$@
 $(1)-hooks           : $$(HOOKS-$(1))
 clean-$(1)-hooks     :
	rm -f $$(HOOKS-$(1))
 .PHONY               : $(1)-hooks clean-$(1)-hooks

endef

define lua_template
 BUILD-$(1)-lua       = $(1)-lua
 CLEAN-$(1)-lua       = clean-$(1)-lua
 $(1)-lua             : $(1)
 clean-$(1)-lua       : clean-$(1)
 $$(BUILD-$(1)-lua)   : $(1)-hooks
	$$(LUAPATCH) $(2) -text $$(HOOKS-$(1)) -bin $$(ADDRESS-$(1)) $$(BIN-$(1))
 $$(CLEAN-$(1)-lua)   :
	rm -f $(2)
 .PHONY               : $$(BUILD-$(1)-lua) $$(CLEAN-$(1)-lua)

endef

$(foreach v,$(GZ_VERSIONS),$(eval \
 $(call bin_template,gz-$(v),gz,$(v),$(SRCDIR)/gz,$(RESDIR)/gz,$(OBJDIR)/gz/$(v),$(BINDIR)/gz/$(v),$(GZ_ADDRESS)) \
 $(call hooks_template,gz-$(v)) \
 $(call lua_template,gz-$(v),$(LUAFILE)) \
))

$(OOT-1.0)            : CPPFLAGS             ?= -DZ64_VERSION=Z64_OOT10
$(OOT-1.1)            : CPPFLAGS             ?= -DZ64_VERSION=Z64_OOT11
$(OOT-1.2)            : CPPFLAGS             ?= -DZ64_VERSION=Z64_OOT12
$(OOT-MQ-J)           : CPPFLAGS             ?= -DZ64_VERSION=Z64_OOTMQJ
$(OOT-1.2-VC)         : CPPFLAGS             ?= -DZ64_VERSION=Z64_OOT12 -DWIIVC
$(OOT-MQ-J-VC)        : CPPFLAGS             ?= -DZ64_VERSION=Z64_OOTMQJ -DWIIVC
$(N64)                : CFLAGS               ?= -O3 -flto -ffat-lto-objects
$(VC)                 : CFLAGS               ?= -O1 -fno-reorder-blocks
$(N64)                : CXXFLAGS             ?= -O3 -flto -ffat-lto-objects
$(VC)                 : CXXFLAGS             ?= -O1 -fno-reorder-blocks
$(N64)                : LDFLAGS              ?= -O3 -flto

$(eval $(call bin_template,ldr,ldr,,$(SRCDIR)/ldr,$(RESDIR)/ldr,$(OBJDIR)/ldr,$(BINDIR)/ldr,$(LDR_ADDRESS)))
