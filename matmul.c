#define _POSIX_C_SOURCE 199309L
#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <sys/time.h>
#include <time.h>
// #define ARRAY_LEN 50000
#define SIZE 500
#define ITER 10

static struct timespec tm1;

static inline void start() {
    clock_gettime(CLOCK_MONOTONIC, &tm1);
}

static inline void stop() {
    struct timespec tm2;
    clock_gettime(CLOCK_MONOTONIC, &tm2);
    unsigned long long t = (tm2.tv_sec - tm1.tv_sec) * 1000 +\
                          (tm2.tv_nsec - tm1.tv_nsec) / 1000000;
    printf("%llu ms\n", t);
}

void generate_matrix(float matrix[SIZE][SIZE]) {
    for (int i = 0; i < SIZE; i++) {
        for (int j = 0; j < SIZE; j++) {
            matrix[i][j] = (float)i/2000;
        }
    }
}

void multiply_matrices(float a[SIZE][SIZE], float b[SIZE][SIZE], float result[SIZE][SIZE]) {
    for (int i = 0; i < SIZE; i++) {
        for (int j = 0; j < SIZE; j++) {
            result[i][j] = 0;
            for (int k = 0; k < SIZE; k++) {
                result[i][j] += a[i][k] * b[k][j];
            }
        }
    }
}

int main(){
    start();
    float a[SIZE][SIZE], b[SIZE][SIZE], result[SIZE][SIZE];
    for (int i = 0; i < ITER; i++) {
        generate_matrix(a);
        generate_matrix(b);
        multiply_matrices(a, b, result);
    }
    stop();
    return 0;
}