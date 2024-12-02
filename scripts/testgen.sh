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
OUTDIR="testgen"

set -x
mkdir -p ${OUTDIR}

p4testgen \
    --target dpdk \
    --arch psa \
    --max-tests 10 \
    --out-dir ${OUTDIR} \
    --test-backend ptf \
    ${BASE}.p4
