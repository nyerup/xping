#
# Makefile for xping
#

LIBEVENT=libevent-2.0.18-stable

PREFIX=/usr/local
SBINPATH=$(PREFIX)/bin
MANPATH=$(PREFIX)/man
CFLAGS=-Wall -Werror -I/usr/local/include
LDFLAGS=-L/usr/local/lib
DEPS=check-libevent
OBJS=xping.o termio.o version.o
LIBS=-levent
VERSION="`git describe --tags --always --dirty=+ 2>/dev/null || date +snapshot-%Y%m%dT%H%M%S`"
TIMESTAMP="`date +%Y%m%dT%H%M%S`"

# Static libevent linking
#CFLAGS+=-I./$(LIBEVENT)/include
#DEPS=libevent.a
#OBJS+=libevent.a
#LIBS=-lrt
#LDFLAGS=-L./$(LIBEVENT)/.libs

# Display statistics
#CFLAGS+=-DSTATS

# Dynamic link and use ncurses
#DEPS+=check-curses
#CFLAGS+=-DNCURSES
#LIBS+=-lcurses

.PHONY: version.o

all: xping xping.8.gz

check-libevent:
	@/bin/echo -n 'Checking for libevent... '; \
	 (echo '#include <stdio.h>'; \
	  echo '#include <event2/event.h>'; \
	  echo 'int main()'; \
	  echo '{ printf("%s\\n", event_get_version()); return 0; }' \
	 ) | $(CC) $(CFLAGS) -x c -o /dev/null - -levent >/dev/null 2>/dev/null && echo yes || \
	 (echo no; \
	  echo ""; \
	  echo "libevent not available in usual locations"; \
	  echo ""; false)
	@touch check-libevent

check-curses:
	@/bin/echo -n 'Checking for libcurses... '; \
	 (echo '#include <stdio.h>'; \
	  echo '#include <curses.h>'; \
	  echo 'int main()'; \
	  echo '{ initscr(); return 0; }' \
	 ) | $(CC) $(CFLAGS) -x c -o /dev/null - -lcurses >/dev/null 2>/dev/null && echo yes || \
	 (echo no; \
	  echo ""; \
	  echo "libcurses not available in usual locations"; \
	  echo ""; false)
	@touch check-curses

libevent.a:
	test -f $(LIBEVENT).tar.gz || wget https://github.com/downloads/libevent/libevent/$(LIBEVENT).tar.gz
	test -d $(LIBEVENT) || tar -xzvf $(LIBEVENT).tar.gz
	cd $(LIBEVENT) && ./configure && make
	cp ./$(LIBEVENT)/.libs/libevent.a .
	size libevent.a

version.o:
	(printf "const char version[] = \"%s\";\n" $(VERSION); \
	 printf "const char built[] = \"%s\";\n" $(TIMESTAMP)) | \
	 $(CC) -x c -c -o version.o -

xping: $(DEPS) $(OBJS)
	$(CC) $(LDFLAGS) -g -o xping $(OBJS) $(LIBS)

xping.8.gz: xping.8
	gzip -c xping.8 > xping.8.gz

install:
	mkdir -p $(SBINPATH)
	mkdir -p $(MANPATH)/man8
	install -m 4555 xping $(SBINPATH)/
	install -m 444 xping.8.gz $(MANPATH)/man8/

clean:
	rm -f check-libevent check-curses xping xping.8.gz $(OBJS)

# Object dependencies
termio.o: termio.c xping.h uthash.h utlist.h
xping.o: xping.c xping.h uthash.h utlist.h
