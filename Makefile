CFLAGS_FILE?=.cflags
COMPILE_TEST_FILE?=.test.c
PREFIX?=/usr/local

## Option for static binary with /opt/zig/zig (not working yet)
#ZIG = /opt/zig/zig
#ifneq ("$(wildcard $(ZIG))", "")
#  CC = $(ZIG) cc -target x86_64-linux-musl
#endif

all: vpa zig

vpa: $(CFLAGS_FILE) Makefile src/vpn.c src/charm.c src/os.c include/charm.h include/vpn.h include/os.h
	$(CC) $$(cat "$(CFLAGS_FILE)") $(OPTFLAGS) -Iinclude -o $@ src/vpn.c src/charm.c src/os.c
	strip $@

zig:
	zig build -Drelease -Dtarget=x86-linux-musl
	upx --lzma --best zig-out/bin/vpa

install: vpa
	install -d $(PREFIX)/bin
	install -m 0755 vpa $(PREFIX)/bin

uninstall:
	rm -f $(PREFIX)/bin/vpa

clean:
	rm -f vpa *~ $(CFLAGS_FILE) $(COMPILE_TEST_FILE)

$(CFLAGS_FILE):
	@CFLAGS="$(CFLAGS)"
	@if [ -z "$$CFLAGS" ]; then \
		if [ ! -r "$(CFLAGS_FILE)" ]; then \
			echo "int main(void) { return 0; }" > "$(COMPILE_TEST_FILE)"; \
			for flag in -march=native -mtune=native -Ofast; do \
				$(CC) $${CFLAGS} $${flag} "$(COMPILE_TEST_FILE)" >/dev/null 2>&1 && CFLAGS="$$CFLAGS $$flag"; \
			done; \
			rm -f a.out; \
			CFLAGS="$${CFLAGS} -Wall -W -Wshadow -Wmissing-prototypes"; \
		fi; \
	fi; \
	echo "$$CFLAGS" > "$(CFLAGS_FILE)"
