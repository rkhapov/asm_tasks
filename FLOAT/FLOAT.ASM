.model tiny
.code
.486

org 100h

; if x < -2 then y = x + 5
; if -2 < x < 2 then y = x^2 + 2x
; if x > 2 then y = sqrt(x) + 6.5

locals @@

start:
	jmp @@actual_start

	x 		dq 16.0
	left	dq -2.0
	right   dq 2.0
	five    dq 5.0
	six     dq 6.5
	two     dq 2.0
	y       dq ?

@@actual_start:
	finit
	fld x
	fld left
	fcomp
	fstsw ax
	sahf
	ja @@less

	fld right
	fcomp
	fstsw ax
	sahf
	jb @@greater

@@middle:
	fld two
	fmul
	fld x
	fld x
	fmul
	fadd
	fst y
	jmp @@end

@@greater:
	fsqrt
	fld six
	fadd
	fst y
	jmp @@end

@@less:
	fld five
	fadd
	fst y

@@end:
	fld y

	ret
end start
