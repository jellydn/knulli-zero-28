################################################################################
#
# vaixterm
#
################################################################################

VAIXTERM_VERSION = fd79eab34137347e5f2c54b32804f47ca48bf50a
VAIXTERM_SITE = $(call github,Stanley00,vaixterm,$(VAIXTERM_VERSION))
VAIXTERM_LICENSE = MIT
VAIXTERM_LICENSE_FILES = LICENSE

VAIXTERM_DEPENDENCIES = sdl2 sdl2_ttf sdl2_image host-pkgconf

# Vendored libvterm (upstream CI uses 0.3.3)
VAIXTERM_LIBVTERM_VERSION = 0.3.3
VAIXTERM_LIBVTERM_SOURCE = libvterm-$(VAIXTERM_LIBVTERM_VERSION).tar.gz
VAIXTERM_EXTRA_DOWNLOADS = https://www.leonerd.org.uk/code/libvterm/$(VAIXTERM_LIBVTERM_SOURCE)

define VAIXTERM_EXTRACT_LIBVTERM
	mkdir -p $(@D)/vendor/libvterm
	$(TAR) -C $(@D)/vendor/libvterm --strip-components=1 \
		-xf $(VAIXTERM_DL_DIR)/$(VAIXTERM_LIBVTERM_SOURCE)
endef
VAIXTERM_POST_EXTRACT_HOOKS += VAIXTERM_EXTRACT_LIBVTERM

VAIXTERM_SDL_CFLAGS = $(shell $(PKG_CONFIG_HOST_BINARY) --cflags sdl2 SDL2_ttf SDL2_image)
VAIXTERM_SDL_LIBS = $(shell $(PKG_CONFIG_HOST_BINARY) --libs sdl2 SDL2_ttf SDL2_image)

define VAIXTERM_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) $(TARGET_CONFIGURE_OPTS) \
		PKG_CONFIG="$(PKG_CONFIG_HOST_BINARY)" \
		CFLAGS="$(TARGET_CFLAGS) $(VAIXTERM_SDL_CFLAGS) -Iinclude -Isrc -Ivendor/libvterm/include -Ivendor/libvterm/src" \
		LDFLAGS="$(TARGET_LDFLAGS) $(VAIXTERM_SDL_LIBS) -lm" \
		-C $(@D)
endef

define VAIXTERM_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/vaixterm $(TARGET_DIR)/usr/bin/vaixterm
endef

define VAIXTERM_INSTALL_RES_CMDS
	if [ -d $(@D)/res ]; then \
		$(INSTALL) -d $(TARGET_DIR)/usr/share/vaixterm/res && \
		cp -r $(@D)/res/* $(TARGET_DIR)/usr/share/vaixterm/res/; \
	fi
endef
VAIXTERM_POST_INSTALL_TARGET_HOOKS += VAIXTERM_INSTALL_RES_CMDS

$(eval $(generic-package))
