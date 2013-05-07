
main:
	X 0
	LD 65 ; start at 'A'
	JMP printUppercase
	X 0
	Y 1
	LD 97 ; start at 'a'
	JMP printLowercase
	HLT

printUppercase:
	TAX

; if (lastchar-'Z' >= 0)
if_1: 
	ST lastchar
	SUB 90 ; 'Z'
	BZ else_1
	LDA lastchar ; restore char
	ADD 1
	INCX
	B printUppercase

else_1:
	RET
	
printLowercase:
	TAX

; if (lastchar-'z' >= 0)
if_2: 
	ST lastchar_2
	SUB 122 ; 'z'
	BZ else_2
	LDA lastchar_2 ; restore char
	ADD 1
	INCX
	B printLowercase

else_2:
	RET	

lastchar:
	.var 0
	
lastchar_2:
	.var 0
