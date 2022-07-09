AS=as
AR=ar
LD=ld

server: server.a
	$(LD) -s -o $@ $<

server.a: src/server.o
	$(AR) scr $@ $^

src/server.o: src/server.s
	$(AS) -o $@ $<
