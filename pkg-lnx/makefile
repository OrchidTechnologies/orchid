version := $(shell ../env/version.sh)
version := $(word 3,${version})

help2man := help2man --no-info --section 8 --output orchidd.8 --name 'Run an Orchid Server' --version-string 'orchidd ${version}' ./man_wrapper.sh

docker := docker run -i --rm --name "orchidd" -v "${PWD}:/workdir" ubuntu:bionic

fpm_deb := fpm -s dir -t deb -n 'orchidd' -v ${version} -a all --url 'https://www.orchid.com/' --description 'Orchid Server Binary' --deb-no-default-config-files --deb-systemd orchidd.service -d libc++1 orchidd=/usr/bin/orchidd orchidd.8=/usr/share/man/man8/orchidd.8 orchidd.conf=/etc/orchidd.conf

fpm_rpm := fpm -s dir -t rpm -n 'orchidd' -v $(subst +,.,${version}) --url 'https://www.orchid.com/' --description 'Orchid Server Binary' -d libcxx orchidd=/usr/bin/ orchidd.8=/usr/share/man/man8/orchidd.8 orchidd.conf=/etc/orchidd.conf orchidd.service=/lib/systemd/system/orchidd.service

.PHONY : all
all : deb rpm

.PHONY: deb
deb: orchidd_${version}_darwin-amd64.deb

.PHONY: rpm
rpm: orchidd-${version}-1.x86_64.rpm

orchidd_${version}_darwin-amd64.deb: orchidd
    ifeq ($(uname-s),Linux)
        ${help2man}
        ${fpm_deb}
    else
	${docker} /bin/sh -c "apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends install ruby ruby-dev rubygems build-essential help2man libc++1 && gem install --no-ri --no-rdoc fpm && cd /workdir && ${help2man} && ${fpm_deb}"
    endif

orchidd-${version}-1.x86_64.rpm: orchidd
    ifeq ($(uname-s),Linux)
        ${help2man}
        ${fpm_rpm}
    else
	${docker} /bin/sh -c "apt-get update && DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends install ruby ruby-dev rubygems build-essential rpm help2man libc++1 && gem install --no-ri --no-rdoc fpm && cd /workdir && ${help2man}  && ${fpm_rpm}"
    endif

orchidd:
	$(MAKE) -C server target=lnx
	cp -a server/out-lnx/x86_64/orchidd ./orchidd
	chmod 0755 ./orchidd

.PHONY: clean
clean:
	rm -f orchidd *.deb *.rpm orchidd.8
