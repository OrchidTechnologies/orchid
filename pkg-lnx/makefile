version := $(shell ../env/version.sh)
version := $(word 2,${version})

help2man := help2man --no-info --section 8 --output orchid.8 --name 'Run an Orchid Server' --version-string 'orchid ${version}' ./man_wrapper.sh

docker := docker run -i --rm --name "orchid" -v "${PWD}:/workdir" ubuntu:bionic

fpm_deb := fpm -s dir -t deb -n 'orchid-server' -v ${version} -a all --url 'https://www.orchid.com' --description 'Orchid Server Binary' --deb-no-default-config-files --deb-systemd orchid.service -d libc++1 orchid-server=/usr/bin/orchid orchid.8=/usr/share/man/man8/orchid.8 orchid.conf=/etc/orchid.conf

fpm_rpm := fpm -s dir -t rpm -n 'orchid-server' -v $(subst +,.,${version}) --url 'https://www.orchid.com' --description 'Orchid Server Binary' -d libcxx orchid-server=/usr/bin/ orchid.8=/usr/share/man/man8/orchid.8 orchid.conf=/etc/orchid.conf orchid.service=/lib/systemd/system/orchid.service

.PHONY : all
all : deb rpm

.PHONY: deb
deb: orchid-server_${version}_darwin-amd64.deb

.PHONY: rpm
rpm: orchid-server-${version}-1.x86_64.rpm

orchid-server_${version}_darwin-amd64.deb: orchid-server
    ifeq ($(uname),Linux)
        ${help2man}
        ${fpm_deb}
    else
	${docker} /bin/sh -c "apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends install ruby ruby-dev rubygems build-essential help2man libc++1 && gem install --no-ri --no-rdoc fpm && cd /workdir && ${help2man} && ${fpm_deb}"
    endif

orchid-server-${version}-1.x86_64.rpm: orchid-server
    ifeq ($(uname),Linux)
        ${help2man}
        ${fpm_rpm}
    else
	${docker} /bin/sh -c "apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends install ruby ruby-dev rubygems build-essential rpm help2man libc++1 && gem install --no-ri --no-rdoc fpm && cd /workdir && ${help2man}  && ${fpm_rpm}"
    endif

orchid-server:
	$(MAKE) -C server target=lnx
	cp -a server/out-lnx/x86_64/orchid ./orchid-server

.PHONY: clean
clean:
	rm -f orchid-server *.deb *.rpm orchid.8
