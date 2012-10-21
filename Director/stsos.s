
init:
	X 0
	Y 0
	JMP init_do

main:
	
	LDA _keyboard ; check key input
	; check for return key 13
	SUB 13
	BZ cr
	ADD 13

	; backspace 127
	SUB 127
	BZ bksp
	ADD 127

	BZ main
	BN main
	TAX
	INCX
	LD 219
	TAX
	B main
	HLT

cr:
	LD 0
	TAX
	INCY
	X 0
	LD 219 ; cursor bar
	TAX
	B main

bksp:
	PUSH
	TXA
	SUB 1
	BN main
	ADD 1
	POP
	; move the cursor
	LD 0
	TAX
	DECX
	LD 219 ; cursor bar
	TAX
	B main

init_do:
	RXA bootmsg
	TAX
	INCX
	BZ cr
	B init_do
	HLT

bootmsg:
	.byte "STS OS 001 LOADED"
	.var 0