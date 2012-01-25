DESTDIR=

.PHONY: default
default: build

.PHONY: build
build:
	echo "java-package currently supports the following binary packages:" > SUPPORTED
	echo >> SUPPORTED
	echo "(This list is automatically generated, do not edit)" >> SUPPORTED
	echo >> SUPPORTED
	grep -h "SUPPORTED$$" $(wildcard lib/*-*.sh) | sed 's/"//g;s/).*//' >> SUPPORTED

.PHONY: clean
clean:
	rm -f SUPPORTED

.PHONY: install
install:
	install -d -m 755 $(DESTDIR)/usr/bin
	install -m 755 make-jpkg.out $(DESTDIR)/usr/bin/make-jpkg
	install -d -m 755 $(DESTDIR)/usr/share/man/man1
	install -m 644 make-jpkg.1 $(DESTDIR)/usr/share/man/man1/
	install -d -m 755 $(DESTDIR)/usr/share/java-package
	for file in lib/*.sh; do \
	    install -m 644 $$file $(DESTDIR)/usr/share/java-package/ ; \
	done
