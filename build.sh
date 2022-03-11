idx=0
CNT=0
ec(){
	idx=$(($idx+1))
	printf "  [%*d/$CNT] $*\n" ${#CNT} $idx
	sh -c "$*"
	exitcode=$?
	if [ "$exitcode" != "0" ] ; then
		echo Compilation failed
		ec rm -rfv objs/
		exit 1
	fi
	unset exitcode
}

ASM=${ASM:=as}
LD=${LD:=ld}
SOURCES=(`ls src/*.s | sed 's/.s//; s/src\///'`)
#SOURCES=${SOURCES:="main"}
#SOURCES=(${SOURCES[*]})
CNT=${#SOURCES[*]}
CNT=$(($CNT+4))

objs=""
ec mkdir objs

for i in ${SOURCES[*]} ; do
	ec $ASM -o objs/$i.o src/$i.s
	objs+="objs/$i.o "
done

ec ar svcr server.a ${objs[@]}

ec $LD -o server server.a -O1
ec rm -vrf objs/ server.a
