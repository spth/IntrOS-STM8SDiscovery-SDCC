#**********************************************************#
#file     makefile
#author   Rajmund Szymanski
#date     06.05.2017
#brief    STM8 makefile.
#**********************************************************#

SDCC       := c:/sys/sdcc/bin/sd
STVP       := c:/sys/tools/stvp/stvp_cmdline -BoardName=ST-LINK -Port=USB -ProgMode=SWIM -Device=STM8S105x6 -verif -no_loop -no_log

#----------------------------------------------------------#

PROJECT    ?=
DEFS       ?=
LIBS       ?=
DIRS       ?=
KEYS       ?=
INCS       ?=
SCRIPT     ?=

#----------------------------------------------------------#

DEFS       += STM8S105
KEYS       += .sdcc *
LIBS       += stm8

#----------------------------------------------------------#

AS         := $(SDCC)asstm8
CC         := $(SDCC)cc
LD         := $(SDCC)ld
AR         := $(SDCC)ar
COPY       := $(SDCC)objcopy

SIZE       := size

RM         ?= rm -f

#----------------------------------------------------------#

DTREE       = $(foreach d,$(foreach k,$(KEYS),$(wildcard $1$k)),$(dir $d) $(call DTREE,$d/))

VPATH      := $(sort $(call DTREE,) $(foreach d,$(DIRS),$(call DTREE,$d/)))

#----------------------------------------------------------#

INC_DIRS   := $(sort $(dir $(foreach d,$(VPATH),$(wildcard $d*.h))))
LIB_DIRS   := $(sort $(dir $(foreach d,$(VPATH),$(wildcard $d*.lib))))
AS_SRCS    :=              $(foreach d,$(VPATH),$(wildcard $d*.s))
CC_SRCS    :=              $(foreach d,$(VPATH),$(wildcard $d*.c))
LIB_SRCS   :=     $(notdir $(foreach d,$(VPATH),$(wildcard $d*.lib)))

ifeq ($(strip $(PROJECT)),)
PROJECT    :=     $(notdir $(CURDIR))
endif

#----------------------------------------------------------#

ELF        := $(PROJECT).elf
HEX        := $(PROJECT).hex
LIB        := $(PROJECT).lib
MAP        := $(PROJECT).map
CDB        := $(PROJECT).cdb
LKF        := $(PROJECT).lk

OBJS       := $(AS_SRCS:.s=.rel)
OBJS       += $(CC_SRCS:.c=.rel)
ASMS       := $(OBJS:.rel=.asm)
LSTS       := $(OBJS:.rel=.lst)
RSTS       := $(OBJS:.rel=.rst)
SYMS       := $(OBJS:.rel=.sym)

#----------------------------------------------------------#

CORE_F      = -mstm8
COMMON_F    =
AS_FLAGS    = -l -o -s
CC_FLAGS    = --std-sdcc11
LD_FLAGS    =

#----------------------------------------------------------#

DEFS_F     := $(DEFS:%=-D%)

INC_DIRS   += $(INCS:%=%/)
INC_DIRS_F := $(INC_DIRS:%/=-I%)

LIB_DIRS_F := $(LIB_DIRS:%/=-L%)
LIBS_F     := $(LIBS:%=-l%)
LIBS_F     += $(LIB_SRCS:%.lib=-l%)

AS_FLAGS   +=
CC_FLAGS   += $(CORE_F) $(COMMON_F) $(DEFS_F) $(INC_DIRS_F)
LD_FLAGS   += $(CORE_F) $(COMMON_F) $(LIBS_F) $(LIB_DIRS_F)

#----------------------------------------------------------#

all : $(ELF) print_elf_size

lib : $(LIB)

$(ELF) : $(OBJS)
	$(info Linking target: $(ELF))
	$(CC) --out-fmt-elf $(LD_FLAGS) $(OBJS) -o $@

$(LIB) : $(OBJS)
	$(info Building library: $(LIB))
	$(AR) -r $@ $?

$(OBJS) : $(MAKEFILE_LIST)

%.rel : %.s
	$(info Assembling file: $<)
	$(AS) $(AS_FLAGS) $@ $<

%.rel : %.c
	$(info Compiling file: $<)
	$(CC) -c $(CC_FLAGS) $< -o $@

$(HEX) : $(OBJS)
	$(info Creating HEX image: $(HEX))
	$(CC) $(LD_FLAGS) $(OBJS) -o $@

print_elf_size : $(ELF)
	$(info Size of target file:)
	$(SIZE) -B $(ELF)

GENERATED = $(BIN) $(ELF) $(HEX) $(LIB) $(LSS) $(MAP) $(CDB) $(LKF) $(LSTS) $(OBJS) $(ASMS) $(LSTS) $(RSTS) $(SYMS)

clean :
	$(info Removing all generated output files)
	$(RM) $(GENERATED)

flash : all $(HEX)
	$(info Programing device...)
	$(STVP) -FileProg=$(HEX)

.PHONY : all lib clean flash
