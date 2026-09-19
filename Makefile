FLUTTER ?= flutter
DART ?= dart
EMULATOR ?= Pixel_8_API_36

.DEFAULT_GOAL := help
.PHONY: help start-emulator devices lint test analyze build

help:
	@printf '%s\n' \
		'make start-emulator  Resolve dependencies and start the emulator' \
		'make devices         List connected devices' \
		'make lint            Format Dart code and run lint/static analysis' \
		'make test            Run unit and widget tests' \
		'make analyze         Run strict static analysis without formatting' \
		'make build           Run tests, formatting, and analysis; build a debug APK'

start-emulator:
	$(FLUTTER) pub get
	$(FLUTTER) emulators --launch $(EMULATOR)

devices:
	$(FLUTTER) devices

lint:
	$(DART) format lib test
	$(MAKE) analyze

test:
	$(FLUTTER) test --coverage

analyze:
	$(FLUTTER) analyze --fatal-infos --fatal-warnings

build:
	$(MAKE) test
	$(MAKE) lint
	$(FLUTTER) build apk --debug