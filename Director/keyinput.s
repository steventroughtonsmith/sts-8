
main:
	LDA _keyboard ; check key input
	; check for return key
	SUB 13
	BZ cr
	ADD 13

	; backspace
	SUB 127
	BZ bksp
	ADD 127

	BZ main
	BN main
	TAX
	INCX
	B main

cr:
	INCY
	X 0
	B main

bksp:

	PUSH
	TXA
	BZ main
	POP
	DECX
	LD 0
	TAX
	B main