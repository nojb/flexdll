#!/bin/bash

function run {
    NAME=$1
    shift
    echo "-=-=- $NAME -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
    "$@"
    CODE=$?
    if [ $CODE -ne 0 ]; then
        echo "-=-=- $NAME failed! -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
        exit $CODE
    else
        echo "-=-=- End of $NAME -=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
    fi
}

echo ** OCAMLROOT=$OCAMLROOT

mkdir -p $OCAMLROOT/bin/flexdll

curl -O http://alain.frisch.fr/flexdll/flexdll-bin-0.34.zip
unzip -u flexdll-bin-0.34.zip -d $OCAMLROOT/bin/flexdll

cd $APPVEYOR_BUILD_FOLDER

# Do not perform end-of-line conversion
git config --global core.autocrlf false
git clone https://github.com/ocaml/ocaml.git --branch $OCAMLBRANCH --depth 1 ocaml

cd ocaml

if [ ! -f $OCAMLROOT/STAMP ] || [ "$(git rev-parse HEAD)" != "$(cat $OCAMLROOT/STAMP)" ]; then
    cp config/m-nt.h config/m.h
    cp config/s-nt.h config/s.h
    #cp config/Makefile.msvc config/Makefile
    cp config/Makefile.msvc64 config/Makefile

    #PREFIX=$(echo "$OCAMLROOT" | sed -e "s|\\\\|/|g")
    PREFIX=$(cygpath -m -s "$OCAMLROOT")
    echo "Edit config/Makefile so set PREFIX=$PREFIX"
    cp config/Makefile config/Makefile.bak
    sed -e "s|PREFIX=.*|PREFIX=$PREFIX|" config/Makefile.bak > config/Makefile
    run "Content of config/Makefile" cat config/Makefile

    run "make world.opt" make -f Makefile.nt world.opt
    run "make install" make -f Makefile.nt install

    git rev-parse HEAD > $OCAMLROOT/STAMP
fi

#run "env" env
set Path=%OCAMLROOT%\bin;%OCAMLROOT%\bin\flexdll;%Path%
export CAML_LD_LIBRARY_PATH=$PREFIX/lib/stublibs

cd $APPVEYOR_BUILD_FOLDER

make

CHAINS="mingw mingw64 cygwin cygwin64 msvc msvc64"

for CHAIN in $CHAINS; do
    run "make build_$CHAIN" make build_$CHAIN
done

for CHAIN in $CHAINS; do
    run "make demo_$CHAIN" make demo_$CHAIN
done
