
;COLOR_BLACK = 0,
;COLOR_BLUE = 1,
;COLOR_GREEN = 2,
;COLOR_LIGHTBLUE = 4,
;COLOR_RED = 8,
;COLOR_PINK = 16,
;COLOR_YELLOW = 32,
;COLOR_WHITE = 64


X 0
Y 0
LDA $VMODE_FB
TAX

loop:
INCX
LDA $X ; x
PUSH
INCY
LDA $Y ; y
PUSH
JMP drawPixel
B loop

end:
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
LD 2 ; color
TAX
LDA RtnAdrs
PUSH
RET

; void drawLine(x1, y1, x2, y2)

RtnAdrs:
.var 0
