################################################################################
#
# EmulationStation theme "Knulli"
#
################################################################################
# Version: Commits on May 01, 2026
ES_THEME_KNULLI_VERSION = cc62a2b60007256ef3f6e9ecf2ee9a9d01e25d68
ES_THEME_KNULLI_SITE = $(call github,symbuzzer,es-theme-knulli,$(ES_THEME_KNULLI_VERSION))

define ES_THEME_KNULLI_INSTALL_TARGET_CMDS
    mkdir -p $(TARGET_DIR)/usr/share/emulationstation/themes/es-theme-knulli
    cp -r $(@D)/* $(TARGET_DIR)/usr/share/emulationstation/themes/es-theme-knulli
endef

$(eval $(generic-package))
