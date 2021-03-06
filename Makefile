####################################################################
# Makefile                                                         #
####################################################################

.SUFFIXES:				# ignore builtin rules
.PHONY: all debug release clean gdb_server gdb flash verify src/compile_date.h

####################################################################
# Definitions                                                      #
####################################################################

DEVICE = EFM32GG232F1024
PROJECTNAME = bootloader

OBJ_DIR = build
EXE_DIR = exe
LST_DIR = lst

####################################################################
# Definitions of toolchain.                                        #
# You might need to do changes to match your system setup          #
####################################################################

# Change path to the tools according to your system configuration
# DO NOT add trailing whitespace chars, they do matter !
WINDOWSCS  ?= GNU Tools ARM Embedded\4.7 2012q4
LINUXCS    ?= $(HOME)/.software/arm-2012.03
#LINUXCS    ?= $(HOME)/.software/summon-arm-toolchain/sat
#LINUXCS    ?= $(HOME)/.software/gcc-arm-none-eabi-4_8-2013q4
#LINUXCS    ?= $(HOME)/.software/gcc-arm-none-eabi-4_7-2013q3

SIMPSTUDIO ?= $(HOME)/.software/energymicro_1.2
RMDIRS     := rm -rf
RMFILES    := rm -rf
ALLFILES   := /*.*
NULLDEVICE := /dev/null
SHELLNAMES := $(ComSpec)$(COMSPEC)

# Try autodetecting the environment
ifeq ($(SHELLNAMES),)
  # Assume we are making on a Linux platform
  TOOLDIR := $(LINUXCS)
else
  QUOTE :="
  ifneq ($(COMSPEC),)
    # Assume we are making on a mingw/msys/cygwin platform running on Windows
    # This is a convenient place to override TOOLDIR, DO NOT add trailing
    # whitespace chars, they do matter !
    TOOLDIR := $(PROGRAMFILES)/$(WINDOWSCS)
    ifeq ($(findstring cygdrive,$(shell set)),)
      # We were not on a cygwin platform
      NULLDEVICE := NUL
    endif
  else
    # Assume we are making on a Windows platform
    # This is a convenient place to override TOOLDIR, DO NOT add trailing
    # whitespace chars, they do matter !
    SHELL      := $(SHELLNAMES)
    TOOLDIR    := $(ProgramFiles)/$(WINDOWSCS)
    RMDIRS     := rd /s /q
    RMFILES    := del /s /q
    ALLFILES   := \*.*
    NULLDEVICE := NUL
  endif
endif

# Create directories and do a clean which is compatible with parallell make
$(shell mkdir $(OBJ_DIR)>$(NULLDEVICE) 2>&1)
$(shell mkdir $(EXE_DIR)>$(NULLDEVICE) 2>&1)
$(shell mkdir $(LST_DIR)>$(NULLDEVICE) 2>&1)
ifeq (clean,$(findstring clean, $(MAKECMDGOALS)))
  ifneq ($(filter $(MAKECMDGOALS),all debug release),)
    $(shell $(RMFILES) $(OBJ_DIR)$(ALLFILES)>$(NULLDEVICE) 2>&1)
    $(shell $(RMFILES) $(EXE_DIR)$(ALLFILES)>$(NULLDEVICE) 2>&1)
    $(shell $(RMFILES) $(LST_DIR)$(ALLFILES)>$(NULLDEVICE) 2>&1)
  endif
endif

CC      = $(QUOTE)$(TOOLDIR)/bin/arm-none-eabi-gcc$(QUOTE)
LD      = $(QUOTE)$(TOOLDIR)/bin/arm-none-eabi-ld$(QUOTE)
AR      = $(QUOTE)$(TOOLDIR)/bin/arm-none-eabi-ar$(QUOTE)
OBJCOPY = $(QUOTE)$(TOOLDIR)/bin/arm-none-eabi-objcopy$(QUOTE)
DUMP    = $(QUOTE)$(TOOLDIR)/bin/arm-none-eabi-objdump$(QUOTE)
GDB     = $(QUOTE)$(TOOLDIR)/bin/arm-none-eabi-gdb$(QUOTE) -ex "tar rem :2331"

JLINKPATH  := $(HOME)/.software/JLink_Linux_V480e_i386
GDB_SERVER := $(JLINKPATH)/JLinkGDBServer -if SWD -speed 50
FLASH      := $(JLINKPATH)/JLinkExe ./FlashBootloader.txt
VERIFY     := $(JLINKPATH)/JLinkExe ./VerifyBootloader.txt

####################################################################
# Flags                                                            #
####################################################################

# -MMD : Don't generate dependencies on system header files.
# -MP  : Add phony targets, useful when a h-file is removed from a project.
# -MF  : Specify a file to write the dependencies to.
DEPFLAGS = -MMD -MP -MF $(@:.o=.d)

#
# Add -Wa,-ahld=$(LST_DIR)/$(@F:.o=.lst) to CFLAGS to produce assembly list files
#
override CFLAGS += -D$(DEVICE) -Wall -Wextra -mcpu=cortex-m3 -mthumb -mfix-cortex-m3-ldrd \
-ffunction-sections -fdata-sections -fomit-frame-pointer -Wl,--gc-sections\
$(DEPFLAGS)

override ASMFLAGS += -x assembler-with-cpp -D$(DEVICE) -Wall -Wextra -mcpu=cortex-m3 -mthumb

#
# NOTE: The -Wl,--gc-sections flag may interfere with debugging using gdb.
#
override LDFLAGS += -Xlinker -Map=$(LST_DIR)/$(PROJECTNAME).map -dead-strip -mcpu=cortex-m3 \
-mthumb -Tefm32gg.ld  -Wl,--gc-sections #-nostartfiles

LIBS = -Wl,--start-group -Wl,--end-group
LIBS += -lcs3 -lcs3unhosted 
#LIBS += -lnosys

INCLUDEPATHS += -Isrc \
-Isrc/config_gg \
-Isrc/fatfs/inc \
-I$(SIMPSTUDIO)/CMSIS/Include \
-I$(SIMPSTUDIO)/Device/EnergyMicro/EFM32GG/Include \
-I$(SIMPSTUDIO)/emlib/inc \
-I$(SIMPSTUDIO)/kits/common/bsp \
-I$(SIMPSTUDIO)/kits/common/drivers \
-I./src/sdconfig/lopoboard/
#-I$(SIMPSTUDIO)/EFM32GG_DK3750/config/microsdconfig.h
#-I$(SIMPSTUDIO)/EFM32G_DK3550/config/microsdconfig.h
#-I$(SIMPSTUDIO)/EFM32LG_DK3650/config/microsdconfig.h
#-I$(SIMPSTUDIO)/EFM32WG_DK3850/config/microsdconfig.h
#-I$(SIMPSTUDIO)/EFM32_Gxxx_DK/config/microsdconfig.h

####################################################################
# Files                                                            #
####################################################################


C_SRC +=  src/autobaud.c \
src/boot.c \
src/bootloader.c \
src/crc.c \
src/flash.c \
src/usart.c \
src/xmodem.c \
src/debuglock.c \
src/system_efm32gg.c \
src/fatfs/src/ff.c \
src/fatfs/src/diskio.c \
src/microsd.c \
$(SIMPSTUDIO)/emlib/src/em_cmu.c \
$(SIMPSTUDIO)/emlib/src/em_gpio.c \
$(SIMPSTUDIO)/emlib/src/em_usart.c 

#src/debug.c \
#src/leuart.c \
#src/iarwrite.c \

s_SRC +=

s_SRC += src/startup_efm32gg.s

####################################################################
# Rules                                                            #
####################################################################

C_FILES = $(notdir $(C_SRC) )
S_FILES = $(notdir $(S_SRC) $(s_SRC) )
#make list of source paths, sort also removes duplicates
C_PATHS = $(sort $(dir $(C_SRC) ) )
S_PATHS = $(sort $(dir $(S_SRC) $(s_SRC) ) )

C_OBJS = $(addprefix $(OBJ_DIR)/, $(C_FILES:.c=.o))
S_OBJS = $(if $(S_SRC), $(addprefix $(OBJ_DIR)/, $(S_FILES:.S=.o)))
s_OBJS = $(if $(s_SRC), $(addprefix $(OBJ_DIR)/, $(S_FILES:.s=.o)))
C_DEPS = $(addprefix $(OBJ_DIR)/, $(C_FILES:.c=.d))
OBJS = $(C_OBJS) $(S_OBJS) $(s_OBJS)

vpath %.c $(C_PATHS)
vpath %.s $(S_PATHS)
vpath %.S $(S_PATHS)

# Default build is debug build
all:      release

debug:    CFLAGS += -DDEBUG -O0 -g3
debug:    src/compile_date.h $(EXE_DIR)/$(PROJECTNAME).bin
	@rm -rf src/compile_date.h

release:  CFLAGS += -DNDEBUG -Os -g3 
release:  src/compile_date.h $(EXE_DIR)/$(PROJECTNAME).bin
	@rm -rf src/compile_date.h

gdb_server:
	$(GDB_SERVER)
gdb:
	$(GDB) $(EXE_DIR)/$(PROJECTNAME).out
flash:
	$(FLASH)
	@echo "" #JLinkExe has exit code 1 if a script exits with qc *sigh*
verify:
	$(VERIFY)
	@echo "" #JLinkExe has exit code 1 if a script exits with qc *sigh*

src/compile_date.h:
	@echo "#define COMPILE_DATE "\"`date +%Y-%m-%d`\" > src/compile_date.h

# Create objects from C SRC files
$(OBJ_DIR)/%.o: %.c
	@echo "Building file: $<"
	$(CC) $(CFLAGS) $(INCLUDEPATHS) -c -o $@ $<

# Assemble .s/.S files
$(OBJ_DIR)/%.o: %.s
	@echo "Assembling $<"
	$(CC) $(ASMFLAGS) $(INCLUDEPATHS) -c -o $@ $<

$(OBJ_DIR)/%.o: %.S
	@echo "Assembling $<"
	$(CC) $(ASMFLAGS) $(INCLUDEPATHS) -c -o $@ $<

# Link
$(EXE_DIR)/$(PROJECTNAME).out: $(OBJS)
	@echo "Linking target: $@"
	$(CC) $(LDFLAGS) $(OBJS) $(LIBS) -o $(EXE_DIR)/$(PROJECTNAME).out

# Create binary file
$(EXE_DIR)/$(PROJECTNAME).bin: $(EXE_DIR)/$(PROJECTNAME).out
	@echo "Creating binary file"
	$(OBJCOPY) -O binary $(EXE_DIR)/$(PROJECTNAME).out $(EXE_DIR)/$(PROJECTNAME).bin
# Uncomment next line to produce assembly listing of entire program
#	$(DUMP) -h -S -C $(EXE_DIR)/$(PROJECTNAME).out>$(LST_DIR)/$(PROJECTNAME)out.lst

clean:
ifeq ($(filter $(MAKECMDGOALS),all debug release),)
	$(RMDIRS) $(OBJ_DIR) $(LST_DIR) $(EXE_DIR)
endif

# include auto-generated dependency files (explicit rules)
ifneq (clean,$(findstring clean, $(MAKECMDGOALS)))
-include $(C_DEPS)
endif
