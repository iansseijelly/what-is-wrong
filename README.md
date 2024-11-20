# GCC Auto-Vectorization on Basic Block Parts
This repo contains steps to reproduce an interesting discovery where gcc tries to auto-vectorzie bubble sort and lead to significant performance drops. 

## Usage
Run `./test.sh sort gcc` to obtain results on -O0, -O1, -O2, -O3, -Os, fdo, and autofdo. 

## Findings
When activating autovectorization (-O3 for gcc11 and -O2 & -O3 for gcc12+), it would produce the following optimization message:
```
sort.c:31:26: optimized: basic block part vectorized using 8 byte vectors
```
Leading to the creation of the following assembly:
```
void bubble_sort (uint32_t *a, uint32_t n) {
    11d0:	48 89 f8             	mov    %rdi,%rax
        s = 0;
    11d3:	45 31 c0             	xor    %r8d,%r8d
    11d6:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    11dd:	00 00 00 00 
    11e1:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    11e8:	00 00 00 00 
    11ec:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    11f3:	00 00 00 00 
    11f7:	66 0f 1f 84 00 00 00 	nopw   0x0(%rax,%rax,1)
    11fe:	00 00 
            if (a[i] < a[i - 1]) {
    1200:	f3 0f 7e 00          	movq   (%rax),%xmm0
    1204:	66 0f 70 c8 e5       	pshufd $0xe5,%xmm0,%xmm1
    1209:	66 0f 7e c2          	movd   %xmm0,%edx
    120d:	66 0f 7e c9          	movd   %xmm1,%ecx
    1211:	39 d1                	cmp    %edx,%ecx
    1213:	73 0f                	jae    1224 <bubble_sort+0x64>
                a[i - 1] = t;
    1215:	66 0f 70 c0 e1       	pshufd $0xe1,%xmm0,%xmm0
                s = 1;
    121a:	41 b8 01 00 00 00    	mov    $0x1,%r8d
                a[i - 1] = t;
    1220:	66 0f d6 00          	movq   %xmm0,(%rax)
        for (i = 1; i < n; i++) {
    1224:	48 83 c0 04          	add    $0x4,%rax
    1228:	48 39 f0             	cmp    %rsi,%rax
    122b:	75 d3                	jne    1200 <bubble_sort+0x40>
    while (s) {
    122d:	45 85 c0             	test   %r8d,%r8d
    1230:	75 9e                	jne    11d0 <bubble_sort+0x10>
}
    1232:	c3                   	ret    
    1233:	66 66 2e 0f 1f 84 00 	data16 cs nopw 0x0(%rax,%rax,1)
    123a:	00 00 00 00 
    123e:	66 90                	xchg   %ax,%ax
```
For the bubble sort code:
```
void bubble_sort (uint32_t *a, uint32_t n) {
    uint32_t i, t, s = 1;
    while (s) {
        s = 0;
        for (i = 1; i < n; i++) {
            if (a[i] < a[i - 1]) {
                t = a[i];
                a[i] = a[i - 1];
                a[i - 1] = t;
                s = 1;
            }
        }
    }
}
```
This inefficient use of fixed-width simd registers made the code ~2x worse than O0 and ~5.5x worse than O3 with vectorization explicitly disabled. 
However, this also means the part for populating arrays are not vectorized, leading to performance drops. 
This phenomenum of pathologically using avx for sorting is not observable on clang+x86, clang+arm, gcc+arm, or gcc+riscv. 