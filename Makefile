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

# Tools used for 'make check'
CURL = curl
WGET = wget
JAVA = java
JAVAC = javac
PYTHON = python3

distname = islandhack-0.5
distfiles = islandhack islandhack-io.c islandhack.1 README COPYING Makefile \
            test-client.sh geturl.java geturl.py example.cache

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
	rm -rf *.class tmpcache*

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

check: check-wget check-curl check-java check-python

check-wget: all
	sh test-client.sh ./islandhack tmpcache-wget "$(WGET) -O -"

check-curl: all
	sh test-client.sh ./islandhack tmpcache-curl "$(CURL) -f"

check-java: all
	$(JAVAC) $(JAVACFLAGS) geturl.java
	sh test-client.sh ./islandhack tmpcache-java "$(JAVA) -cp . geturl"

check-python: all
	sh test-client.sh ./islandhack tmpcache-python "$(PYTHON) ./geturl.py"

dist:
	rm -rf $(distname)
	mkdir $(distname)
	cp -pr $(distfiles) $(distname)
	tar cv $(distname) | gzip -9 > $(distname).tar.gz

.PHONY: all clean install uninstall dist check \
	check-wget check-curl check-java check-python
