main:
	X 20
	Y 20
	JMP init
	JMP loop

init:
	JMP initsnake
	JMP initapple
	RET

loop:
	JMP readKeys

initsnake:
	LD 16
	ST direction
	LD 4
	ST length
	LDA sy
	ST sx
	LDA sx
	ST body
	RET

initapple:
	RET

readKeys:
	LDA _keyboard ; check key input
	SUB 100
	BZ keyRight
	ADD 100
	SUB 115
	BZ keyDown
	ADD 115
	SUB 97
	BZ keyLeft
	ADD 97
	SUB 119
	BZ keyUp
	ADD 119

keyRight:
	LD 8
	ST direction
	B endKeys

keyLeft:
	LD 16
	ST direction
	B endKeys

keyUp:
	LD 2
	ST direction
	B endKeys

keyDown:
	LD 4
	ST direction
	B endKeys

endKeys:
	JMP updateSnake

updateSnake:
	LDA direction

	SUB 16
	BZ goleft
	ADD 16

	SUB 8
	BZ goright
	ADD 8

	SUB 4
	BZ godown
	ADD 4

	SUB 2
	BZ goup
	ADD 2

	B continueSnake

goleft:
	TXA
	BZ continueSnake
	DECX
	LD 16
	ST direction
	B continueSnake

goright:
	TXA
	SUB 39
	BZ continueSnake
	ADD 39
	INCX
	LD 8
	ST direction
	B continueSnake

godown:
	INCY
	LD 4
	ST direction
	B continueSnake

goup:
	DECY
	LD 2
	ST direction
	B continueSnake

continueSnake:
	JMP drawSnake
	JMP loop

drawSnake:
	LD 219
	TAX
	RET


;(1 => up, 2 => right, 4 => down, 8 => left)
direction:
	.var 0

length:
	.var 0

ax:
	.var 0

ay:
	.var 0

sx:
	.var 0

sy:
	.var 0

body:
	.var 0