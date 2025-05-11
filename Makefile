ARCHS = arm64 arm64e               # Device architectures to support
TARGET = iphone:clang:latest:15.0  # Target iOS version
INSTALL_TARGET_PROCESSES = SpringBoard  # Process to inject into

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Acrypt

Acrypt_FILES = Tweak.xm
Acrypt_CFLAGS = -fobjc-arc -I/var/jb/include  # Compiler flags
Acrypt_LDFLAGS = -L/var/jb/lib -lElleKit      # Linker flags
Acrypt_FRAMEWORKS = UIKit LocalAuthentication # Apple frameworks we need
Acrypt_PRIVATE_FRAMEWORKS = Preferences       # Private Apple frameworks
Acrypt_EXTRA_FRAMEWORKS = AppList             # Third-party frameworks
Acrypt_INSTALL_PATH = /var/jb/Library/TweakInject  # Rootless install path
Acrypt_PRIVATE_FRAMEWORKS += SpringBoardServices FrontBoard
Acrypt_EXTRA_FRAMEWORKS += ElleKit

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"  # Respring after install
