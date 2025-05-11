ARCHS = arm64 arm64e               # Device architectures to support
TARGET = iphone:clang:latest:15.0  # Target iOS version
INSTALL_TARGET_PROCESSES = SpringBoard  # Process to inject into

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Acrypt

AppLocker_FILES = Tweak.xm
AppLocker_CFLAGS = -fobjc-arc -I/var/jb/include  # Compiler flags
AppLocker_LDFLAGS = -L/var/jb/lib -lElleKit      # Linker flags
AppLocker_FRAMEWORKS = UIKit LocalAuthentication # Apple frameworks we need
AppLocker_PRIVATE_FRAMEWORKS = Preferences       # Private Apple frameworks
AppLocker_EXTRA_FRAMEWORKS = AppList             # Third-party frameworks
AppLocker_INSTALL_PATH = /var/jb/Library/TweakInject  # Rootless install path

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"  # Respring after install