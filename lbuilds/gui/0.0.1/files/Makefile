SRC = $(wildcard *.c)
OBJ = $(SRC:.c=.o)
DEP = $(addprefix .,$(SRC:.c=.o.dep))

LIBS = -lfreetype

run_silent = $(if $(V),$(2),@echo $(1) && $(2))

all: gui

include config.mak
-include $(DEP)

gui: $(OBJ)
	$(call run_silent,"  LINK  $@",$(CC) $(LDFLAGS) -o $@ $^ $(LIBS))

%.o: %.c
	$(call run_silent,"  CC    $@",$(CC) $(CFLAGS) -MMD -MF .$@.dep -c -o $@ $<)

clean:
	@rm -f gui $(OBJ) $(DEP)

.PHONY: clean
