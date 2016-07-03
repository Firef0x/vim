# vim: set ft=make :
# Makefile for VIM on the Amiga, using SAS/Lattice C 6.0 to 6.58
#
# Do NOT use the peephole optimizer with a version before 6.56!
# It messes up all kinds of things:
# For 6.0 and 6.1, expand_env() will not work correctly.
# For 6.2 and 6.3 the call to free_line in u_freeentry is wrong.
# The "read.me" file for version 6.56 includes a remark about a fix for the
# peephole optimizer.  Everything before 6.56 will probably fail.
#
# You should use Manx Aztec C whenever possible, because it has been tested.
#
# The prototypes from Manx and SAS are incompatible. If the prototypes
# were generated by Manx, first do "touch *.c; make proto" before "make".
# The prototypes generated on Unix work for both.
#
# Note: Not all dependencies are included. This was done to avoid having
#       to compile everything when a global variable or function is added.

#>>>>> choose options:

### See feature.h for a list of optionals.
### Any other defines can be included here.

# NO_ARP	Don't include ARP functions
# SASC=658	Sas/C version number
# NEWSASC	fixes a bug in the syntax highlighting?
DEFINES = DEF=NO_ARP DEF=NEWSASC DEF="SASC=658"

#>>>>> if HAVE_TGETENT is defined termlib.o has to be used
#TERMLIB = termlib.o
TERMLIB =

#>>>>> choose NODEBUG for normal compiling, the other for debugging and
# profiling
# don't switch on debugging when generating proto files, it crashes the
# compiler.
DBG = NODEBUG
#DBG = DBG=SF

#>>>>> choose NOOPTPEEP for 6.0 to 6.3, NOOPT for debugging
# with version 6.56 and later you can probably use OPT
OPTIMIZE  = OPT
#OPTIMIZE = NOOPTPEEP
#OPTIMIZE = NOOPT

# for 6.58 you can use the line below, but be warned it takes a loooonnnggg time
#OPTIMIZE=OPT  OPTIMIZERSCHEDULER OPTIMIZERTIME NoOPTIMIZERALIAS \
	OptimizerComplexity=10 OptimizerDepth=10 OptimizerRecurDepth=10 \
	OptimizerInLocal OPTPEEP

#generate code for your processor - 68060 will work for 040's as well.
CPU=68000
#CPU=68020
#CPU=68030
#CPU=68040
#CPU=68060

#Error reporting - rexx or console
ERROR = ERRORCONSOLE ERRORSOURCE ERRORHIGHLIGHT
#ERROR = ERRORREXX ERRORCONSOLE ERRORSOURCE ERRORHIGHLIGHT

#memory types, if you have fast use it :->,
#	ANY = will work on all machines
#	FAST = this is the best option, for speed
#MEMORYTYPE=FAST
MEMORYTYPE=ANY

#MEMSIZE - this is for compile time only for speed of compilation
#MEMSIZE=HUGE
MEMSIZE=LARGE
#MEMSIZE=SMALL

#>>>>> end of choices
###########################################################################

CC	= sc
GST	= vim.gst
COPTS	= SINT SCODE SDATA
SHELL	= csh
DEL	= $(SHELL) -c rm -f

# ignore error messages for uninitialized variables, they are mostly not correct
CFLAGS  = NOLINK $(DBG) CPU=$(CPU) NOSTACKCHECK DEF=AMIGA CODE=FAR idir=proto ignore=317
CFLAGS2 = $(OPTIMIZE) $(ERROR) GSTIMMEDIATE GST=$(GST)
CFLAGS3 = $(COPTS) STRINGMERGE MEMSIZE=$(MEMSIZE)
CFLAGS4 = $(DEFINES) DATAMEMORY=$(MEMORYTYPE)

PROPT = DEF=PROTO GPROTO GPPARM MAXIMUMERRORS=999 GENPROTOSTATICS GENPROTOPARAMETERS

SRC = \
	arabic.c \
	blowfish.c \
	buffer.c \
	charset.c \
	crypt.c \
	crypt_zip.c \
	diff.c \
	digraph.c \
	edit.c \
	eval.c \
	ex_cmds.c \
	ex_cmds2.c \
	ex_docmd.c \
	ex_eval.c \
	ex_getln.c \
	farsi.c \
	fileio.c \
	fold.c \
	getchar.c \
	hardcopy.c \
	hashtab.c \
	json.c \
	main.c \
	mark.c \
	memfile.c \
	memline.c \
	menu.c \
	message.c \
	misc1.c \
	misc2.c \
	move.c \
	mbyte.c \
	normal.c \
	ops.c \
	option.c \
	os_amiga.c \
	popupmnu.c \
	quickfix.c \
	regexp.c \
	screen.c \
	search.c \
	sha256.c \
	spell.c \
	syntax.c \
	tag.c \
	term.c \
	ui.c \
	undo.c \
	window.c \
	version.c

OBJ = \
	arabic.o \
	blowfish.o \
	buffer.o \
	charset.o \
	crypt.o \
	crypt_zip.o \
	diff.o \
	digraph.o \
	edit.o \
	eval.o \
	ex_cmds.o \
	ex_cmds2.o \
	ex_docmd.o \
	ex_eval.o \
	ex_getln.o \
	farsi.o \
	fileio.o \
	fold.o \
	getchar.o \
	hardcopy.o \
	hashtab.o \
	json.o \
	main.o \
	mark.o \
	memfile.o \
	memline.o \
	menu.o \
	message.o \
	misc1.o \
	misc2.o \
	move.o \
	mbyte.o \
	normal.o \
	ops.o \
	option.o \
	os_amiga.o \
	popupmnu.o \
	quickfix.o \
	regexp.o \
	screen.o \
	search.o \
	sha256.o \
	spell.o \
	syntax.o \
	tag.o \
	term.o \
	ui.o \
	undo.o \
	window.o \
	$(TERMLIB)

PRO = \
	proto/arabic.pro \
	proto/blowfish.pro \
	proto/buffer.pro \
	proto/charset.pro \
	proto/crypt.pro \
	proto/crypt_zip.pro \
	proto/diff.pro \
	proto/digraph.pro \
	proto/edit.pro \
	proto/eval.pro \
	proto/ex_cmds.pro \
	proto/ex_cmds2.pro \
	proto/ex_docmd.pro \
	proto/ex_eval.pro \
	proto/ex_getln.pro \
	proto/farsi.pro \
	proto/fileio.pro \
	proto/fold.pro \
	proto/getchar.pro \
	proto/hardcopy.pro \
	proto/hashtab.pro \
	proto/json.pro \
	proto/main.pro \
	proto/mark.pro \
	proto/memfile.pro \
	proto/memline.pro \
	proto/menu.pro \
	proto/message.pro \
	proto/misc1.pro \
	proto/misc2.pro \
	proto/move.pro \
	proto/mbyte.pro \
	proto/normal.pro \
	proto/ops.pro \
	proto/option.pro \
	proto/os_amiga.pro \
	proto/popupmnu.pro \
	proto/quickfix.pro \
	proto/regexp.pro \
	proto/screen.pro \
	proto/search.pro \
	proto/sha256.pro \
	proto/spell.pro \
	proto/syntax.pro \
	proto/tag.pro \
	proto/term.pro \
	proto/termlib.pro \
	proto/ui.pro \
	proto/undo.pro \
	proto/window.pro

all: proto Vim

Vim: scoptions $(OBJ) version.c version.h
	$(CC) $(CFLAGS) version.c
	$(CC) LINK $(COPTS) $(OBJ) version.o $(DBG) PNAME=Vim

debug: scoptions $(OBJ) version.c version.h
	$(CC) $(CFLAGS) version.c
	$(CC) LINK $(COPTS) $(OBJ) version.o $(DBG) PNAME=Vim

proto: $(GST) $(PRO)

tags:
	spat ctags $(SRC) *.h
#	csh -c ctags $(SRC) *.h

# can't use delete here, too many file names
clean:
	$(DEL) *.o Vim $(GST)

# generate GlobalSymbolTable, which speeds up the compile time.
#
# A preprocessing stage is used to work around a bug in the GST generator, in
# that it does not handle nested makefiles properly in this stage.
# Ignore error message for not producing any code (105).
$(GST): scoptions vim.h keymap.h macros.h ascii.h term.h structs.h
	$(CC) $(CFLAGS) PREPROCESSORONLY vim.h objectname pre.h
	$(CC) MGST=$(GST) pre.h ignore=105
	$(DEL) pre.h

# generate an options file, because SAS/C smake can't handle the amiga command
# line can handle the lengths that this makefile will impose on the shell.
# (Manx's make can do this).
scoptions: Make_sas.mak
	@echo "Generating - $@ ..."
	@echo $(CFLAGS) > scoptions
	@echo $(CFLAGS1) >> scoptions
	@echo $(CFLAGS2) >> scoptions
	@echo $(CFLAGS3) >> scoptions
	@echo $(CFLAGS4) >> scoptions
	@echo $(COPTS) >>scoptions
	@echo done

###########################################################################

$(OBJ): $(GST) vim.h
$(PRO): $(GST) vim.h

.c.o:
	$(CC) $(CFLAGS) $*.c

.c.pro:
	$(CC) $(CFLAGS) GPFILE=proto/$*.pro $(PROPT) $*.c

# dependencies
arabic.o:		arabic.c
proto/arabic.pro:	arabic.c
blowfish.o:		blowfish.c
proto/blowfish.pro:	blowfish.c
buffer.o:		buffer.c
proto/buffer.pro:	buffer.c
charset.o:		charset.c
proto/charset.pro:	charset.c
crypt.o:		crypt.c
proto/crypt.pro:	crypt.c
crypt_zip.o:		crypt_zip.c
proto/crypt_zip.pro:	crypt_zip.c
diff.o:			diff.c
proto/diff.pro:		diff.c
digraph.o:		digraph.c
proto/digraph.pro:	digraph.c
edit.o:			edit.c
proto/edit.pro:		edit.c
eval.o:			eval.c
proto/eval.pro:		eval.c
ex_cmds.o:		ex_cmds.c
proto/ex_cmds.pro:	ex_cmds.c
ex_cmds2.o:		ex_cmds2.c
proto/ex_cmds2.pro:	ex_cmds2.c
ex_docmd.o:		ex_docmd.c ex_cmds.h
proto/ex_docmd.pro:	ex_docmd.c ex_cmds.h
ex_eval.o:		ex_eval.c ex_cmds.h
proto/ex_eval.pro:	ex_eval.c ex_cmds.h
ex_getln.o:		ex_getln.c
proto/ex_getln.pro:	ex_getln.c
farsi.o:		farsi.c
proto/farsi.pro:	farsi.c
fileio.o:		fileio.c
proto/fileio.pro:	fileio.c
fold.o:			fold.c
proto/fold.pro:		fold.c
getchar.o:		getchar.c
proto/getchar.pro:	getchar.c
hardcopy.o:		hardcopy.c
proto/hardcopy.pro:	hardcopy.c
hashtab.o:		hashtab.c
proto/hashtab.pro:	hashtab.c
json.o:			json.c
proto/json.pro:		json.c
main.o:			main.c
proto/main.pro:		main.c
mark.o:			mark.c
proto/mark.pro:		mark.c
memfile.o:		memfile.c
proto/memfile.pro:	memfile.c
memline.o:		memline.c
proto/memline.pro:	memline.c
menu.o:			menu.c
proto/menu.pro:		menu.c
message.o:		message.c
proto/message.pro:	message.c
misc1.o:		misc1.c
proto/misc1.pro:	misc1.c
misc2.o:		misc2.c
proto/misc2.pro:	misc2.c
move.o:			move.c
proto/move.pro:		move.c
mbyte.o:		mbyte.c
proto/mbyte.pro:	mbyte.c
normal.o:		normal.c
proto/normal.pro:	normal.c
ops.o:			ops.c
proto/ops.pro:		ops.c
option.o:		option.c
proto/option.pro:	option.c
os_amiga.o:		os_amiga.c
proto/os_amiga.pro:	os_amiga.c
popupmnu.o:		popupmnu.c
proto/popupmnu.pro:	popupmnu.c
quickfix.o:		quickfix.c
proto/quickfix.pro:	quickfix.c
regexp.o:		regexp.c
proto/regexp.pro:	regexp.c
screen.o:		screen.c
proto/screen.pro:	screen.c
search.o:		search.c
proto/search.pro:	search.c
sha256.o:		sha256.c
proto/sha256.pro:	sha256.c
spell.o:		spell.c
proto/spell.pro:	spell.c
syntax.o:		syntax.c
proto/syntax.pro:	syntax.c
tag.o:			tag.c
proto/tag.pro:		tag.c
term.o:			term.c
proto/term.pro:		term.c
termlib.o:		termlib.c
proto/termlib.pro:	termlib.c
ui.o:			ui.c
proto/ui.pro:		ui.c
undo.o:			undo.c
proto/undo.pro:		undo.c
window.o:		window.c
