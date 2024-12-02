#!/bin/bash

print_usage() {
    1>&2 echo "usage: $0 <progname.p4>"
}

if [ $# -ne 1 ]
then
    print_usage
    exit 1
fi

PROG="$1"
BASE=`basename ${PROG} .p4`
OUTDIR="output"

set -x
mkdir -p ${OUTDIR}
p4c-dpdk \
    --arch psa \
    -o ${OUTDIR}/${BASE}.spec \
    --bf-rt-schema ${OUTDIR}/${BASE}.bfrt.json \
    --context ${OUTDIR}/${BASE}.context.json \
    --p4runtime-files ${OUTDIR}/${BASE}.txtpb \
    --p4runtime-format text \
    ${BASE}.p4
