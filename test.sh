export TARGET=$1

gcc --version

gcc $TARGET.c -o ${TARGET}
gcc -O0 $TARGET.c -o ${TARGET}_0 -g
gcc -O1 $TARGET.c -o ${TARGET}_1 -g
gcc -O2 $TARGET.c -o ${TARGET}_2 -g
gcc -O3 $TARGET.c -o ${TARGET}_3 -g 
gcc -O3 $TARGET.c -o ${TARGET}_3_no_vectorize -g -fno-tree-vectorize

echo "---running original---"
./${TARGET}
echo ""
echo "---running O0---"
./${TARGET}_0
echo ""
echo "---running O1---"
./${TARGET}_1
echo ""
echo "---running O2---"
./${TARGET}_2
echo ""
echo "---running O3---"
./${TARGET}_3
echo ""
echo "---running O3 no vectorize---"
./${TARGET}_3_no_vectorize
echo ""
gcc -Os $TARGET.c -o ${TARGET}_os -g
echo "---running size optimized---"
./${TARGET}_os
echo ""
gcc -O2 $TARGET.c -o ${TARGET}_instrumented -fprofile-generate -g
echo "---running instrumented---"
./${TARGET}_instrumented
echo ""
gcc -O2 $TARGET.c -o ${TARGET}_fdo -fprofile-use=${TARGET}_instrumented-$TARGET.gcda -g -fno-tree-vectorize
echo "---running fdo---"
./${TARGET}_fdo
echo ""
echo "---running autofdo with pmu sampling---"
python3 /scratch/iansseijelly/pmu-tools/ocperf.py record -b -e br_inst_retired.near_taken:pp -- ./${TARGET}_2
echo ""
/scratch/iansseijelly/autofdo/build/create_gcov --binary=./${TARGET}_2 --profile=perf.data --gcov=${TARGET}.gcov -gcov_version=1
gcc -O2 -fauto-profile=${TARGET}.gcov $TARGET.c -o ${TARGET}_autofdo -g -fno-tree-vectorize
echo "---running autofdo---"
./${TARGET}_autofdo
