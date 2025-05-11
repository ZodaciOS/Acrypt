ARCHS = arm64 arm64e
TARGET = iphone:clang:14.0:14.0
DEPLOYMENT_TARGET = 14.0
INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Acrypt

Acrypt_FILES = Tweak.xm AcryptManager.m
Acrypt_CFLAGS = -fobjc-arc -Wno-deprecated-declarations
Acrypt_LDFLAGS = -lElleKit
Acrypt_PRIVATE_FRAMEWORKS = Preferences SpringBoardServices
Acrypt_EXTRA_FRAMEWORKS = AppList
Acrypt_LIBRARIES = hapticfeedback

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
