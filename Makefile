APP_NAME = SmoothScroll
BUNDLE = $(APP_NAME).app
BUILD_DIR = .build/release
INSTALL_DIR = /Applications
LAUNCH_AGENT = ~/Library/LaunchAgents/com.smoothscroll.app.plist

.PHONY: build bundle run clean install uninstall

build:
	swift build -c release

bundle: build
	rm -rf $(BUNDLE)
	mkdir -p $(BUNDLE)/Contents/MacOS
	mkdir -p $(BUNDLE)/Contents/Resources
	cp $(BUILD_DIR)/$(APP_NAME) $(BUNDLE)/Contents/MacOS/
	cp Resources/Info.plist $(BUNDLE)/Contents/
	cp Resources/AppIcon.icns $(BUNDLE)/Contents/Resources/
	codesign --force --sign - $(BUNDLE)

run: bundle
	open $(BUNDLE)

install: bundle
	@echo "Installing $(APP_NAME) to $(INSTALL_DIR)..."
	cp -R $(BUNDLE) $(INSTALL_DIR)/
	@echo "Creating login item..."
	@mkdir -p ~/Library/LaunchAgents
	@printf '%s\n' \
		'<?xml version="1.0" encoding="UTF-8"?>' \
		'<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' \
		'<plist version="1.0">' \
		'<dict>' \
		'    <key>Label</key>' \
		'    <string>com.smoothscroll.app</string>' \
		'    <key>ProgramArguments</key>' \
		'    <array>' \
		'        <string>$(INSTALL_DIR)/$(BUNDLE)/Contents/MacOS/$(APP_NAME)</string>' \
		'    </array>' \
		'    <key>RunAtLoad</key>' \
		'    <true/>' \
		'</dict>' \
		'</plist>' > $(LAUNCH_AGENT)
	@echo "Done. $(APP_NAME) will start at login."

uninstall:
	@echo "Removing login item..."
	-launchctl unload $(LAUNCH_AGENT) 2>/dev/null
	-rm -f $(LAUNCH_AGENT)
	@echo "Removing $(APP_NAME) from $(INSTALL_DIR)..."
	-rm -rf $(INSTALL_DIR)/$(BUNDLE)
	@echo "Done."

clean:
	swift package clean
	rm -rf $(BUNDLE)
