#!/bin/bash

print_usage() {
    1>&2 echo "usage: $0 <progname.p4>"
    1>&2 echo "usage: $0 <progname.p4> [ extra p4testgen options ]"
    1>&2 echo ""
    1>&2 echo "Example:"
    1>&2 echo "    build.sh main.p4 --arch pna"
}

if [ $# -lt 1 ]
then
    print_usage
    exit 1
fi

PROG="$1"
shift
BASE=`basename ${PROG} .p4`
OUTDIR="testgen"

set -x
mkdir -p ${OUTDIR}

p4testgen \
    --target dpdk \
    $* \
    --port-ranges 0:7 \
    --max-tests 10 \
    --out-dir ${OUTDIR} \
    --test-backend ptf \
    ${BASE}.p4
