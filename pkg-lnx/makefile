version := $(shell ../env/version.sh)
version := $(word 2,$(version))

.PHONY : all
all : deb rpm

.PHONY: deb
deb: orchid-server_$(version)_darwin-amd64.deb

.PHONY: rpm
rpm: orchid-server-$(version)-1.x86_64.rpm

orchid-server_$(version)_darwin-amd64.deb: orchid-server
	fpm -s dir -t deb -n 'orchid-server' -v $(version) --url 'https://www.orchid.com' --description 'Orchid Server Binary' --deb-no-default-config-files --deb-systemd orchid.service -d libc++1 orchid-server=/usr/bin/

orchid-server-$(version)-1.x86_64.rpm: orchid-server
	fpm -s dir -t rpm -n 'orchid-server' -v $(version) --url 'https://www.orchid.com' --description 'Orchid Server Binary' -d libc++1 orchid-server=/usr/bin/

orchid-server:
	$(MAKE) -C server target=lnx
	cp -a server/out-lnx/orchid ./orchid-server

.PHONY: clean
clean:
	rm -f orchid-server *.deb *.rpm
