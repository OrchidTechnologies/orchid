.PHONY: all

all: all-cli-lnx
all: all-cli-mac

all: all-app-ios
all: all-app-sim
all: all-app-and

all: all-srv-and
all: all-srv-lnx
all: all-srv-mac
#all: all-srv-win

.PHONY: tst-ethereum
tst-ethereum:
	$(MAKE) -C tst-ethereum test

.PHONY: all-cli-lnx
all-cli-lnx:
	$(MAKE) -C cli-shared target=lnx

.PHONY: all-cli-mac
all-cli-mac:
	$(MAKE) -C cli-shared target=mac

.PHONY: all-srv-and
all-srv-and:
	$(MAKE) -C srv-shared target=and

.PHONY: all-srv-lnx
all-srv-lnx:
	$(MAKE) -C srv-shared target=lnx

.PHONY: all-srv-mac
all-srv-mac:
	$(MAKE) -C srv-shared target=mac

.PHONY: all-srv-win
all-srv-win:
	$(MAKE) -C srv-shared target=win

.PHONY: all-app-ios
all-app-ios:
	$(MAKE) -C app-ios target=ios

.PHONY: all-app-sim
all-app-sim:
	$(MAKE) -C app-ios target=sim

.PHONY: all-app-and
all-app-and:
	$(MAKE) -C app-android target=and
