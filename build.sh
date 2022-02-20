ec(){
	e=$($@)
	unset e
	echo $@
	if [ "$?" != "0" ] ; then
		echo Compilation failed
		exit 1
	fi
}

ASM=${ASM:=as}
LD=${LD:=ld}
SOURCES=${SOURCES:="main"}
SOURCES=(${SOURCES[*]})

objs=""

for i in ${SOURCES[*]} ; do
	ec $ASM -o src/$i.o src/$i.s
	objs+="src/$i.o"
done

ec $LD -o ${SOURCES[0]} ${objs[@]}
