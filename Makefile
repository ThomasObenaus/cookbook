FLUTTER ?= flutter
DART ?= dart
EMULATOR ?= Pixel_8_API_36
DEVICE ?= emulator-5554

.DEFAULT_GOAL := help
.PHONY: help start-emulator devices lint test integration-test analyze build release

help:
	@printf '%s\n' \
		'make start-emulator  Resolve dependencies and start the emulator' \
		'make devices         List connected devices' \
		'make lint            Format Dart code and run lint/static analysis' \
		'make test            Run unit and widget tests' \
		'make integration-test Run Android integration tests (DEVICE=emulator-5554 by default)' \
		'make analyze         Run strict static analysis without formatting' \
		'make build           Run tests, formatting, and analysis; build a debug APK' \
		'make release         Check formatting, analyze, and test; build a signed release AAB'

start-emulator:
	$(FLUTTER) pub get
	$(FLUTTER) emulators --launch $(EMULATOR)

devices:
	$(FLUTTER) devices

lint:
	$(DART) format lib test integration_test
	$(MAKE) analyze

test:
	$(FLUTTER) test --coverage

integration-test:
	$(FLUTTER) test integration_test -d "$(DEVICE)"

analyze:
	$(FLUTTER) analyze --fatal-infos --fatal-warnings

build:
	$(MAKE) test
	$(MAKE) lint
	$(FLUTTER) build apk --debug

release:
	$(DART) format --output=none --set-exit-if-changed .
	$(MAKE) analyze
	$(MAKE) test
	$(FLUTTER) build appbundle --release