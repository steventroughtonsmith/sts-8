
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

	; Y++ when X == screen width
	PUSH
	TXA
	SUB 40
	BZ cr
	ADD 40
	POP

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
	LD bootmsg
	JMP print

	JMP newline

	LD email
	JMP print

	JMP newline
	
	B cr
	HLT

print:
	ST print_storage
print_loop:
	LDA print_storage
	RA
	BZ print_end
	TAX
	INCX
	; print_storage++
	LDA print_storage
	ADD 1
	ST print_storage
	B print_loop
print_end:
	LD 0
	ST print_storage
	RET

newline:
	INCY
	X 0
	RET

bootmsg:
	.byte "STS-OS 001: LOADED"
	.byte 0

email:
	.byte "sts-8"
	.byte 0

print_storage:
	.byte 0