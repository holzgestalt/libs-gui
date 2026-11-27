# Build/install an application-linked appearance provider and its link metadata.
# Toolkit implementations supply their own sources and optional dependencies.
override shared = no
include $(GNUSTEP_MAKEFILES)/common.make

GS_THEME_LIBRARY := libgnustep-theme-$(GNUSTEP_THEME_NAME)
GS_THEME_ENTRY := $(GS_THEME_LIBRARY)-entry
LIBRARY_NAME = $(GS_THEME_LIBRARY) $(GS_THEME_ENTRY)
$(GS_THEME_LIBRARY)_OBJC_FILES = $(GNUSTEP_THEME_OBJC_FILES)
$(GS_THEME_LIBRARY)_C_FILES = $(GNUSTEP_THEME_C_FILES)
$(GS_THEME_LIBRARY)_HEADER_FILES = $(GNUSTEP_THEME_HEADERS)
$(GS_THEME_LIBRARY)_HEADER_FILES_INSTALL_DIR = GNUstepGUI
$(GS_THEME_ENTRY)_OBJC_FILES = $(GNUSTEP_THEME_ENTRY_SOURCE)
$(GS_THEME_ENTRY)_OBJCFLAGS = -DGS_THEME_PROVIDER=GSThemeProvider_$(GNUSTEP_THEME_NAME)

include $(GNUSTEP_MAKEFILES)/library.make

GS_THEME_PC = gnustep-theme-$(GNUSTEP_THEME_NAME).pc
GS_THEME_BUILD_PC_DIR ?= $(abspath ../pkgconfig)
GS_THEME_BUILD_LIB_DIR := $(abspath $(GNUSTEP_OBJ_DIR))
GS_THEME_INSTALL_LIB_DIR := $(GNUSTEP_LIBRARIES)/$(GNUSTEP_TARGET_LDIR)
# GNUstep already applies DESTDIR to installation directories. Metadata must
# describe the final prefix, while file copying uses the staged directory.
GS_THEME_INSTALLED_LIB_DIR := $(abspath $(if $(DESTDIR),$(patsubst $(DESTDIR)/%,%,$(GNUSTEP_LIBRARIES)),$(GNUSTEP_LIBRARIES))/$(GNUSTEP_TARGET_LDIR))
GS_THEME_LINK_LIBRARIES = -l$(patsubst lib%,%,$(GS_THEME_ENTRY)) -l$(patsubst lib%,%,$(GS_THEME_LIBRARY)) $(foreach dep,$(GNUSTEP_THEME_DEPENDENCIES),-lgnustep-theme-$(dep))
GS_THEME_BUILD_ARCHIVES = $(GS_THEME_BUILD_LIB_DIR)/$(GS_THEME_ENTRY).a $(GS_THEME_BUILD_LIB_DIR)/$(GS_THEME_LIBRARY).a $(foreach dep,$(GNUSTEP_THEME_DEPENDENCIES),$(GS_THEME_INSTALLED_LIB_DIR)/libgnustep-theme-$(dep).a)
GS_THEME_INSTALLED_ARCHIVES = $(GS_THEME_INSTALLED_LIB_DIR)/$(GS_THEME_ENTRY).a $(GS_THEME_INSTALLED_LIB_DIR)/$(GS_THEME_LIBRARY).a $(foreach dep,$(GNUSTEP_THEME_DEPENDENCIES),$(GS_THEME_INSTALLED_LIB_DIR)/libgnustep-theme-$(dep).a)
ifneq ($(findstring darwin,$(GNUSTEP_TARGET_OS)),)
GS_THEME_LOAD_START = -Wl,-all_load
GS_THEME_LOAD_END = -Wl,-noall_load
GS_THEME_EXPORT = -Wl,-export_dynamic
else ifneq ($(findstring mingw,$(GNUSTEP_TARGET_OS))$(findstring windows,$(GNUSTEP_TARGET_OS)),)
# Windows: lld refuses --export-dynamic, and a DLL can't import from the
# executable anyway; ThemeEntry.m registers the provider with the GUI DLL.
GS_THEME_LOAD_START = -Wl,--whole-archive
GS_THEME_LOAD_END = -Wl,--no-whole-archive
GS_THEME_EXPORT =
else
GS_THEME_LOAD_START = -Wl,--whole-archive
GS_THEME_LOAD_END = -Wl,--no-whole-archive
GS_THEME_EXPORT = -Wl,--export-dynamic
endif

.PHONY: gs-theme-metadata
gs-theme-metadata:
	$(MKDIRS) $(GNUSTEP_OBJ_DIR) $(GS_THEME_BUILD_PC_DIR)
	@for kind in build installed; do \
	  if test "$$kind" = build; then \
	    libdir='$(GS_THEME_BUILD_LIB_DIR)'; archives='$(GS_THEME_BUILD_ARCHIVES)'; \
	    output='$(GS_THEME_BUILD_PC_DIR)/$(GS_THEME_PC)'; \
	  else \
	    libdir='$(GS_THEME_INSTALLED_LIB_DIR)'; archives='$(GS_THEME_INSTALLED_ARCHIVES)'; \
	    output='$(GNUSTEP_OBJ_DIR)/$(GS_THEME_PC).installed'; \
	  fi; \
	  { printf '%s\n' "libdir=$$libdir" "archives=$$archives" \
	    'Name: GNUstep $(GNUSTEP_THEME_NAME) theme' \
	    'Description: Application-linked GNUstep appearance provider' \
	    'Version: 1.0' \
	    "Libs: -L$$libdir $(GS_THEME_EXPORT) $(GS_THEME_LOAD_START) $(GS_THEME_LINK_LIBRARIES) $(GS_THEME_LOAD_END) $(GNUSTEP_THEME_EXTRA_LIBS)"; \
	  } > "$$output.tmp"; \
	  if cmp -s "$$output.tmp" "$$output"; then rm "$$output.tmp"; else mv "$$output.tmp" "$$output"; fi; \
	done

after-all:: gs-theme-metadata
after-install:: gs-theme-metadata
	$(MKDIRS) $(GS_THEME_INSTALL_LIB_DIR)/pkgconfig
	$(INSTALL_DATA) $(GNUSTEP_OBJ_DIR)/$(GS_THEME_PC).installed $(GS_THEME_INSTALL_LIB_DIR)/pkgconfig/$(GS_THEME_PC)
after-uninstall::
	rm -f $(GS_THEME_INSTALL_LIB_DIR)/pkgconfig/$(GS_THEME_PC)
