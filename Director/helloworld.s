main:
	X 0
	Y 0
loop:
	RXA message
	TAX
	INCX
	BZ end
	B loop
	
end:
	HLT

message:
.byte "HELLO WORLD"
.byte 0

	