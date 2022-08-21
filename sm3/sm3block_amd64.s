#include "textflag.h"

#define xorm(P1, P2) \
	XORL P2, P1; \
	MOVL P1, P2

#define XDWORD0 Y4
#define XDWORD1 Y5
#define XDWORD2 Y6
#define XDWORD3 Y7
#define XDWORD4 Y8

#define XWORD0 X4
#define XWORD1 X5
#define XWORD2 X6
#define XWORD3 X7
#define XWORD4 X8

#define XTMP0 Y0
#define XTMP1 Y1
#define XTMP2 Y2
#define XTMP3 Y3
#define XTMP4 Y10
#define XTMP5 Y11

#define a AX
#define b BX
#define c CX
#define d R8
#define e DX
#define f R9
#define g R10
#define h R11

#define T1 R12
#define y0 R13
#define y1 R14
#define y2 R15
#define y3 DI

// mask to convert LE -> BE
#define BYTE_FLIP_MASK 	Y13
#define X_BYTE_FLIP_MASK X13    //low half of Y13

#define NUM_BYTES DX
#define INP	DI

#define CTX	SI
#define SRND SI
#define TBL BP

// Offsets
#define XFER_SIZE 2*64*4
#define INP_END_SIZE 8
#define INP_SIZE 8

#define _XFER	0
#define _INP_END _XFER + XFER_SIZE
#define _INP _INP_END + INP_END_SIZE
#define STACK_SIZE _INP + INP_SIZE

#define ROUND_AND_SCHED_0_15_0(wj, wj2, a, b, c, d, e, f, g, h, XDWORD0, XDWORD1, XDWORD2, XDWORD3) \
	MOVL	e, y2;						  \ // y2=E
	RORXL	$20, a, y1;					\ // y1=A<<<12
	ADDL	0*4(TBL)(SRND*1), y2;				\ // y2=E+Ti
  VPALIGNR $12, XDWORD0, XDWORD1, XTMP0;\ //XTMP0 = W[-13]
	ADDL	y1, y2;						  \ // y2=(A<<<12)+E+Ti
	RORXL	$25, y2, y0;				\ // y0=((A<<<12)+E+Ti)<<<7=SS1
	XORL	y0, y1;						  \ // y1=SS1^(A<<<12)=SS2
  VPSLLD   $7, XTMP0, XTMP1;            \
	;									        \
	ADDL	(wj2 + 0*4)(SP)(SRND*1), d;						\
	MOVL	a, T1; 						\
	XORL	b, T1; 						\
  VPSRLD   $(32-7), XTMP0, XTMP2;       \
	XORL	c, T1; 						\
	ADDL	T1, d; 						\
	ADDL	y1, d;						\ // d=TT1
	VPOR     XTMP1, XTMP2, XTMP3;         \ // XTMP3 = W[-13] <<< 7
	;									      \
	ADDL	(wj + 0*4)(SP)(SRND*1), h;						\
	MOVL	e, y3;						\
	XORL	f, y3;						\
  VPALIGNR $8, XDWORD2, XDWORD3, XTMP1; \ // XTMP1 = W[-6]
	XORL	g, y3;						\
	ADDL	y3, h;						\
	ADDL	y0, h;						\ // h=TT2
	VPXOR    XTMP3, XTMP1, XTMP1;         \ // XTMP1 = W[-6] ^ (W[-13]<<<7)  outside
	;									      \
	RORXL	$23, h, y2;					\
	RORXL	$15, h, y3;					\
	XORL	h, y2;    					\
  VPALIGNR $12, XDWORD1, XDWORD2, XTMP0;\ // XTMP0 = W[-9]
	;                 				\
	MOVL	d, h;     					\
	XORL	y2, y3;   					\
	MOVL	y3, d;    					\
	VPXOR    XDWORD0, XTMP0, XTMP0;       \ // XTMP0 = W[-9] ^ W[-16]   inside
	;                 				\
	RORXL	$23, b, b; 					\
	RORXL	$13, f, f;          \
  VPSHUFD $0xA5, XDWORD3, XTMP2        // XTMP2 = W[-3] {BBAA} 待扩展

#define ROUND_AND_SCHED_0_15_1(wj, wj2, a, b, c, d, e, f, g, h, XDWORD0, XDWORD1, XDWORD2, XDWORD3) \
	MOVL	e, y2;						\ // y2=E
	RORXL	$20, a, y1;					\ // y1=A<<<12
	ADDL	1*4(TBL)(SRND*1), y2;				\ // y2=E+Ti
  VPSLLQ  $15, XTMP2, XTMP3;           \ // XTMP3 = W[-3] <<< 15 {BxAx}
	ADDL	y1, y2;						\ // y2=(A<<<12)+E+Ti
	RORXL	$25, y2, y0;					\ // y0=((A<<<12)+E+Ti)<<<7=SS1
	XORL	y0, y1;						\ // y1=SS1^(A<<<12)=SS2
	VPSHUFB shuff_00BA<>(SB), XTMP3, XTMP3;\ // XTMP3 = s1 {00BA}
	;									\
	ADDL	(wj2 + 1*4)(SP)(SRND*1), d;						\
	MOVL	a, T1; 						\
	XORL	b, T1; 						\
  VPXOR   XTMP0, XTMP3, XTMP3;         \ // XTMP3 = x {xxBA}  store to use
	XORL	c, T1; 						\
	ADDL	T1, d; 						\
	ADDL	y1, d;						\ // d=TT1
  VPSLLD  $15, XTMP3, XTMP2;            \ // XTMP2 = x << 15
	;									\
	ADDL	(wj + 1*4)(SP)(SRND*1), h;						\
	MOVL	e, y3;						\
	XORL	f, y3;						\
	VPSRLD  $(32-15), XTMP3, XTMP4;       \ // XTMP4 = x >> (32-15)
	XORL	g, y3;						\
	ADDL	y3, h;						\
	ADDL	y0, h;						\ // h=TT2
	VPOR    XTMP2, XTMP4, XTMP5;         \ // XTMP5 = x <<< 15 (xxBA)
	;									\
	RORXL	$23, h, y2;					\
	RORXL	$15, h, y3;					\
	XORL	h, y2;    					\
  VPXOR   XTMP3, XTMP5, XTMP5;         \ // XTMP5 = x ^ (x <<< 15) (xxBA)
	;                 					\
	MOVL	d, h;     					\
	XORL	y2, y3;   					\
	MOVL	y3, d;    					\
  VPSLLD  $23, XTMP3, XTMP2;           \ // XTMP3 << 23
	;                 					\
	RORXL	$23, b, b; 					\
	RORXL	$13, f, f;          \
	VPSRLD  $(32-23), XTMP3, XTMP4       // XTMP3 >> (32-23)

#define ROUND_AND_SCHED_0_15_2(wj, wj2, a, b, c, d, e, f, g, h, XDWORD0, XDWORD1, XDWORD2, XDWORD3) \
	MOVL	e, y2;						\ // y2=E
	RORXL	$20, a, y1;					\ // y1=A<<<12
	ADDL	2*4(TBL)(SRND*1), y2;				\ // y2=E+Ti
	VPOR    XTMP2, XTMP4, XTMP4;         \ // XTMP4 = x <<< 23 (xxBA)
	ADDL	y1, y2;						\ // y2=(A<<<12)+E+Ti
	RORXL	$25, y2, y0;					\ // y0=((A<<<12)+E+Ti)<<<7=SS1
	XORL	y0, y1;						\ // y1=SS1^(A<<<12)=SS2
  VPXOR   XTMP5, XTMP4, XTMP4;         \ // XTMP4 = x ^ (x <<< 15) ^ (x <<< 23) (xxBA)
	;									\
	ADDL	(wj2 + 2*4)(SP)(SRND*1), d;						\
	MOVL	a, T1; 						\
	XORL	b, T1; 						\
  VPXOR   XTMP4, XTMP1, XTMP2;         \ // XTMP2 = {. ,. , w1, w0}
	XORL	c, T1; 						\
	ADDL	T1, d; 						\
	ADDL	y1, d;						\ // d=TT1
  VPALIGNR $4, XDWORD3, XTMP2, XTMP3;  \ // XTMP3 = DCBA
	;									\
	ADDL	(wj + 2*4)(SP)(SRND*1), h;						\
	MOVL	e, y3;						\
	XORL	f, y3;						\
  VPSLLD  $15, XTMP3, XTMP4;           \ // XTMP4 = W[-3] << 15
	XORL	g, y3;						\
	ADDL	y3, h;						\
	ADDL	y0, h;						\ // h=TT2
  VPSRLD  $(32-15), XTMP3, XTMP5;      \ // XTMP5 = W[-3] >> (32-15)
	;									\
	RORXL	$23, h, y2;					\
	RORXL	$15, h, y3;					\
	XORL	h, y2;    					\
  VPOR    XTMP4, XTMP5, XTMP5;         \ // XTMP5 = W[-3] <<< 15 {DCBA}
	;                 					\
	MOVL	d, h;     					\
	XORL	y2, y3;   					\
	MOVL	y3, d;    					\
  VPXOR   XTMP0, XTMP5, XTMP3;         \ // XTMP3 = x {DCBA}
	;                 					\
	RORXL	$23, b, b; 					\
	RORXL	$13, f, f;          \
  VPSLLD  $15, XTMP3, XTMP4            // XTMP4 = XTMP3 << 15

#define ROUND_AND_SCHED_0_15_3(wj, wj2, a, b, c, d, e, f, g, h, XDWORD0, XDWORD1, XDWORD2, XDWORD3) \
	MOVL	e, y2;						\ // y2=E
	RORXL	$20, a, y1;					\ // y1=A<<<12
	ADDL	3*4(TBL)(SRND*1), y2;				\ // y2=E+Ti
  VPSRLD  $(32-15), XTMP3, XTMP5;      \ // XTMP5 = XTMP3 >> (32-15)
	ADDL	y1, y2;						\ // y2=(A<<<12)+E+Ti
	RORXL	$25, y2, y0;					\ // y0=((A<<<12)+E+Ti)<<<7=SS1
	XORL	y0, y1;						\ // y1=SS1^(A<<<12)=SS2
  VPOR    XTMP5, XTMP4, XTMP4;         \ // XTMP4 = x <<< 15 (DCBA)
	;									\
	ADDL	(wj2 + 3*4)(SP)(SRND*1), d;						\
	MOVL	a, T1; 						\
	XORL	b, T1; 						\
  VPXOR   XTMP3, XTMP4, XTMP4;         \ // XTMP4 = x ^ (x <<< 15) (DCBA)
	XORL	c, T1; 						\
	ADDL	T1, d; 						\
	ADDL	y1, d;						\ // d=TT1
  VPSLLD  $23, XTMP3, XTMP5;           \ // XTMP5 = XTMP3 << 23
	;									\
	ADDL	(wj + 3*4)(SP)(SRND*1), h;						\
	MOVL	e, y3;						\
	XORL	f, y3;						\
  VPSRLD  $(32-23), XTMP3, XTMP3;      \ // XTMP3 >> (32-23)  XTMP3 still useful?
	XORL	g, y3;						\
	ADDL	y3, h;						\
	ADDL	y0, h;						\ // h=TT2
  VPOR    XTMP3, XTMP5, XTMP5;         \ // XTMP5 = x <<< 23
	;									\
	RORXL	$23, h, y2;					\
	RORXL	$15, h, y3;					\
	XORL	h, y2;    					\
  VPXOR   XTMP5, XTMP4, XTMP4;         \ // XTMP4 = x ^ (x <<< 15) ^ (x <<< 23) (DCBA)
	;                 					\
	MOVL	d, h;     					\
	XORL	y2, y3;   					\
	MOVL	y3, d;    					\
  VPXOR   XTMP4, XTMP1, XDWORD0;       \ // XDWORD0 = {W3, W2, W1, W0,}
	;                 					\
	RORXL	$23, b, b; 					\
	RORXL	$13, f, f


#define ROUND_AND_SCHED_16_63_0(wj, wj2, a, b, c, d, e, f, g, h, XDWORD0, XDWORD1, XDWORD2, XDWORD3) \
  MOVL	e, y2;						  \ // y2=E
  RORXL	$20, a, y1;					\ // y1=A<<<12
  VPALIGNR $12, XDWORD0, XDWORD1, XTMP0;\ //XTMP0 = W[-13]
  ADDL	0*4(TBL)(SRND*1), y2;				\ // y2=E+Ti
  ADDL	y1, y2;						  \ // y2=(A<<<12)+E+Ti
  RORXL	$25, y2, y0;				\ // y0=((A<<<12)+E+Ti)<<<7=SS1
  XORL	y0, y1;						  \ // y1=SS1^(A<<<12)=SS2
  VPSLLD   $7, XTMP0, XTMP1;            \
  ;									        \
  ADDL	(wj2 + 0*4)(SP)(SRND*1), d;						\
  MOVL	a, T1; 						\
  ORL		c, T1; 						\ // a|c
  ANDL	b, T1; 						\ //(a|c)&b
  VPSRLD   $(32-7), XTMP0, XTMP2;       \
  MOVL	c, y2;						\
  ANDL	a, y2;						\
  ORL		y2, T1;						\ // (a|c)&b | a&c
  VPOR     XTMP1, XTMP2, XTMP3;         \ // XTMP3 = W[-13] <<< 7
  ADDL	T1, d; 						\
  ADDL	y1, d;						\ // d=TT1
  ;									      \
  ADDL	(wj + 0*4)(SP)(SRND*1), h;						\
  VPALIGNR $8, XDWORD2, XDWORD3, XTMP1; \ // XTMP1 = W[-6]
  MOVL	e, y3;						\
  ANDL	f, y3;						\
  ANDNL	g, e, y2;					\
  VPXOR    XTMP3, XTMP1, XTMP1;         \ // XTMP1 = W[-6] ^ (W[-13]<<<7)  outside
  ORL		y2, y3;						\
  ADDL	y3, h;						\
  ADDL	y0, h;						\ // h=TT2
  ;									      \
  VPALIGNR $12, XDWORD1, XDWORD2, XTMP0;\ // XTMP0 = W[-9]
  RORXL	$23, h, y2;					\
  RORXL	$15, h, y3;					\
  XORL	h, y2;    					\
  ;                 				\
  VPXOR    XDWORD0, XTMP0, XTMP0;       \ // XTMP0 = W[-9] ^ W[-16]   inside
  MOVL	d, h;     					\
  XORL	y2, y3;   					\
  MOVL	y3, d;    					\
  ;                 				\
  VPSHUFD $0xA5, XDWORD3, XTMP2;       \ // XTMP2 = W[-3] {BBAA} 待扩展
  RORXL	$23, b, b; 					\
  RORXL	$13, f, f

#define ROUND_AND_SCHED_16_63_1(wj, wj2, a, b, c, d, e, f, g, h, XDWORD0, XDWORD1, XDWORD2, XDWORD3) \
	MOVL	e, y2;						\ // y2=E
	RORXL	$20, a, y1;					\ // y1=A<<<12
  VPSLLQ  $15, XTMP2, XTMP3;           \ // XTMP3 = W[-3] <<< 15 {BxAx}
	ADDL	1*4(TBL)(SRND*1), y2;				\ // y2=E+Ti
	ADDL	y1, y2;						\ // y2=(A<<<12)+E+Ti
	RORXL	$25, y2, y0;					\ // y0=((A<<<12)+E+Ti)<<<7=SS1
	XORL	y0, y1;						\ // y1=SS1^(A<<<12)=SS2
	VPSHUFB shuff_00BA<>(SB), XTMP3, XTMP3;\ // XTMP3 = s1 {00BA}
	;									\
	ADDL	(wj2 + 1*4)(SP)(SRND*1), d;						\
	MOVL	a, T1; 						\
  ORL		c, T1; 						\ // a|c
	ANDL	b, T1; 						\ //(a|c)&b
  VPXOR   XTMP0, XTMP3, XTMP3;         \ // XTMP3 = x {xxBA}  store to use
	MOVL	c, y2;						\
	ANDL	a, y2;						\
	ORL		y2, T1;						\ // (a|c)&b | a&c
  VPSLLD  $15, XTMP3, XTMP2;            \ // XTMP2 = x << 15
	ADDL	T1, d; 						\
	ADDL	y1, d;						\ // d=TT1
	;									\
	ADDL	(wj + 1*4)(SP)(SRND*1), h;						\
  VPSRLD  $(32-15), XTMP3, XTMP4;       \ // XTMP4 = x >> (32-15)
	MOVL	e, y3;						\
  ANDL	f, y3;						\
	ANDNL	g, e, y2;					\
  VPOR    XTMP2, XTMP4, XTMP5;         \ // XTMP5 = x <<< 15 (xxBA)
	ORL		y2, y3;						\
	ADDL	y3, h;						\
	ADDL	y0, h;						\ // h=TT2
	;									\
  VPXOR   XTMP3, XTMP5, XTMP5;         \ // XTMP5 = x ^ (x <<< 15) (xxBA)
	RORXL	$23, h, y2;					\
	RORXL	$15, h, y3;					\
	XORL	h, y2;    					\
	;                 					\
  VPSLLD  $23, XTMP3, XTMP2;           \ // XTMP3 << 23
	MOVL	d, h;     					\
	XORL	y2, y3;   					\
	MOVL	y3, d;    					\
	;                 					\
  VPSRLD  $(32-23), XTMP3, XTMP4;      \ // XTMP3 >> (32-23)
	RORXL	$23, b, b; 					\
	RORXL	$13, f, f

#define ROUND_AND_SCHED_16_63_2(wj, wj2, a, b, c, d, e, f, g, h, XDWORD0, XDWORD1, XDWORD2, XDWORD3) \
	MOVL	e, y2;						\ // y2=E
	RORXL	$20, a, y1;					\ // y1=A<<<12
  VPOR    XTMP2, XTMP4, XTMP4;         \ // XTMP4 = x <<< 23 (xxBA)
	ADDL	2*4(TBL)(SRND*1), y2;				\ // y2=E+Ti
	ADDL	y1, y2;						\ // y2=(A<<<12)+E+Ti
	RORXL	$25, y2, y0;					\ // y0=((A<<<12)+E+Ti)<<<7=SS1
	XORL	y0, y1;						\ // y1=SS1^(A<<<12)=SS2
  VPXOR   XTMP5, XTMP4, XTMP4;         \ // XTMP4 = x ^ (x <<< 15) ^ (x <<< 23) (xxBA)
	;									\
	ADDL	(wj2 + 2*4)(SP)(SRND*1), d;						\
	MOVL	a, T1; 						\
  ORL		c, T1; 						\ // a|c
	ANDL	b, T1; 						\ //(a|c)&b
  VPXOR   XTMP4, XTMP1, XTMP2;         \ // XTMP2 = {. ,. , w1, w0}
	MOVL	c, y2;						\
	ANDL	a, y2;						\
	ORL		y2, T1;						\ // (a|c)&b | a&c
  VPALIGNR $4, XDWORD3, XTMP2, XTMP3;  \ // XTMP3 = DCBA
	ADDL	T1, d; 						\
	ADDL	y1, d;						\ // d=TT1
	;									\
	ADDL	(wj + 2*4)(SP)(SRND*1), h;						\
  VPSLLD  $15, XTMP3, XTMP4;           \ // XTMP4 = W[-3] << 15
	MOVL	e, y3;						\
  ANDL	f, y3;						\
	ANDNL	g, e, y2;					\
  VPSRLD  $(32-15), XTMP3, XTMP5;      \ // XTMP5 = W[-3] >> (32-15)
	ORL		y2, y3;						\
	ADDL	y3, h;						\
	ADDL	y0, h;						\ // h=TT2
	;									\
  VPOR    XTMP4, XTMP5, XTMP5;         \ // XTMP5 = W[-3] <<< 15 {DCBA}
	RORXL	$23, h, y2;					\
	RORXL	$15, h, y3;					\
	XORL	h, y2;    					\
	;                 					\
  VPXOR   XTMP0, XTMP5, XTMP3;         \ // XTMP3 = x {DCBA}
	MOVL	d, h;     					\
	XORL	y2, y3;   					\
	MOVL	y3, d;    					\
	;                 					\
  VPSLLD  $15, XTMP3, XTMP4;           \ // XTMP4 = XTMP3 << 15
	RORXL	$23, b, b; 					\
	RORXL	$13, f, f

#define ROUND_AND_SCHED_16_63_3(wj, wj2, a, b, c, d, e, f, g, h, XDWORD0, XDWORD1, XDWORD2, XDWORD3) \
	MOVL	e, y2;						\ // y2=E
	RORXL	$20, a, y1;					\ // y1=A<<<12
  VPSRLD  $(32-15), XTMP3, XTMP5;      \ // XTMP5 = XTMP3 >> (32-15)
	ADDL	3*4(TBL)(SRND*1), y2;				\ // y2=E+Ti
	ADDL	y1, y2;						\ // y2=(A<<<12)+E+Ti
	RORXL	$25, y2, y0;					\ // y0=((A<<<12)+E+Ti)<<<7=SS1
	XORL	y0, y1;						\ // y1=SS1^(A<<<12)=SS2
  VPOR    XTMP5, XTMP4, XTMP4;         \ // XTMP4 = x <<< 15 (DCBA)
	;									\
	ADDL	(wj2 + 3*4)(SP)(SRND*1), d;						\
	MOVL	a, T1; 						\
  ORL		c, T1; 						\ // a|c
	ANDL	b, T1; 						\ //(a|c)&b
  VPXOR   XTMP3, XTMP4, XTMP4;         \ // XTMP4 = x ^ (x <<< 15) (DCBA)
	MOVL	c, y2;						\
	ANDL	a, y2;						\
	ORL		y2, T1;						\ // (a|c)&b | a&c
	ADDL	T1, d; 						\
  VPSLLD  $23, XTMP3, XTMP5;           \ // XTMP5 = XTMP3 << 23
	ADDL	y1, d;						\ // d=TT1
	;									\
	ADDL	(wj + 3*4)(SP)(SRND*1), h;						\
	MOVL	e, y3;						\
  ANDL	f, y3;						\
  VPSRLD  $(32-23), XTMP3, XTMP3;      \ // XTMP3 >> (32-23)  XTMP3 still useful?
	ANDNL	g, e, y2;					\
	ORL		y2, y3;						\
	ADDL	y3, h;						\
  VPOR    XTMP3, XTMP5, XTMP5;         \ // XTMP5 = x <<< 23
	ADDL	y0, h;						\ // h=TT2
	;									\
	RORXL	$23, h, y2;					\
	RORXL	$15, h, y3;					\
  VPXOR   XTMP5, XTMP4, XTMP4;         \ // XTMP4 = x ^ (x <<< 15) ^ (x <<< 23) (DCBA)
	XORL	h, y2;    					\
	;                 					\
	MOVL	d, h;     					\
	XORL	y2, y3;   					\
  VPXOR   XTMP4, XTMP1, XDWORD0;       \ // XDWORD0 = {W3, W2, W1, W0,}
	MOVL	y3, d;    					\
	;                 					\
	RORXL	$23, b, b; 					\
	RORXL	$13, f, f


#define ROUND_0_15_0(wj, wj2, flag, a, b, c, d, e, f, g, h) \
	MOVL	e, y2;						  \ // y2=E
	RORXL	$20, a, y1;					\ // y1=A<<<12
	ADDL	(0*4+flag*16)(TBL)(SRND*1), y2;				\ // y2=E+Ti
	ADDL	y1, y2;						  \ // y2=(A<<<12)+E+Ti
	RORXL	$25, y2, y0;				\ // y0=((A<<<12)+E+Ti)<<<7=SS1
	XORL	y0, y1;						  \ // y1=SS1^(A<<<12)=SS2
	;									        \
	ADDL	(wj2 + 0*4)(SP)(SRND*1), d;						\
	MOVL	a, T1; 						\
	XORL	b, T1; 						\
	XORL	c, T1; 						\
	ADDL	T1, d; 						\
	ADDL	y1, d;						\ // d=TT1
	;									      \
	ADDL	(wj + 0*4)(SP)(SRND*1), h;						\
	MOVL	e, y3;						\
	XORL	f, y3;						\
	XORL	g, y3;						\
	ADDL	y3, h;						\
	ADDL	y0, h;						\ // h=TT2
	;									      \
	RORXL	$23, h, y2;					\
	RORXL	$15, h, y3;					\
	XORL	h, y2;    					\
	;                 				\
	MOVL	d, h;     					\
	XORL	y2, y3;   					\
	MOVL	y3, d;    					\
	;                 				\
	RORXL	$23, b, b; 					\
	RORXL	$13, f, f

#define ROUND_0_15_1(wj, wj2, flag, a, b, c, d, e, f, g, h) \
	MOVL	e, y2;						\ // y2=E
	RORXL	$20, a, y1;					\ // y1=A<<<12
	ADDL	(1*4+flag*16)(TBL)(SRND*1), y2;				\ // y2=E+Ti
	ADDL	y1, y2;						\ // y2=(A<<<12)+E+Ti
	RORXL	$25, y2, y0;					\ // y0=((A<<<12)+E+Ti)<<<7=SS1
	XORL	y0, y1;						\ // y1=SS1^(A<<<12)=SS2
	;									\
	ADDL	(wj2 + 1*4)(SP)(SRND*1), d;						\
	MOVL	a, T1; 						\
	XORL	b, T1; 						\
	XORL	c, T1; 						\
	ADDL	T1, d; 						\
	ADDL	y1, d;						\ // d=TT1
	;									\
	ADDL	(wj + 1*4)(SP)(SRND*1), h;						\
	MOVL	e, y3;						\
	XORL	f, y3;						\
	XORL	g, y3;						\
	ADDL	y3, h;						\
	ADDL	y0, h;						\ // h=TT2
	;									\
	RORXL	$23, h, y2;					\
	RORXL	$15, h, y3;					\
	XORL	h, y2;    					\
	;                 					\
	MOVL	d, h;     					\
	XORL	y2, y3;   					\
	MOVL	y3, d;    					\
	;                 					\
	RORXL	$23, b, b; 					\
	RORXL	$13, f, f

#define ROUND_0_15_2(wj, wj2, flag, a, b, c, d, e, f, g, h) \
	MOVL	e, y2;						\ // y2=E
	RORXL	$20, a, y1;					\ // y1=A<<<12
	ADDL	(2*4+flag*16)(TBL)(SRND*1), y2;				\ // y2=E+Ti
	ADDL	y1, y2;						\ // y2=(A<<<12)+E+Ti
	RORXL	$25, y2, y0;					\ // y0=((A<<<12)+E+Ti)<<<7=SS1
	XORL	y0, y1;						\ // y1=SS1^(A<<<12)=SS2
	;									\
	ADDL	(wj2 + 2*4)(SP)(SRND*1), d;						\
	MOVL	a, T1; 						\
	XORL	b, T1; 						\
	XORL	c, T1; 						\
	ADDL	T1, d; 						\
	ADDL	y1, d;						\ // d=TT1
	;									\
	ADDL	(wj + 2*4)(SP)(SRND*1), h;						\
	MOVL	e, y3;						\
	XORL	f, y3;						\
	XORL	g, y3;						\
	ADDL	y3, h;						\
	ADDL	y0, h;						\ // h=TT2
	;									\
	RORXL	$23, h, y2;					\
	RORXL	$15, h, y3;					\
	XORL	h, y2;    					\
	;                 					\
	MOVL	d, h;     					\
	XORL	y2, y3;   					\
	MOVL	y3, d;    					\
	;                 					\
	RORXL	$23, b, b; 					\
	RORXL	$13, f, f

#define ROUND_0_15_3(wj, wj2, flag, a, b, c, d, e, f, g, h) \
	MOVL	e, y2;						\ // y2=E
	RORXL	$20, a, y1;					\ // y1=A<<<12
	ADDL	(3*4+flag*16)(TBL)(SRND*1), y2;				\ // y2=E+Ti
	ADDL	y1, y2;						\ // y2=(A<<<12)+E+Ti
	RORXL	$25, y2, y0;					\ // y0=((A<<<12)+E+Ti)<<<7=SS1
	XORL	y0, y1;						\ // y1=SS1^(A<<<12)=SS2
	;									\
	ADDL	(wj2 + 3*4)(SP)(SRND*1), d;						\
	MOVL	a, T1; 						\
	XORL	b, T1; 						\
	XORL	c, T1; 						\
	ADDL	T1, d; 						\
	ADDL	y1, d;						\ // d=TT1
	;									\
	ADDL	(wj + 3*4)(SP)(SRND*1), h;						\
	MOVL	e, y3;						\
	XORL	f, y3;						\
	XORL	g, y3;						\
	ADDL	y3, h;						\
	ADDL	y0, h;						\ // h=TT2
	;									\
	RORXL	$23, h, y2;					\
	RORXL	$15, h, y3;					\
	XORL	h, y2;    					\
	;                 					\
	MOVL	d, h;     					\
	XORL	y2, y3;   					\
	MOVL	y3, d;    					\
	;                 					\
	RORXL	$23, b, b; 					\
	RORXL	$13, f, f


#define ROUND_16_63_0(wj, wj2, flag, a, b, c, d, e, f, g, h) \
	MOVL	e, y2;						  \ // y2=E
	RORXL	$20, a, y1;					\ // y1=A<<<12
	ADDL	(0*4+flag*16)(TBL)(SRND*1), y2;				\ // y2=E+Ti
	ADDL	y1, y2;						  \ // y2=(A<<<12)+E+Ti
	RORXL	$25, y2, y0;				\ // y0=((A<<<12)+E+Ti)<<<7=SS1
	XORL	y0, y1;						  \ // y1=SS1^(A<<<12)=SS2
	;									        \
	ADDL	(wj2 + 0*4)(SP)(SRND*1), d;						\
	MOVL	a, T1; 						\
  ORL		c, T1; 						\ // a|c
	ANDL	b, T1; 						\ //(a|c)&b
	MOVL	c, y2;						\
	ANDL	a, y2;						\
	ORL		y2, T1;						\ // (a|c)&b | a&c
	ADDL	T1, d; 						\
	ADDL	y1, d;						\ // d=TT1
	;									      \
	ADDL	(wj + 0*4)(SP)(SRND*1), h;						\
	MOVL	e, y3;						\
  ANDL	f, y3;						\
	ANDNL	g, e, y2;					\
	ORL		y2, y3;						\
	ADDL	y3, h;						\
	ADDL	y0, h;						\ // h=TT2
	;									      \
	RORXL	$23, h, y2;					\
	RORXL	$15, h, y3;					\
	XORL	h, y2;    					\
	;                 				\
	MOVL	d, h;     					\
	XORL	y2, y3;   					\
	MOVL	y3, d;    					\
	;                 				\
	RORXL	$23, b, b; 					\
	RORXL	$13, f, f

#define ROUND_16_63_1(wj, wj2, flag, a, b, c, d, e, f, g, h) \
	MOVL	e, y2;						\ // y2=E
	RORXL	$20, a, y1;					\ // y1=A<<<12
	ADDL	(1*4+flag*16)(TBL)(SRND*1), y2;				\ // y2=E+Ti
	ADDL	y1, y2;						\ // y2=(A<<<12)+E+Ti
	RORXL	$25, y2, y0;					\ // y0=((A<<<12)+E+Ti)<<<7=SS1
	XORL	y0, y1;						\ // y1=SS1^(A<<<12)=SS2
	;									\
	ADDL	(wj2 + 1*4)(SP)(SRND*1), d;						\
	MOVL	a, T1; 						\
  ORL		c, T1; 						\ // a|c
	ANDL	b, T1; 						\ //(a|c)&b
	MOVL	c, y2;						\
	ANDL	a, y2;						\
	ORL		y2, T1;						\ // (a|c)&b | a&c
	ADDL	T1, d; 						\
	ADDL	y1, d;						\ // d=TT1
	;									\
	ADDL	(wj + 1*4)(SP)(SRND*1), h;						\
	MOVL	e, y3;						\
  ANDL	f, y3;						\
	ANDNL	g, e, y2;					\
	ORL		y2, y3;						\
	ADDL	y3, h;						\
	ADDL	y0, h;						\ // h=TT2
	;									\
	RORXL	$23, h, y2;					\
	RORXL	$15, h, y3;					\
	XORL	h, y2;    					\
	;                 					\
	MOVL	d, h;     					\
	XORL	y2, y3;   					\
	MOVL	y3, d;    					\
	;                 					\
	RORXL	$23, b, b; 					\
	RORXL	$13, f, f

#define ROUND_16_63_2(wj, wj2, flag, a, b, c, d, e, f, g, h) \
	MOVL	e, y2;						\ // y2=E
	RORXL	$20, a, y1;					\ // y1=A<<<12
	ADDL	(2*4+flag*16)(TBL)(SRND*1), y2;				\ // y2=E+Ti
	ADDL	y1, y2;						\ // y2=(A<<<12)+E+Ti
	RORXL	$25, y2, y0;					\ // y0=((A<<<12)+E+Ti)<<<7=SS1
	XORL	y0, y1;						\ // y1=SS1^(A<<<12)=SS2
	;									\
	ADDL	(wj2 + 2*4)(SP)(SRND*1), d;						\
	MOVL	a, T1; 						\
  ORL		c, T1; 						\ // a|c
	ANDL	b, T1; 						\ //(a|c)&b
	MOVL	c, y2;						\
	ANDL	a, y2;						\
	ORL		y2, T1;						\ // (a|c)&b | a&c
	ADDL	T1, d; 						\
	ADDL	y1, d;						\ // d=TT1
	;									\
	ADDL	(wj + 2*4)(SP)(SRND*1), h;						\
	MOVL	e, y3;						\
  ANDL	f, y3;						\
	ANDNL	g, e, y2;					\
	ORL		y2, y3;						\
	ADDL	y3, h;						\
	ADDL	y0, h;						\ // h=TT2
	;									\
	RORXL	$23, h, y2;					\
	RORXL	$15, h, y3;					\
	XORL	h, y2;    					\
	;                 					\
	MOVL	d, h;     					\
	XORL	y2, y3;   					\
	MOVL	y3, d;    					\
	;                 					\
	RORXL	$23, b, b; 					\
	RORXL	$13, f, f

#define ROUND_16_63_3(wj, wj2, flag, a, b, c, d, e, f, g, h) \
	MOVL	e, y2;						\ // y2=E
	RORXL	$20, a, y1;					\ // y1=A<<<12
	ADDL	(3*4+flag*16)(TBL)(SRND*1), y2;				\ // y2=E+Ti
	ADDL	y1, y2;						\ // y2=(A<<<12)+E+Ti
	RORXL	$25, y2, y0;					\ // y0=((A<<<12)+E+Ti)<<<7=SS1
	XORL	y0, y1;						\ // y1=SS1^(A<<<12)=SS2
	;									\
	ADDL	(wj2 + 3*4)(SP)(SRND*1), d;						\
	MOVL	a, T1; 						\
  ORL		c, T1; 						\ // a|c
	ANDL	b, T1; 						\ //(a|c)&b
	MOVL	c, y2;						\
	ANDL	a, y2;						\
	ORL		y2, T1;						\ // (a|c)&b | a&c
	ADDL	T1, d; 						\
	ADDL	y1, d;						\ // d=TT1
	;									\
	ADDL	(wj + 3*4)(SP)(SRND*1), h;						\
	MOVL	e, y3;						\
  ANDL	f, y3;						\
	ANDNL	g, e, y2;					\
	ORL		y2, y3;						\
	ADDL	y3, h;						\
	ADDL	y0, h;						\ // h=TT2
	;									\
	RORXL	$23, h, y2;					\
	RORXL	$15, h, y3;					\
	XORL	h, y2;    					\
	;                 					\
	MOVL	d, h;     					\
	XORL	y2, y3;   					\
	MOVL	y3, d;    					\
	;                 					\
	RORXL	$23, b, b; 					\
	RORXL	$13, f, f

// (68+64)*4*2+8+8+8
TEXT ·blockasm(SB), 0, $1080-48
	CMPB ·useAVX2(SB), $1
	JE   avx2

avx2:
  MOVQ dig+0(FP), CTX        //dig.h
  MOVQ p_base+8(FP), INP          //Input
  MOVQ p_len+16(FP), NUM_BYTES    //INP_LEN

  LEAQ -64(INP)(NUM_BYTES*1), NUM_BYTES // Pointer to the last block
  MOVQ NUM_BYTES, _INP_END(SP)

  CMPQ NUM_BYTES, INP
  JE   avx2_only_one_block

  MOVL 0(CTX), a  // a = H0
  MOVL 4(CTX), b  // b = H1
  MOVL 8(CTX), c  // c = H2
  MOVL 12(CTX), d // d = H3
  MOVL 16(CTX), e // e = H4
  MOVL 20(CTX), f // f = H5
  MOVL 24(CTX), g // g = H6
  MOVL 28(CTX), h // h = H7

loop0: //load input

  VMOVDQU (0*32)(INP), XTMP0
  VMOVDQU (1*32)(INP), XTMP1
  VMOVDQU (2*32)(INP), XTMP2
  VMOVDQU (3*32)(INP), XTMP3

  VMOVDQU flip_mask<>(SB), BYTE_FLIP_MASK

  // Apply Byte Flip Mask: LE -> BE
	VPSHUFB BYTE_FLIP_MASK, XTMP0, XTMP0
	VPSHUFB BYTE_FLIP_MASK, XTMP1, XTMP1
	VPSHUFB BYTE_FLIP_MASK, XTMP2, XTMP2
	VPSHUFB BYTE_FLIP_MASK, XTMP3, XTMP3

	// Transpose data into high/low parts
  VPERM2I128 $0x20, XTMP2, XTMP0, XDWORD0 // w3, w2, w1, w0
	VPERM2I128 $0x31, XTMP2, XTMP0, XDWORD1 // w7, w6, w5, w4
	VPERM2I128 $0x20, XTMP3, XTMP1, XDWORD2 // w11, w10, w9, w8
	VPERM2I128 $0x31, XTMP3, XTMP1, XDWORD3 // w15, w14, w13, w12

  MOVQ $TSHF<>(SB), TBL

avx2_last_block_enter:
  ADDQ $64, INP
  MOVQ INP, _INP(SP)
  XORQ SRND, SRND

loop1_1: //w16-w31 and first 16 rounds, srnd:4*32

  VMOVDQU XDWORD0, (_XFER + 0*32)(SP)(SRND*1)     //wj
  VPXOR   XDWORD1, XDWORD0, XDWORD4               //wj2
  VMOVDQU XDWORD4, (_XFER + 17*32)(SP)(SRND*1)
  ROUND_AND_SCHED_0_15_0(_XFER + 0*32, _XFER + 17*32, a, b, c, d, e, f, g, h, XDWORD0, XDWORD1, XDWORD2, XDWORD3)
  ROUND_AND_SCHED_0_15_1(_XFER + 0*32, _XFER + 17*32, h, a, b, c, d, e, f, g, XDWORD0, XDWORD1, XDWORD2, XDWORD3)
  ROUND_AND_SCHED_0_15_2(_XFER + 0*32, _XFER + 17*32, g, h, a, b, c, d, e, f, XDWORD0, XDWORD1, XDWORD2, XDWORD3)
  ROUND_AND_SCHED_0_15_3(_XFER + 0*32, _XFER + 17*32, f, g, h, a, b, c, d, e, XDWORD0, XDWORD1, XDWORD2, XDWORD3)

	ADDQ $32, SRND

  VMOVDQU XDWORD1, (_XFER + 0*32)(SP)(SRND*1)
	VPXOR   XDWORD2, XDWORD1, XDWORD4
	VMOVDQU XDWORD4, (_XFER + 17*32)(SP)(SRND*1)
	ROUND_AND_SCHED_0_15_0(_XFER + 0*32, _XFER + 17*32, e, f, g, h, a, b, c, d, XDWORD1, XDWORD2, XDWORD3, XDWORD0)
	ROUND_AND_SCHED_0_15_1(_XFER + 0*32, _XFER + 17*32, d, e, f, g, h, a, b, c, XDWORD1, XDWORD2, XDWORD3, XDWORD0)
	ROUND_AND_SCHED_0_15_2(_XFER + 0*32, _XFER + 17*32, c, d, e, f, g, h, a, b, XDWORD1, XDWORD2, XDWORD3, XDWORD0)
	ROUND_AND_SCHED_0_15_3(_XFER + 0*32, _XFER + 17*32, b, c, d, e, f, g, h, a, XDWORD1, XDWORD2, XDWORD3, XDWORD0)

	ADDQ $32, SRND

  VMOVDQU XDWORD2, (_XFER + 0*32)(SP)(SRND*1)
  VPXOR   XDWORD3, XDWORD2, XDWORD4
  VMOVDQU XDWORD4, (_XFER + 17*32)(SP)(SRND*1)
  ROUND_AND_SCHED_0_15_0(_XFER + 0*32, _XFER + 17*32,  a, b, c, d, e, f, g, h, XDWORD2, XDWORD3, XDWORD0, XDWORD1)
  ROUND_AND_SCHED_0_15_1(_XFER + 0*32, _XFER + 17*32,  h, a, b, c, d, e, f, g, XDWORD2, XDWORD3, XDWORD0, XDWORD1)
  ROUND_AND_SCHED_0_15_2(_XFER + 0*32, _XFER + 17*32,  g, h, a, b, c, d, e, f, XDWORD2, XDWORD3, XDWORD0, XDWORD1)
  ROUND_AND_SCHED_0_15_3(_XFER + 0*32, _XFER + 17*32,  f, g, h, a, b, c, d, e, XDWORD2, XDWORD3, XDWORD0, XDWORD1)

  ADDQ $32, SRND

  VMOVDQU XDWORD3, (_XFER + 0*32)(SP)(SRND*1)
  VPXOR   XDWORD0, XDWORD3, XDWORD4
  VMOVDQU XDWORD4, (_XFER + 17*32)(SP)(SRND*1)
  ROUND_AND_SCHED_0_15_0(_XFER + 0*32, _XFER + 17*32,  e, f, g, h, a, b, c, d, XDWORD3, XDWORD0, XDWORD1, XDWORD2)
  ROUND_AND_SCHED_0_15_1(_XFER + 0*32, _XFER + 17*32,  d, e, f, g, h, a, b, c, XDWORD3, XDWORD0, XDWORD1, XDWORD2)
  ROUND_AND_SCHED_0_15_2(_XFER + 0*32, _XFER + 17*32,  c, d, e, f, g, h, a, b, XDWORD3, XDWORD0, XDWORD1, XDWORD2)
  ROUND_AND_SCHED_0_15_3(_XFER + 0*32, _XFER + 17*32,  b, c, d, e, f, g, h, a, XDWORD3, XDWORD0, XDWORD1, XDWORD2)
  ADDQ $32, SRND

loop1_2: //w32-w64, srnd 3*4*32, 将tshift（传参）摆脱srnd依赖,重写round_and_sched,减少3条addq

  VMOVDQU XDWORD0, (_XFER + 0*32)(SP)(SRND*1)     //wj
  VPXOR   XDWORD1, XDWORD0, XDWORD4               //wj2
  VMOVDQU XDWORD4, (_XFER + 17*32)(SP)(SRND*1)
  ROUND_AND_SCHED_16_63_0(_XFER + 0*32, _XFER + 17*32, a, b, c, d, e, f, g, h, XDWORD0, XDWORD1, XDWORD2, XDWORD3)
  ROUND_AND_SCHED_16_63_1(_XFER + 0*32, _XFER + 17*32, h, a, b, c, d, e, f, g, XDWORD0, XDWORD1, XDWORD2, XDWORD3)
  ROUND_AND_SCHED_16_63_2(_XFER + 0*32, _XFER + 17*32, g, h, a, b, c, d, e, f, XDWORD0, XDWORD1, XDWORD2, XDWORD3)
  ROUND_AND_SCHED_16_63_3(_XFER + 0*32, _XFER + 17*32, f, g, h, a, b, c, d, e, XDWORD0, XDWORD1, XDWORD2, XDWORD3)

  ADDQ $32, SRND

  VMOVDQU XDWORD1, (_XFER + 0*32)(SP)(SRND*1)
  VPXOR   XDWORD2, XDWORD1, XDWORD4
  VMOVDQU XDWORD4, (_XFER + 17*32)(SP)(SRND*1)
  ROUND_AND_SCHED_16_63_0(_XFER + 0*32, _XFER + 17*32, e, f, g, h, a, b, c, d, XDWORD1, XDWORD2, XDWORD3, XDWORD0)
  ROUND_AND_SCHED_16_63_1(_XFER + 0*32, _XFER + 17*32, d, e, f, g, h, a, b, c, XDWORD1, XDWORD2, XDWORD3, XDWORD0)
  ROUND_AND_SCHED_16_63_2(_XFER + 0*32, _XFER + 17*32, c, d, e, f, g, h, a, b, XDWORD1, XDWORD2, XDWORD3, XDWORD0)
  ROUND_AND_SCHED_16_63_3(_XFER + 0*32, _XFER + 17*32, b, c, d, e, f, g, h, a, XDWORD1, XDWORD2, XDWORD3, XDWORD0)

  ADDQ $32, SRND

  VMOVDQU XDWORD2, (_XFER + 0*32)(SP)(SRND*1)
  VPXOR   XDWORD3, XDWORD2, XDWORD4
  VMOVDQU XDWORD4, (_XFER + 17*32)(SP)(SRND*1)
  ROUND_AND_SCHED_16_63_0(_XFER + 0*32, _XFER + 17*32,  a, b, c, d, e, f, g, h, XDWORD2, XDWORD3, XDWORD0, XDWORD1)
  ROUND_AND_SCHED_16_63_1(_XFER + 0*32, _XFER + 17*32,  h, a, b, c, d, e, f, g, XDWORD2, XDWORD3, XDWORD0, XDWORD1)
  ROUND_AND_SCHED_16_63_2(_XFER + 0*32, _XFER + 17*32,  g, h, a, b, c, d, e, f, XDWORD2, XDWORD3, XDWORD0, XDWORD1)
  ROUND_AND_SCHED_16_63_3(_XFER + 0*32, _XFER + 17*32,  f, g, h, a, b, c, d, e, XDWORD2, XDWORD3, XDWORD0, XDWORD1)

  ADDQ $32, SRND

  VMOVDQU XDWORD3, (_XFER + 0*32)(SP)(SRND*1)
  VPXOR   XDWORD0, XDWORD3, XDWORD4
  VMOVDQU XDWORD4, (_XFER + 17*32)(SP)(SRND*1)
  ROUND_AND_SCHED_16_63_0(_XFER + 0*32, _XFER + 17*32,  e, f, g, h, a, b, c, d, XDWORD3, XDWORD0, XDWORD1, XDWORD2)
  ROUND_AND_SCHED_16_63_1(_XFER + 0*32, _XFER + 17*32,  d, e, f, g, h, a, b, c, XDWORD3, XDWORD0, XDWORD1, XDWORD2)
  ROUND_AND_SCHED_16_63_2(_XFER + 0*32, _XFER + 17*32,  c, d, e, f, g, h, a, b, XDWORD3, XDWORD0, XDWORD1, XDWORD2)
  ROUND_AND_SCHED_16_63_3(_XFER + 0*32, _XFER + 17*32,  b, c, d, e, f, g, h, a, XDWORD3, XDWORD0, XDWORD1, XDWORD2)

  ADDQ $32, SRND
  CMPQ SRND, $3*4*32
	JB   loop1_2

loop1_3: //w64-w67, last 16rounds and 4 msg_sched

  VMOVDQU XDWORD0, (_XFER + 0*32)(SP)(SRND*1)     //wj
  VPXOR   XDWORD1, XDWORD0, XDWORD4               //wj2
  VMOVDQU XDWORD4, (_XFER + 17*32)(SP)(SRND*1)
  ROUND_AND_SCHED_16_63_0(_XFER + 0*32, _XFER + 17*32, a, b, c, d, e, f, g, h, XDWORD0, XDWORD1, XDWORD2, XDWORD3)
  ROUND_AND_SCHED_16_63_1(_XFER + 0*32, _XFER + 17*32, h, a, b, c, d, e, f, g, XDWORD0, XDWORD1, XDWORD2, XDWORD3)
  ROUND_AND_SCHED_16_63_2(_XFER + 0*32, _XFER + 17*32, g, h, a, b, c, d, e, f, XDWORD0, XDWORD1, XDWORD2, XDWORD3)
  ROUND_AND_SCHED_16_63_3(_XFER + 0*32, _XFER + 17*32, f, g, h, a, b, c, d, e, XDWORD0, XDWORD1, XDWORD2, XDWORD3)
  ADDQ $32, SRND

  VMOVDQU XDWORD1, (_XFER + 0*32)(SP)(SRND*1)     //wj
  VPXOR   XDWORD2, XDWORD1, XDWORD4               //wj2
  VMOVDQU XDWORD4, (_XFER + 17*32)(SP)(SRND*1)
  ROUND_16_63_0(_XFER + 0*32, _XFER + 17*32, 0, e, f, g, h, a, b, c, d)
  ROUND_16_63_1(_XFER + 0*32, _XFER + 17*32, 0, d, e, f, g, h, a, b, c)
  ROUND_16_63_2(_XFER + 0*32, _XFER + 17*32, 0, c, d, e, f, g, h, a, b)
  ROUND_16_63_3(_XFER + 0*32, _XFER + 17*32, 0, b, c, d, e, f, g, h, a)
  ADDQ $32, SRND

  VMOVDQU XDWORD2, (_XFER + 0*32)(SP)(SRND*1)     //wj
  VPXOR   XDWORD3, XDWORD2, XDWORD4               //wj2
  VMOVDQU XDWORD4, (_XFER + 17*32)(SP)(SRND*1)
	ROUND_16_63_0(_XFER + 0*32, _XFER + 17*32, 0, a, b, c, d, e, f, g, h)
	ROUND_16_63_1(_XFER + 0*32, _XFER + 17*32, 0, h, a, b, c, d, e, f, g)
	ROUND_16_63_2(_XFER + 0*32, _XFER + 17*32, 0, g, h, a, b, c, d, e, f)
	ROUND_16_63_3(_XFER + 0*32, _XFER + 17*32, 0, f, g, h, a, b, c, d, e)
  ADDQ $32, SRND

  VMOVDQU XDWORD3, (_XFER + 0*32)(SP)(SRND*1)     //wj
  VPXOR   XDWORD0, XDWORD3, XDWORD4               //wj2
  VMOVDQU XDWORD4, (_XFER + 17*32)(SP)(SRND*1)
  ROUND_16_63_0(_XFER + 0*32, _XFER + 17*32, 0, e, f, g, h, a, b, c, d)
  ROUND_16_63_1(_XFER + 0*32, _XFER + 17*32, 0, d, e, f, g, h, a, b, c)
  ROUND_16_63_2(_XFER + 0*32, _XFER + 17*32, 0, c, d, e, f, g, h, a, b)
  ROUND_16_63_3(_XFER + 0*32, _XFER + 17*32, 0, b, c, d, e, f, g, h, a)
  ADDQ $32, SRND

  MOVQ dig+0(FP), CTX      //dig.h
	MOVQ _INP(SP), INP

  xorm(  0(CTX), a)
  xorm(  4(CTX), b)
  xorm(  8(CTX), c)
  xorm( 12(CTX), d)
  xorm( 16(CTX), e)
  xorm( 20(CTX), f)
  xorm( 24(CTX), g)
  xorm( 28(CTX), h)

  CMPQ _INP_END(SP), INP
  JB   done_hash

  XORQ SRND, SRND

loop2_0: //Do second block with previously scheduled results wj/wj2

  ROUND_0_15_0(_XFER + 0*32 + 16, _XFER + 17*32 + 16, 1, a, b, c, d, e, f, g, h)
  ROUND_0_15_1(_XFER + 0*32 + 16, _XFER + 17*32 + 16, 1, h, a, b, c, d, e, f, g)
  ROUND_0_15_2(_XFER + 0*32 + 16, _XFER + 17*32 + 16, 1, g, h, a, b, c, d, e, f)
  ROUND_0_15_3(_XFER + 0*32 + 16, _XFER + 17*32 + 16, 1, f, g, h, a, b, c, d, e)
  ADDQ $32, SRND

  ROUND_0_15_0(_XFER + 0*32 + 16, _XFER + 17*32 + 16, 1, e, f, g, h, a, b, c, d)
  ROUND_0_15_1(_XFER + 0*32 + 16, _XFER + 17*32 + 16, 1, d, e, f, g, h, a, b, c)
  ROUND_0_15_2(_XFER + 0*32 + 16, _XFER + 17*32 + 16, 1, c, d, e, f, g, h, a, b)
  ROUND_0_15_3(_XFER + 0*32 + 16, _XFER + 17*32 + 16, 1, b, c, d, e, f, g, h, a)
  ADDQ $32, SRND

  CMPQ SRND, $4*32
  JB   loop2_0

loop2_1:
  ROUND_16_63_0(_XFER + 0*32 + 16, _XFER + 17*32 + 16, 1, a, b, c, d, e, f, g, h)
  ROUND_16_63_1(_XFER + 0*32 + 16, _XFER + 17*32 + 16, 1, h, a, b, c, d, e, f, g)
  ROUND_16_63_2(_XFER + 0*32 + 16, _XFER + 17*32 + 16, 1, g, h, a, b, c, d, e, f)
  ROUND_16_63_3(_XFER + 0*32 + 16, _XFER + 17*32 + 16, 1, f, g, h, a, b, c, d, e)
  ADDQ $32, SRND

  ROUND_16_63_0(_XFER + 0*32 + 16, _XFER + 17*32 + 16, 1, e, f, g, h, a, b, c, d)
  ROUND_16_63_1(_XFER + 0*32 + 16, _XFER + 17*32 + 16, 1, d, e, f, g, h, a, b, c)
  ROUND_16_63_2(_XFER + 0*32 + 16, _XFER + 17*32 + 16, 1, c, d, e, f, g, h, a, b)
  ROUND_16_63_3(_XFER + 0*32 + 16, _XFER + 17*32 + 16, 1, b, c, d, e, f, g, h, a)
  ADDQ $32, SRND

  CMPQ SRND, $4*4*32
  JB   loop2_1

  MOVQ dig+0(FP), CTX      //Output
  MOVQ _INP(SP), INP
  ADDQ $64, INP

  xorm(  0(CTX), a)
  xorm(  4(CTX), b)
  xorm(  8(CTX), c)
  xorm( 12(CTX), d)
  xorm( 16(CTX), e)
  xorm( 20(CTX), f)
  xorm( 24(CTX), g)
  xorm( 28(CTX), h)

  CMPQ _INP_END(SP), INP
  JA   loop0
  JB   done_hash


avx2_do_last_block:

	VMOVDQU 0(INP), XWORD0
	VMOVDQU 16(INP), XWORD1
	VMOVDQU 32(INP), XWORD2
	VMOVDQU 48(INP), XWORD3

	VMOVDQU flip_mask<>(SB), BYTE_FLIP_MASK

	VPSHUFB X_BYTE_FLIP_MASK, XWORD0, XWORD0
	VPSHUFB X_BYTE_FLIP_MASK, XWORD1, XWORD1
	VPSHUFB X_BYTE_FLIP_MASK, XWORD2, XWORD2
	VPSHUFB X_BYTE_FLIP_MASK, XWORD3, XWORD3

	MOVQ $TSHF<>(SB), TBL

	JMP avx2_last_block_enter

avx2_only_one_block:
	// Load initial digest
	MOVL 0(CTX), a  // a = H0
	MOVL 4(CTX), b  // b = H1
	MOVL 8(CTX), c  // c = H2
	MOVL 12(CTX), d // d = H3
	MOVL 16(CTX), e // e = H4
	MOVL 20(CTX), f // f = H5
	MOVL 24(CTX), g // g = H6
	MOVL 28(CTX), h // h = H7

	JMP avx2_do_last_block

done_hash:
  VZEROUPPER
	RET

// shuffle byte order from LE to BE
DATA flip_mask<>+0x00(SB)/8, $0x0405060700010203
DATA flip_mask<>+0x08(SB)/8, $0x0c0d0e0f08090a0b
DATA flip_mask<>+0x10(SB)/8, $0x0405060700010203
DATA flip_mask<>+0x18(SB)/8, $0x0c0d0e0f08090a0b
GLOBL flip_mask<>(SB), 8, $32

// shuffle BxAx -> 00BA
DATA shuff_00BA<>+0x00(SB)/8, $0x0f0e0d0c07060504
DATA shuff_00BA<>+0x08(SB)/8, $0xFFFFFFFFFFFFFFFF
DATA shuff_00BA<>+0x10(SB)/8, $0x0f0e0d0c07060504
DATA shuff_00BA<>+0x18(SB)/8, $0xFFFFFFFFFFFFFFFF
GLOBL shuff_00BA<>(SB), 8, $32

//tshift for 2 blocks
DATA TSHF<>+0x0(SB)/4, $0x79cc4519
DATA TSHF<>+0x4(SB)/4, $0xf3988a32
DATA TSHF<>+0x8(SB)/4, $0xe7311465
DATA TSHF<>+0xc(SB)/4, $0xce6228cb
DATA TSHF<>+0x10(SB)/4, $0x79cc4519
DATA TSHF<>+0x14(SB)/4, $0xf3988a32
DATA TSHF<>+0x18(SB)/4, $0xe7311465
DATA TSHF<>+0x1c(SB)/4, $0xce6228cb

DATA TSHF<>+0x20(SB)/4, $0x9cc45197
DATA TSHF<>+0x24(SB)/4, $0x3988a32f
DATA TSHF<>+0x28(SB)/4, $0x7311465e
DATA TSHF<>+0x2c(SB)/4, $0xe6228cbc
DATA TSHF<>+0x30(SB)/4, $0x9cc45197
DATA TSHF<>+0x34(SB)/4, $0x3988a32f
DATA TSHF<>+0x38(SB)/4, $0x7311465e
DATA TSHF<>+0x3c(SB)/4, $0xe6228cbc

DATA TSHF<>+0x40(SB)/4, $0xcc451979
DATA TSHF<>+0x44(SB)/4, $0x988a32f3
DATA TSHF<>+0x48(SB)/4, $0x311465e7
DATA TSHF<>+0x4c(SB)/4, $0x6228cbce
DATA TSHF<>+0x50(SB)/4, $0xcc451979
DATA TSHF<>+0x54(SB)/4, $0x988a32f3
DATA TSHF<>+0x58(SB)/4, $0x311465e7
DATA TSHF<>+0x5c(SB)/4, $0x6228cbce

DATA TSHF<>+0x60(SB)/4, $0xc451979c
DATA TSHF<>+0x64(SB)/4, $0x88a32f39
DATA TSHF<>+0x68(SB)/4, $0x11465e73
DATA TSHF<>+0x6c(SB)/4, $0x228cbce6
DATA TSHF<>+0x70(SB)/4, $0xc451979c
DATA TSHF<>+0x74(SB)/4, $0x88a32f39
DATA TSHF<>+0x78(SB)/4, $0x11465e73
DATA TSHF<>+0x7c(SB)/4, $0x228cbce6

DATA TSHF<>+0x80(SB)/4, $0x9d8a7a87
DATA TSHF<>+0x84(SB)/4, $0x3b14f50f
DATA TSHF<>+0x88(SB)/4, $0x7629ea1e
DATA TSHF<>+0x8c(SB)/4, $0xec53d43c
DATA TSHF<>+0x90(SB)/4, $0x9d8a7a87
DATA TSHF<>+0x94(SB)/4, $0x3b14f50f
DATA TSHF<>+0x98(SB)/4, $0x7629ea1e
DATA TSHF<>+0x9c(SB)/4, $0xec53d43c

DATA TSHF<>+0xa0(SB)/4, $0xd8a7a879
DATA TSHF<>+0xa4(SB)/4, $0xb14f50f3
DATA TSHF<>+0xa8(SB)/4, $0x629ea1e7
DATA TSHF<>+0xac(SB)/4, $0xc53d43ce
DATA TSHF<>+0xb0(SB)/4, $0xd8a7a879
DATA TSHF<>+0xb4(SB)/4, $0xb14f50f3
DATA TSHF<>+0xb8(SB)/4, $0x629ea1e7
DATA TSHF<>+0xbc(SB)/4, $0xc53d43ce

DATA TSHF<>+0xc0(SB)/4, $0x8a7a879d
DATA TSHF<>+0xc4(SB)/4, $0x14f50f3b
DATA TSHF<>+0xc8(SB)/4, $0x29ea1e76
DATA TSHF<>+0xcc(SB)/4, $0x53d43cec
DATA TSHF<>+0xd0(SB)/4, $0x8a7a879d
DATA TSHF<>+0xd4(SB)/4, $0x14f50f3b
DATA TSHF<>+0xd8(SB)/4, $0x29ea1e76
DATA TSHF<>+0xdc(SB)/4, $0x53d43cec

DATA TSHF<>+0xe0(SB)/4, $0xa7a879d8
DATA TSHF<>+0xe4(SB)/4, $0x4f50f3b1
DATA TSHF<>+0xe8(SB)/4, $0x9ea1e762
DATA TSHF<>+0xec(SB)/4, $0x3d43cec5
DATA TSHF<>+0xf0(SB)/4, $0xa7a879d8
DATA TSHF<>+0xf4(SB)/4, $0x4f50f3b1
DATA TSHF<>+0xf8(SB)/4, $0x9ea1e762
DATA TSHF<>+0xfc(SB)/4, $0x3d43cec5

DATA TSHF<>+0x100(SB)/4, $0x7a879d8a
DATA TSHF<>+0x104(SB)/4, $0xf50f3b14
DATA TSHF<>+0x108(SB)/4, $0xea1e7629
DATA TSHF<>+0x10c(SB)/4, $0xd43cec53
DATA TSHF<>+0x110(SB)/4, $0x7a879d8a
DATA TSHF<>+0x114(SB)/4, $0xf50f3b14
DATA TSHF<>+0x118(SB)/4, $0xea1e7629
DATA TSHF<>+0x11c(SB)/4, $0xd43cec53

DATA TSHF<>+0x120(SB)/4, $0xa879d8a7
DATA TSHF<>+0x124(SB)/4, $0x50f3b14f
DATA TSHF<>+0x128(SB)/4, $0xa1e7629e
DATA TSHF<>+0x12c(SB)/4, $0x43cec53d
DATA TSHF<>+0x130(SB)/4, $0xa879d8a7
DATA TSHF<>+0x134(SB)/4, $0x50f3b14f
DATA TSHF<>+0x138(SB)/4, $0xa1e7629e
DATA TSHF<>+0x13c(SB)/4, $0x43cec53d

DATA TSHF<>+0x140(SB)/4, $0x879d8a7a
DATA TSHF<>+0x144(SB)/4, $0xf3b14f5
DATA TSHF<>+0x148(SB)/4, $0x1e7629ea
DATA TSHF<>+0x14c(SB)/4, $0x3cec53d4
DATA TSHF<>+0x150(SB)/4, $0x879d8a7a
DATA TSHF<>+0x154(SB)/4, $0xf3b14f5
DATA TSHF<>+0x158(SB)/4, $0x1e7629ea
DATA TSHF<>+0x15c(SB)/4, $0x3cec53d4

DATA TSHF<>+0x160(SB)/4, $0x79d8a7a8
DATA TSHF<>+0x164(SB)/4, $0xf3b14f50
DATA TSHF<>+0x168(SB)/4, $0xe7629ea1
DATA TSHF<>+0x16c(SB)/4, $0xcec53d43
DATA TSHF<>+0x170(SB)/4, $0x79d8a7a8
DATA TSHF<>+0x174(SB)/4, $0xf3b14f50
DATA TSHF<>+0x178(SB)/4, $0xe7629ea1
DATA TSHF<>+0x17c(SB)/4, $0xcec53d43

DATA TSHF<>+0x180(SB)/4, $0x9d8a7a87
DATA TSHF<>+0x184(SB)/4, $0x3b14f50f
DATA TSHF<>+0x188(SB)/4, $0x7629ea1e
DATA TSHF<>+0x18c(SB)/4, $0xec53d43c
DATA TSHF<>+0x190(SB)/4, $0x9d8a7a87
DATA TSHF<>+0x194(SB)/4, $0x3b14f50f
DATA TSHF<>+0x198(SB)/4, $0x7629ea1e
DATA TSHF<>+0x19c(SB)/4, $0xec53d43c

DATA TSHF<>+0x1a0(SB)/4, $0xd8a7a879
DATA TSHF<>+0x1a4(SB)/4, $0xb14f50f3
DATA TSHF<>+0x1a8(SB)/4, $0x629ea1e7
DATA TSHF<>+0x1ac(SB)/4, $0xc53d43ce
DATA TSHF<>+0x1b0(SB)/4, $0xd8a7a879
DATA TSHF<>+0x1b4(SB)/4, $0xb14f50f3
DATA TSHF<>+0x1b8(SB)/4, $0x629ea1e7
DATA TSHF<>+0x1bc(SB)/4, $0xc53d43ce

DATA TSHF<>+0x1c0(SB)/4, $0x8a7a879d
DATA TSHF<>+0x1c4(SB)/4, $0x14f50f3b
DATA TSHF<>+0x1c8(SB)/4, $0x29ea1e76
DATA TSHF<>+0x1cc(SB)/4, $0x53d43cec
DATA TSHF<>+0x1d0(SB)/4, $0x8a7a879d
DATA TSHF<>+0x1d4(SB)/4, $0x14f50f3b
DATA TSHF<>+0x1d8(SB)/4, $0x29ea1e76
DATA TSHF<>+0x1dc(SB)/4, $0x53d43cec

DATA TSHF<>+0x1e0(SB)/4, $0xa7a879d8
DATA TSHF<>+0x1e4(SB)/4, $0x4f50f3b1
DATA TSHF<>+0x1e8(SB)/4, $0x9ea1e762
DATA TSHF<>+0x1ec(SB)/4, $0x3d43cec5
DATA TSHF<>+0x1f0(SB)/4, $0xa7a879d8
DATA TSHF<>+0x1f4(SB)/4, $0x4f50f3b1
DATA TSHF<>+0x1f8(SB)/4, $0x9ea1e762
DATA TSHF<>+0x1fc(SB)/4, $0x3d43cec5
GLOBL TSHF<>(SB), (NOPTR + RODATA), $512
