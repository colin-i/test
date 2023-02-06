
#1 year  2 month

y=${1}
m=${2}

mkdir -p ${y}

cp -P date prevdate && \
cd ${y} && \
mkdir ${m} && \
cd ${m} && \
echo $(date -u -d $(if [ "${m}" = "12" ]; then echo -n $((y+1))-1;else echo -n ${y}-$((m+1));fi)-1 +%s)>date
