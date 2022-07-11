AS=as
AR=ar
LD=ld

INTERPRETER=/system/bin/linker64
LIBS=
DEBUG=0
ifeq ($(DEBUG), 0)
LD_FLAGS+=-s
else
LD_FLAGS+=
endif

ifneq "$(LIBS)" ""
LD_FLAGS+=-I$(INTERPRETER) $(LIBS)
endif

server: server.a
	 $(LD) $(LD_FLAGS) -o $@ $<

server.a: src/server.o
	$(AR) scr $@ $^

src/server.o: src/server.s
	$(AS) -o $@ $<
