#!/usr/bin/bash
idx=0
CNT=0
ec(){
	idx=$(($idx+1))
	sh -c "$*"
	exitcode=$?
	printf "  [%*d/$CNT] $*\n" ${#CNT} $idx
	if [ "$exitcode" != "0" ] && [ "$exitcode" != "" ]; then
		if [ "$1" == "mkdir" ]; then
			echo Mkdir failed to create directory, ignored
			return
		fi
		echo Compilation failed at \`$*\'
		exit 1
	fi
	unset exitcode
}

UNDEBUG_FL=-s
UNCLEAN_FL=n

for arg in $@; do
	if [ "$arg" == "--debug" ]; then
		UNDEBUG_FL=""
		DEBUG_FL="--defsym DBG=1"
	elif [ "$arg" == "--noclean" ]; then
		UNCLEAN_FL=y
	fi
done

ASM=${ASM:=as}
LD=${LD:=ld}
SOURCES=(`cd src/; ls *.s | sed 's/\.s//'`)
#SOURCES=${SOURCES:="main"}
#SOURCES=(${SOURCES[*]})
CNT=${#SOURCES[*]}
CNT=$(($CNT+3+$(if [ $UNCLEAN_FL == n ]; then echo 1; else echo 0; fi)))

objs=""
ec mkdir objs

for i in ${SOURCES[*]} ; do
	ec $ASM $DEBUG_FL -O2 -o objs/$i.o src/$i.s
	objs+="objs/$i.o "
done

ec ar scr server.a ${objs[@]}

ec $LD -O1 $UNDEBUG_FL -o server server.a
if [ $UNCLEAN_FL == n ]; then
	ec rm -rf objs/ server.a
fi
