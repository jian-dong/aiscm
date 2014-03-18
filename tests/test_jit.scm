(use-modules (oop goops)
             (system foreign)
             (rnrs bytevectors)
             (srfi srfi-26)
             (aiscm jit)
             (aiscm element)
             (aiscm mem)
             (aiscm int)
             (aiscm pointer)
             (guile-tap))
(planned-tests 104)
(define w1 (random (ash 1 14)))
(define w2 (random (ash 1 14)))
(define i1 (random (ash 1 30)))
(define i2 (random (ash 1 30)))
(define l1 (random (ash 1 62)))
(define l2 (random (ash 1 62)))
(define ctx (make <jit-context>))
(define mem1 (make <mem> #:size 16))
(define mem2 (make <mem> #:size 32))
(define iptr (make (pointer <int>) #:value mem1))
(define lptr (make (pointer <long>) #:value mem2))
(store iptr (make <int> #:value i1))
(store (+ iptr 1) (make <int> #:value i2))
(ok (equal? '(#xb8 #x2a #x00 #x00 #x00) (MOV EAX 42))
    "MOV EAX, 42")
(ok (equal? '(#xb9 #x2a #x00 #x00 #x00) (MOV ECX 42))
    "MOV ECX, 42")
(ok (equal? '(#x41 #xb9 #x2a #x00 #x00 #x00) (MOV R9D 42))
    "MOV R9D, 42")
(ok (equal? '(#x48 #xbe #x2a #x00 #x00 #x00 #x00 #x00 #x00 #x00)
            (MOV RSI 42))
    "MOV RSI, 42")
(ok (equal? '(#x49 #xb9 #x2a #x00 #x00 #x00 #x00 #x00 #x00 #x00)
            (MOV R9 42))
    "MOV R9, 42")
(ok (equal? '(#x89 #xc3) (MOV EBX EAX))
    "MOV EBX, EAX")
(ok (equal? '(#x89 #xd1) (MOV ECX EDX))
    "MOV ECX, EDX")
(ok (equal? '(#x45 #x89 #xc8) (MOV R8D R9D))
    "MOV R8D, R9D")
(ok (equal? '(#x8b #x0a) (MOV ECX *RDX))
    "MOV ECX, *RDX")
(ok (equal? '(#x41 #x8b #x0b) (MOV ECX *R11))
    "MOV ECX, *R11")
(ok (equal? '(#x8b #x4a #x04) (MOV ECX *RDX 4))
    "MOV ECX, *RDX, 4")
(ok (equal? '(#x8b #x4c #x24 #x04) (MOV ECX *RSP 4))
    "MOV ECX, *RSP, 4")
(ok (equal? '(#x45 #x8b #x53 #x04) (MOV R10D *R11 4))
    "MOV R10D, *R11, 4")
(ok (equal? '(#x89 #x11) (MOV *RCX EDX))
    "MOV *RCX, EDX")
(ok (equal? '(#x44 #x89 #x01) (MOV *RCX R8D))
    "MOV *RCX R8D")
(ok (equal? '(#xc3) (RET))
    "RET # near return")
(ok (begin ((asm ctx void (list (RET)))) #t)
    "Empty function")
(ok (eqv? i1 ((asm ctx int (list (MOV EAX i1) (RET)))))
    "Return constant in EAX")
(ok (eqv? l1 ((asm ctx long (list (MOV RAX l1) (RET)))))
    "Return constant in RAX")
(ok (eqv? i1 ((asm ctx int (list (MOV ECX i1) (MOV EAX ECX) (RET)))))
    "Function copying content from ECX")
(ok (eqv? i1 ((asm ctx int (list (MOV R14D i1) (MOV EAX R14D) (RET)))))
    "Function copying content from R14D")
(ok (eqv? (ash 42 32) ((asm ctx long
                            (list (MOV R14 (ash 42 32))
                                  (MOV RAX R14)
                                  (RET)))))
    "Function copying content from R14")
(ok (equal? '(#xd1 #xe5) (SHL EBP))
    "SHL EBP, 1")
(ok (equal? '(#xd1 #xe5) (SAL EBP))
    "SAL EBP, 1")
(ok (eqv? (ash i1 1) ((asm ctx int (list (MOV EAX i1) (SHL EAX) (RET)))))
    "Shift EAX left by 1")
(ok (eqv? (ash i1 1) ((asm ctx int (list (MOV R9D i1)
                                         (SHL R9D)
                                         (MOV EAX R9D)
                                         (RET)))))
    "Shift R9D left by 1")
(ok (eqv? (ash l1 1) ((asm ctx long (list (MOV RAX l1) (SHL RAX) (RET)))))
    "Function shifting 64-bit number left by 1")
(ok (equal? '(#x48 #xd1 #xe5) (SHL RBP))
    "SHL RBP, 1")
(ok (equal? '(#x48 #xd1 #xe5) (SAL RBP))
    "SAL RBP, 1")
(ok (equal? '(#xd1 #xed) (SHR EBP))
    "SHR EBP, 1")
(ok (equal? '(#xd1 #xfd) (SAR EBP))
    "SAR EBP, 1")
(ok (eqv? (ash i1 -1) ((asm ctx int (list (MOV EAX i1) (SHR EAX) (RET)))))
    "Function shifting right by 1")
(ok (eqv? -21 ((asm ctx int (list (MOV EAX -42) (SAR EAX) (RET)))))
    "Function shifting negative number right by 1")
(ok (equal? '(#x48 #xd1 #xed) (SHR RBP))
    "SHR RBP, 1")
(ok (equal? '(#x48 #xd1 #xfd) (SAR RBP))
    "SAR RBP, 1")
(ok (eqv? (ash l1 -1) ((asm ctx long (list (MOV RAX l1) (SHR RAX) (RET)))))
    "Function shifting 64-bit number right by 1")
(ok (eqv? (ash -1 30) ((asm ctx long
                            (list (MOV RAX (ash -1 32))
                                  (SAR RAX)
                                  (SAR RAX)
                                  (RET)))))
    "Function shifting signed 64-bit number right by 2")
(ok (equal? '(#x05 #x0d #x00 #x00 #x00) (ADD EAX 13))
    "ADD EAX, 13")
(ok (equal? '(#x48 #x05 #x0d #x00 #x00 #x00) (ADD RAX 13))
    "ADD RAX, 13")
(ok (equal? '(#x41 #x81 #xc2 #x0d #x00 #x00 #x00) (ADD R10D 13))
    "ADD R10D, 13")
(ok (equal? '(#x49 #x81 #xc2 #x0d #x00 #x00 #x00) (ADD R10 13))
    "ADD R10, 13")
(ok (equal? '(#x01 #xd1) (ADD ECX EDX))
    "ADD ECX, EDX")
(ok (equal? '(#x45 #x01 #xfe) (ADD R14D R15D))
    "ADD R14D, R15D")
(ok (equal? '(#x2d #x0d #x00 #x00 #x00) (SUB EAX 13))
    "SUB EAX, 13")
(ok (equal? '(#x48 #x2d #x0d #x00 #x00 #x00) (SUB RAX 13))
    "SUB RAX, 13")
(ok (equal? '(#x41 #x81 #xea #x0d #x00 #x00 #x00) (SUB R10D 13))
    "SUB R10D, 13")
(ok (equal? '(#x49 #x81 #xea #x0d #x00 #x00 #x00) (SUB R10 13))
    "SUB R10, 13")
(ok (equal? '(#x29 #xd1) (SUB ECX EDX))
    "SUB ECX, EDX")
(ok (equal? '(#x45 #x29 #xfe) (SUB R14D R15D))
    "SUB R14D, R15D")
(ok (eqv? 55 ((asm ctx int (list (MOV EAX 42) (ADD EAX 13) (RET)))))
    "Function using EAX to add 42 and 13")
(ok (eqv? 55 ((asm ctx long (list (MOV RAX 42) (ADD RAX 13) (RET)))))
    "Function using RAX to add 42 and 13")
(ok (eqv? (+ i1 i2) ((asm ctx int
                          (list (MOV EAX i1)
                                (ADD EAX i2)
                                (RET)))))
    "Function adding two integers in EAX")
(ok (eqv? (+ i1 i2) ((asm ctx int
                          (list (MOV EDX i1)
                                (ADD EDX i2)
                                (MOV EAX EDX)
                                (RET)))))
    "Function adding two integers in EDX")
(ok (eqv? (+ i1 i2) ((asm ctx int
                          (list (MOV R10D i1)
                                (ADD R10D i2)
                                (MOV EAX R10D)
                                (RET)))))
    "Function adding two integers in R10D")
(ok (eqv? (+ i1 i2) ((asm ctx int
                          (list (MOV EAX i1)
                                (MOV ECX i2)
                                (ADD EAX ECX)
                                (RET)))))
    "Function using EAX and ECX to add two integers")
(ok (eqv? (+ i1 i2) ((asm ctx int
                          (list (MOV R14D i1)
                                (MOV R15D i2)
                                (ADD R14D R15D)
                                (MOV EAX R14D)
                                (RET)))))
    "Function using R14D and R15D to add two integers")
(ok (equal? '(#x90) (NOP))
    "NOP # no operation")
(ok (eqv? i1 ((asm ctx int (list (MOV EAX i1) (NOP) (NOP) (RET)))))
    "Function with some NOP statements inside")
(ok (equal? '(#x52) (PUSH RDX))
    "PUSH RDX")
(ok (equal? '(#x57) (PUSH RDI))
    "PUSH RDI")
(ok (equal? '(#x5a) (POP RDX))
    "POP RDX")
(ok (equal? '(#x5f) (POP RDI))
    "POP RDI")
(ok (eqv? l1 ((asm ctx long (list (MOV RDX l1) (PUSH RDX) (POP RAX) (RET)))))
    "Function using PUSH and POP")
(ok (eqv? i1 ((asm ctx int (list (MOV RCX mem1) (MOV EAX *RCX) (RET)))))
    "Function loading integer from address in RCX")
(ok (eqv? i1 ((asm ctx int (list (MOV R10 mem1) (MOV EAX *R10) (RET)))))
    "Function loading integer from address in R10")
(ok (eqv? i1 ((asm ctx int (list (MOV RCX mem1) (MOV EAX *RCX) (RET)))))
    "Function loading value from address given as pointer")
(ok (eqv? i2 ((asm ctx int (list (MOV RCX mem1) (MOV EAX *RCX 4) (RET)))))
    "Load value from address in RCX with offset")
(ok (eqv? i2 ((asm ctx int (list (MOV R9 mem1) (MOV EAX *R9 4) (RET)))))
    "Load value from address in R9D with offset")
(ok (eqv? i1 (begin ((asm ctx void
                          (list (MOV RSI (+ mem1 8))
                                (MOV ECX i1)
                                (MOV *RSI ECX)
                                (RET))))
                    (get-value (fetch (+ iptr 2)))))
    "Function writing value of ECX to memory")
(ok (eqv? l1 (begin ((asm ctx void
                          (list (MOV RSI mem2)
                                (MOV RCX l1)
                                (MOV *RSI RCX)
                                (RET))))
                    (get-value (fetch lptr))))
    "Function writing value of RCX to memory")
(ok (eqv? i1 (begin ((asm ctx int
                          (list (MOV RSI (+ mem1 12))
                                (MOV R8D i1)
                                (MOV *RSI R8D)
                                (RET))))
                    (get-value (fetch (+ iptr 3)))))
    "Function writing value of R8D to memory")
(ok (eqv? 2 ((asm ctx int (list (MOV EAX EDI) (RET))
                  int int int int) 2 3 5 7))
    "Function return first integer argument")
(ok (eqv? 3 ((asm ctx int (list (MOV EAX ESI) (RET))
                  int int int int) 2 3 5 7))
    "Function return second integer argument")
(ok (eqv? 5 ((asm ctx int (list (MOV EAX EDX) (RET))
                  int int int int) 2 3 5 7))
    "Function return third integer argument")
(ok (eqv? 7 ((asm ctx int (list (MOV EAX ECX) (RET))
                  int int int int) 2 3 5 7))
    "Function return fourth integer argument")
(ok (eqv? 11 ((asm ctx int (list (MOV EAX R8D) (RET))
                   int int int int int int) 2 3 5 7 11 13))
    "Function return fifth integer argument")
(ok (eqv? 13 ((asm ctx int (list (MOV EAX R9D) (RET))
                   int int int int int int) 2 3 5 7 11 13))
    "Function return sixth integer argument")
(ok (eqv? 17 ((asm ctx int (list (MOV EAX *RSP #x8) (RET))
                   int int int int int int int int) 2 3 5 7 11 13 17 19))
    "Function return seventh integer argument")
(ok (eqv? 19 ((asm ctx int (list (MOV EAX *RSP #x10) (RET))
                   int int int int int int int int) 2 3 5 7 11 13 17 19))
    "Function return eighth integer argument")
(ok (equal? '(#xf7 #xdb) (NEG EBX))
    "NEG EBX")
(ok (eqv? (- i1) ((asm ctx int (list (MOV EAX EDI) (NEG EAX) (RET)) int) i1))
    "Function negating an integer")
(ok (eqv? (- l1) ((asm ctx long (list (MOV RAX RDI) (NEG RAX) (RET)) long) l1))
    "Function negating a long integer")
(ok (eqv? (- i1 i2) ((asm ctx int
                          (list (MOV EAX i1)
                                (SUB EAX i2)
                                (RET)))))
    "Function subtracting two integers in EAX")
(ok (eqv? (- i1 i2) ((asm ctx int
                          (list (MOV EDX i1)
                                (SUB EDX i2)
                                (MOV EAX EDX)
                                (RET)))))
    "Function subtracting two integers in EDX")
(ok (eqv? (- i1 i2) ((asm ctx int
                          (list (MOV R10D i1)
                                (SUB R10D i2)
                                (MOV EAX R10D)
                                (RET)))))
    "Function subtracting two integers in R10D")
(ok (eqv? (- i1 i2) ((asm ctx int
                          (list (MOV EAX i1)
                                (MOV ECX i2)
                                (SUB EAX ECX)
                                (RET)))))
    "Function using EAX and ECX to subtract two integers")
(ok (eqv? (- i1 i2) ((asm ctx int
                          (list (MOV R14D i1)
                                (MOV R15D i2)
                                (SUB R14D R15D)
                                (MOV EAX R14D)
                                (RET)))))
    "Function using R14D and R15D to subtract two integers")
(ok (not (throws? (asm ctx int (list (MOV EAX i1) 'tst (RET)))))
    "Assembler should tolerate labels")
(ok (eqv? 0 (assq-ref (label-offsets (list 'tst)) 'tst))
    "Sole label maps to zero")
(ok (eqv? 0 (assq-ref (label-offsets (list 'tst (NOP))) 'tst))
    "Label at beginning of code is zero")
(ok (eqv? (length (MOV EAX ESI))
          (assq-ref (label-offsets (list (MOV EAX ESI) 'tst)) 'tst))
    "Label after MOV EAX ESI statement maps to length of that statement")
(ok (equal? '(1 2) (let ((a (label-offsets (list (NOP) 'x (NOP) 'y))))
                     (map (cut assq-ref a <>) '(x y))))
    "Map multiple labels")
(ok (equal? '(#xeb #x2a) (JMP 42))
    "JMP 42")
(ok (eq? 'tst (get-target (JMP 'tst)))
    "Target of JMP to label")
(ok (eqv? 2 (len (JMP 'tst)))
    "Length of JMP")
(ok (eqv? 2 (assq-ref (label-offsets (list (JMP 'tst) 'tst)) 'tst))
    "Label after JMP statement maps to 2")
(ok (equal? (JMP 5) (resolve (JMP 'tst) 0 '((tst . 5))))
    "Resolve jump address with zero offset")
(ok (equal? (JMP 3) (resolve (JMP 'tst) 2 '((tst . 5))))
    "Resolve jump address with offset 2")
(ok (equal? (list (JMP 5)) (resolve-jumps (list (JMP 'tst)) '((tst . 7))))
    "Resolve jump address in trivial program")
(ok (equal? (list (JMP 5) (NOP)) (resolve-jumps (list (JMP 'tst) (NOP)) '((tst . 7))))
    "Resolve jump address in program with trailing NOP")
(ok (equal? (list (NOP) (JMP 4)) (resolve-jumps (list (NOP) (JMP 'tst)) '((tst . 7))))
    "Resolve jump address in program with leading NOP")
(ok (equal? (list (NOP) (NOP)) (resolve-jumps (list (NOP) 'tst (NOP)) '()))
    "Remove label information from program")
(ok (eqv? i1 ((asm ctx int
                   (list (MOV ECX i1)
                         (JMP 'tst)
                         (MOV ECX 0)
                         'tst
                         (MOV EAX ECX)
                         (RET)))))
    "Function with a local jump")
(ok (eqv? i1 ((asm ctx int
                   (list (MOV EAX 0)
                         (JMP 'b)
                         'a
                         (MOV EAX i1)
                         (JMP 'c)
                         'b
                         (MOV EAX i2)
                         (JMP 'a)
                         'c
                         (RET)))))
    "Function with several local jumps")
(format #t "~&")
