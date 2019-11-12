.model tiny
.code

org 100h

locals @@

start:
	jmp call_main

	x 		dq -2.0
	left	dq -3.0
	right   dq 2.0
	y       dq ?

call_main:
	fld qword ptr [x]
	fld qword ptr [left]
	fadd

	ret
end start
