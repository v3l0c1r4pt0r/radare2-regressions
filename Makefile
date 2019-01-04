VERSION=2.5.0
DESTDIR?=/
PREFIX?=/usr/local
BINDIR=$(DESTDIR)/$(PREFIX)/bin
PWD=$(shell pwd)
PKG=radare2-regressions
TAR=tar -cvf
TAREXT=tar.xz
CZ=xz -f

TDIRS=$(shell ls -d t*| grep -v tmp) bins
LIBDIR=$(DESTDIR)/$(PREFIX)/lib

-include config.mk


PULLADDR=https://github.com/radare/radare2-regressions.git

do:
	-git pull ${PULLADDR}
	-$(MAKE) overlay-apply
	$(SHELL) run_tests.sh

overlay:
	if [ -f ../old/t/overlay ]; then \
		$(SHELL) overlay.sh create ; \
	fi

apply-overlay overlay-apply:
	$(SHELL) overlay.sh apply

all:
	-$(MAKE) overlay-apply
	$(MAKE) alltargets

alltargets: js-tests commands io archos unit_tests

archos:
	@$(MAKE) -C old/t.archos
dbg.linux:
	$(SHELL) run_tests.sh old/t.archos/Linux

commands:
	$(SHELL) run_tests.sh old/t

io:
	$(SHELL) run_tests.sh old/t.io

keystone:
	cd new && npm install
	cd new && node bin/r2r.js db/extras/asm/x86.ks_

swf:
	cd new && npm install
	cd new && node bin/r2r.js db/extras/asm/swf

m68k-extras:
	cd new && npm install
	cd new && node bin/r2r.js db/extras/asm/m68k

mc6809:
	cd new && npm install
	cd new && node bin/r2r.js db/extras/asm/x86.udis

udis86:
	cd new && npm install
	cd new && node bin/r2r.js db/extras/asm/mc6809

olly-extras:
	cd new && npm install
	cd new && node bin/r2r.js db/extras/asm/x86.olly

dwarf:
	cd new && npm install
	cd new && node bin/r2r.js db/extras/asm/dwarf
broken:
	grep BROKEN=1 t -r -l

clean:
	rm -rf tmp

symstall:
	mkdir -p $(BINDIR)
	chmod +x r2-v r2r
	ln -fs $(PWD)/r2-v $(BINDIR)/r2-v
	ln -fs $(PWD)/r2r $(BINDIR)/r2r

#sed -e 's,@R2RDIR@,$(PWD),g' < $(PWD)/r2-v > $(BINDIR)/r2-v
#sed -e 's,@R2RDIR@,$(PWD),g' < $(PWD)/r2r > $(BINDIR)/r2r
install:
	mkdir -p $(BINDIR)
	sed -e 's,@R2RDIR@,$(LIBDIR)/radare2-regressions,g' < $(PWD)/r2-v > $(BINDIR)/r2-v
	sed -e 's,@R2RDIR@,$(LIBDIR)/radare2-regressions,g' < $(PWD)/r2r > $(BINDIR)/r2r
	chmod +x $(BINDIR)/r2-v
	chmod +x $(BINDIR)/r2r
	mkdir -p $(LIBDIR)/radare2-regressions
	cp -rf $(TDIRS) $(LIBDIR)/radare2-regressions
	cp -rf *.sh $(LIBDIR)/radare2-regressions

uninstall:
	rm -f $(BINDIR)/r2r
	rm -f $(BINDIR)/r2-v
	rm -rf $(LIBDIR)/radare2-regressions

unit_tests:
	@make -C ./unit all
	@./run_unit.sh

tested:
	@grep -re FILE= t*  | cut -d : -f 2- | sed -e 's/^.*bins\///g' |sort -u | grep -v FILE

untested:
	@${MAKE} -s tested > .a
	@${MAKE} -s allbins > .b
	@diff -ru .a .b | grep ^+ | grep -v +++ | cut -c 2-
	@rm -f .a .b

js-tests:
	cd new && npm install
	cd new && node bin/r2r.js

allbins:
	find bins -type f

dist:
	git clone . $(PKG)-$(VERSION)
	rm -rf $(PKG)-$(VERSION)/.git
	$(TAR) "$(PKG)-${VERSION}.tar" "$(PKG)-$(VERSION)"
	${CZ} "$(PKG)-${VERSION}.tar"

.PHONY: all clean allbins dist
