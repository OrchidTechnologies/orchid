include env/common.mk
-include local.mk

.PHONY: all

all: cli-lnx
all: cli-mac
all: cli-win

all: app-ios
all: app-and
all: app-mac

all: srv-lnx
all: srv-mac
all: srv-win

.PHONY: tst-ethereum
tst-ethereum:
	$(MAKE) -C tst-ethereum test

.PHONY: cli-lnx
cli-lnx:
	$(MAKE) -C cli-shared target=lnx

.PHONY: cli-mac
cli-mac:
	$(MAKE) -C cli-shared target=mac

.PHONY: cli-win
cli-win:
	$(MAKE) -C cli-shared target=win

.PHONY: tst-win
tst-win:
	$(MAKE) -C tst-network target=win

.PHONY: srv-and
srv-and:
	$(MAKE) -C srv-daemon target=and

.PHONY: srv-lnx
srv-lnx:
	$(MAKE) -C srv-daemon target=lnx

.PHONY: srv-mac
srv-mac:
	$(MAKE) -C srv-daemon target=mac

.PHONY: srv-win
srv-win:
	$(MAKE) -C srv-daemon target=win

.PHONY: app-ios
app-ios:
	$(MAKE) -C app-ios target=ios

.PHONY: app-sim
app-sim:
	$(MAKE) -C app-ios target=sim

.PHONY: app-and
app-and:
	$(MAKE) -C app-android target=and

.PHONY: app-mac
app-mac:
	$(MAKE) -C app-macos target=mac


.PHONY: github
github: app-and cli-lnx cli-mac cli-win srv-lnx srv-mac srv-win
	./github.sh $(github)
