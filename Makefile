.PHONY: setup project build test clean run

setup:
	@chmod +x scripts/setup.sh
	@./scripts/setup.sh

project:
	xcodegen generate

build: project
	xcodebuild build \
		-project AudioBy.xcodeproj \
		-scheme AudioBy \
		-destination 'generic/platform=iOS Simulator' \
		CODE_SIGNING_ALLOWED=NO

test: project
	xcodebuild test \
		-project AudioBy.xcodeproj \
		-scheme AudioBy \
		-destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
		CODE_SIGNING_ALLOWED=NO

clean:
	rm -rf AudioBy.xcodeproj
	rm -rf build/
