.PHONY: all

all: all-app-ios
all: all-app-sim

all: all-srv-and
all: all-srv-lnx
all: all-srv-mac
#all: all-srv-win

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
