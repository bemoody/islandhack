prefix = /usr/local
exec_prefix = $(prefix)
bindir = $(exec_prefix)/bin
libdir = $(exec_prefix)/lib
preloaddir = $(libdir)
datarootdir = $(prefix)/share
mandir = $(datarootdir)/man
man1dir = $(mandir)/man1

CC = gcc
CFLAGS = -g -O2 -W -Wall -Wmissing-prototypes
INSTALL = install

distname = islandhack-0.4
distfiles = islandhack islandhack-io.c islandhack.1 README COPYING Makefile

library = libislandhack.so.0

all: $(library)

$(library): islandhack-io.o
	$(CC) $(CFLAGS) $(LDFLAGS) -shared -Wl,-soname,$(library) \
	  -o $(library) islandhack-io.o -ldl

islandhack-io.o: islandhack-io.c
	$(CC) $(CFLAGS) $(CPPFLAGS) -fpic -c islandhack-io.c

clean:
	rm -f *.o *.so $(library)
	rm -f islandhack.tmp

install: islandhack $(library)
	$(INSTALL) -d $(DESTDIR)$(libdir)
	$(INSTALL) -m 644 $(library) $(DESTDIR)$(libdir)
	$(INSTALL) -d $(DESTDIR)$(bindir)
	if [ -n "$(preloaddir)" ]; then \
	  sed 's|my $$PKGLIBDIR = .*;|my $$PKGLIBDIR = q<$(preloaddir)>;|' \
	   < islandhack > islandhack.tmp ; \
	else \
	  sed 's|my $$PKGLIBDIR = .*;|my $$PKGLIBDIR;|' \
	   < islandhack > islandhack.tmp ; \
	fi
	$(INSTALL) -m 755 islandhack.tmp $(DESTDIR)$(bindir)/islandhack
	rm -f islandhack.tmp
	$(INSTALL) -d $(DESTDIR)$(man1dir)
	$(INSTALL) -m 644 islandhack.1 $(DESTDIR)$(man1dir)

uninstall:
	rm -f $(DESTDIR)$(bindir)/islandhack
	rm -f $(DESTDIR)$(libdir)/$(library)
	rm -f $(DESTDIR)$(man1dir)/islandhack.1

dist:
	rm -rf $(distname)
	mkdir $(distname)
	cp -p $(distfiles) $(distname)
	tar cv $(distname) | gzip -9 > $(distname).tar.gz

.PHONY: all clean install uninstall dist
