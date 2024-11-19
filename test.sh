export TARGET=$1

# if there's a second argument, use it as the compiler path
if [ -n "$2" ]; then
    COMPILER_PATH=$2
else
    COMPILER_PATH=$COMPILER_PATH
fi

lscpu

$COMPILER_PATH --version

$COMPILER_PATH ${TARGET}.c -o ${TARGET}.bin
$COMPILER_PATH -O0 ${TARGET}.c -o ${TARGET}_0.bin -g
$COMPILER_PATH -O1 ${TARGET}.c -o ${TARGET}_1.bin -g
$COMPILER_PATH -O2 ${TARGET}.c -o ${TARGET}_2.bin -g
$COMPILER_PATH -O3 ${TARGET}.c -o ${TARGET}_3.bin -g 
$COMPILER_PATH -O3 ${TARGET}.c -o ${TARGET}_3_no_vectorize.bin -g -fno-tree-vectorize

echo "---running original---"
./${TARGET}.bin
echo ""
echo "---running O0---"
./${TARGET}_0.bin
echo ""
echo "---running O1---"
./${TARGET}_1.bin
echo ""
echo "---running O2---"
./${TARGET}_2.bin
echo ""
echo "---running O3---"
./${TARGET}_3.bin
echo ""
echo "---running O3 no vectorize---"
./${TARGET}_3_no_vectorize.bin
echo ""
$COMPILER_PATH -Os ${TARGET}.c -o ${TARGET}_os.bin -g
echo "---running size optimized---"
./${TARGET}_os.bin
echo ""
$COMPILER_PATH -O2 ${TARGET}.c -o ${TARGET}_instrumented.bin -fprofile-generate -g
echo "---running instrumented---"
./${TARGET}_instrumented.bin
echo ""
$COMPILER_PATH -O2 ${TARGET}.c -o ${TARGET}_fdo.bin -fprofile-use=${TARGET}_instrumented-$TARGET.gcda -g -fno-tree-vectorize
echo "---running fdo---"
./${TARGET}_fdo.bin
echo ""
echo "---running autofdo with pmu sampling---"
python3 /scratch/iansseijelly/pmu-tools/ocperf.py record -b -e br_inst_retired.near_taken:pp -- ./${TARGET}_2.bin
echo ""
/scratch/iansseijelly/autofdo/build/create_gcov --binary=./${TARGET}_2.bin --profile=perf.data --gcov=${TARGET}.gcov -gcov_version=1
$COMPILER_PATH -O2 -fauto-profile=${TARGET}.gcov ${TARGET}.c -o ${TARGET}_autofdo.bin -g -fno-tree-vectorize
echo "---running autofdo---"
./${TARGET}_autofdo.bin
