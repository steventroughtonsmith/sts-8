X 0
Y 0

loop:
INCX
LDA $X ; x
PUSH
INCY
LDA $Y ; y
PUSH
JMP drawPixel
B loop
HLT

; void drawPixel(x, y)
drawPixel:
; pop return address then args
POP
ST RtnAdrs
POP
ST $Y
POP
ST $X
LD 219
TAX
LDA RtnAdrs
PUSH
RET

; void drawLine(x1, y1, x2, y2)

RtnAdrs:
.var 0
