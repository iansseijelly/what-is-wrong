for file in $(find . -type f -name '*.bin' ); do
    objdump -S $file > ${file}.dump
done
