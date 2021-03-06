NAME=gitql
VERSION=1.3.0
ITERATION=1.lru
PREFIX=/usr/local
LICENSE=MIT
VENDOR="Claudson Oliveira"
MAINTAINER="Ryan Parman"
DESCRIPTION="GitQL is a Git query language."
URL=https://github.com/cloudson/gitql
ACTUALOS=$(shell osqueryi "select * from os_version;" --json | jq -r ".[].name")
EL=$(shell if [[ "$(ACTUALOS)" == "Amazon Linux AMI" ]]; then echo alami; else echo el; fi)
RHEL=$(shell [[ -f /etc/centos-release ]] && rpm -q --queryformat '%{VERSION}' centos-release)

#-------------------------------------------------------------------------------

all: info clean install-deps compile install-tmp package move

#-------------------------------------------------------------------------------

.PHONY: info
info:
	@ echo "NAME:        $(NAME)"
	@ echo "VERSION:     $(VERSION)"
	@ echo "ITERATION:   $(ITERATION)"
	@ echo "PREFIX:      $(PREFIX)"
	@ echo "LICENSE:     $(LICENSE)"
	@ echo "VENDOR:      $(VENDOR)"
	@ echo "MAINTAINER:  $(MAINTAINER)"
	@ echo "DESCRIPTION: $(DESCRIPTION)"
	@ echo "URL:         $(URL)"
	@ echo "OS:          $(ACTUALOS)"
	@ echo "EL:          $(EL)"
	@ echo "RHEL:        $(RHEL)"
	@ echo " "

#-------------------------------------------------------------------------------

.PHONY: clean
clean:
	rm -Rf /tmp/installdir* gitql* /tmp/gocode*

#-------------------------------------------------------------------------------

.PHONY: install-deps
install-deps:
	yum install -y \
		cmake \
		golang \
	;

#-------------------------------------------------------------------------------

.PHONY: compile
compile:
	export GOPATH=/tmp/gocode && mkdir -p $$GOPATH;
	go get -u -d github.com/cloudson/gitql;
	cd $$GOPATH/src/github.com/cloudson/gitql && \
		git checkout $(VERSION) && \
		make \
	;

#-------------------------------------------------------------------------------

.PHONY: install-tmp
install-tmp:
	mkdir -p /tmp/installdir-$(NAME)-$(VERSION);
	cd $$GOPATH/src/github.com/cloudson/gitql && \
		mkdir -p /tmp/installdir-$(NAME)-$(VERSION)/usr/local/bin/ && \
		mkdir -p /tmp/installdir-$(NAME)-$(VERSION)/usr/local/lib/ && \
		cp ./libgit2/install/lib/lib*  /tmp/installdir-$(NAME)-$(VERSION)/usr/local/lib/ && \
		cp ./gitql /tmp/installdir-$(NAME)-$(VERSION)/usr/local/bin/git-ql;

#-------------------------------------------------------------------------------

.PHONY: package
package:

	# Main package
	fpm \
		-f \
		-d libtool \
		-s dir \
		-t rpm \
		-n $(NAME) \
		-v $(VERSION) \
		-C /tmp/installdir-$(NAME)-$(VERSION) \
		-m $(MAINTAINER) \
		--iteration $(ITERATION) \
		--license $(LICENSE) \
		--vendor $(VENDOR) \
		--prefix / \
		--url $(URL) \
		--description $(DESCRIPTION) \
		--rpm-defattrdir 0755 \
		--rpm-digest md5 \
		--rpm-compression gzip \
		--rpm-os linux \
		--rpm-changelog CHANGELOG.txt \
		--rpm-dist $(EL)$(RHEL) \
		--rpm-auto-add-directories \
		--after-install after-install-libs.sh \
		usr/local/bin \
		usr/local/lib \
	;

#-------------------------------------------------------------------------------

.PHONY: move
move:
	[[ -d /vagrant/repo ]] && mv *.rpm /vagrant/repo/
