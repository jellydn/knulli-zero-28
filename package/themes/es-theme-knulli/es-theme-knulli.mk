################################################################################
#
# EmulationStation theme "Knulli"
#
################################################################################
# Version: Commits on May 17, 2026
ES_THEME_KNULLI_VERSION = a0c12e873212d969271938926d6c9b2d201690cc
ES_THEME_KNULLI_SITE = $(call github,symbuzzer,es-theme-knulli,$(ES_THEME_KNULLI_VERSION))

define ES_THEME_KNULLI_INSTALL_TARGET_CMDS
    mkdir -p $(TARGET_DIR)/usr/share/emulationstation/themes/es-theme-knulli
    cp -r $(@D)/* $(TARGET_DIR)/usr/share/emulationstation/themes/es-theme-knulli
endef

$(eval $(generic-package))
