echo "Cleaning up..."
# remove everything that does not end in .c, .sh, or .txt
find . -type f ! -name '*.c' ! -name '*.sh' ! -name '*.txt' -exec rm -f {} \;
