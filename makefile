.PHONY: all

all: tst-tunnel

all: all-app-ios
all: all-app-sim
all: all-app-and

all: all-srv-and
all: all-srv-lnx
all: all-srv-mac
all: all-srv-win

tst-ethereum:
	$(MAKE) -C tst-ethereum test

tst-tunnel:
	$(MAKE) -C tst-tunnel target=mac

all-srv-and:
	$(MAKE) -C srv-shared target=and

all-srv-lnx:
	$(MAKE) -C srv-shared target=lnx

all-srv-mac:
	$(MAKE) -C srv-shared target=mac

all-srv-win:
	$(MAKE) -C srv-shared target=win

all-app-ios:
	$(MAKE) -C app-ios target=ios

all-app-sim:
	$(MAKE) -C app-ios target=sim

all-app-and:
	$(MAKE) -C app-android target=and
