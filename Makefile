PROJECT := Lyra.xcodeproj
SCHEME := Lyra
CONFIGURATION ?= Debug
SIMULATOR_NAME := iPhone 18 Pro
SIMULATOR_OS := 27.0
SIMULATOR_ID := 3E8101D8-44A6-4A22-8A88-A6D35EF74DEE
DESTINATION := platform=iOS Simulator,id=$(SIMULATOR_ID)
DERIVED_DATA := $(CURDIR)/build/DerivedData
APP_PATH := $(DERIVED_DATA)/Build/Products/$(CONFIGURATION)-iphonesimulator/Lyra.app
BUNDLE_ID := com.lyra.reader

.PHONY: generate resolve build test boot run clean verify-simulator

generate:
	xcodegen generate

resolve: generate
	xcodebuild -resolvePackageDependencies \
		-project $(PROJECT) \
		-scheme $(SCHEME)

verify-simulator:
	@xcrun simctl list devices available | grep -F "$(SIMULATOR_NAME) ($(SIMULATOR_ID))" >/dev/null || \
		(echo "Required simulator is unavailable: $(SIMULATOR_NAME), iOS $(SIMULATOR_OS), $(SIMULATOR_ID)" && exit 1)

build: generate verify-simulator
	xcodebuild build \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-configuration $(CONFIGURATION) \
		-destination '$(DESTINATION)' \
		-derivedDataPath $(DERIVED_DATA) \
		CODE_SIGNING_ALLOWED=NO

test: generate verify-simulator
	xcodebuild test \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination '$(DESTINATION)' \
		-derivedDataPath $(DERIVED_DATA) \
		CODE_SIGNING_ALLOWED=NO

boot: verify-simulator
	@xcrun simctl boot $(SIMULATOR_ID) 2>/dev/null || true
	xcrun simctl bootstatus $(SIMULATOR_ID) -b
	open /Applications/Xcode.app/Contents/Applications/DeviceHub.app

run: boot build
	xcrun simctl install $(SIMULATOR_ID) $(APP_PATH)
	xcrun simctl launch $(SIMULATOR_ID) $(BUNDLE_ID)

clean:
	xcodebuild clean \
		-project $(PROJECT) \
		-scheme $(SCHEME) \
		-destination '$(DESTINATION)' \
		-derivedDataPath $(DERIVED_DATA)
