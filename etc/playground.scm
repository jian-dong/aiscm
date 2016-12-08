(use-modules (oop goops)
             (srfi srfi-1)
             (srfi srfi-26)
             (system foreign)
             (aiscm element)
             (aiscm int)
             (aiscm sequence)
             (aiscm mem)
             (aiscm pointer)
             (aiscm rgb)
             (aiscm obj)
             (aiscm asm)
             (aiscm jit)
             (aiscm method)
             (aiscm util)
             (guile-tap))

(define default-registers (list RAX RCX RDX RSI RDI R10 R11 R9 R8 RBX R12 R13 R14 R15))

(define (set-spill-locations allocation offset increment)
  "Allocate spill locations for spilled variables"
  (if (null? allocation)
      allocation
      (let* [(candidate (car allocation))
             (variable  (car candidate))
             (register  (cdr candidate))]
        (cons (if register candidate (cons variable (ptr <int> RSP offset)))
              (set-spill-locations (cdr allocation) (+ offset (if register 0 increment)) increment)))))

(define (linear-scan-coloring live-intervals registers predefined)
  "Linear scan register allocation based on live intervals"
  (define (linear-allocate live-intervals register-use variable-use result)
   (if (null? live-intervals)
        result
        (let* [(candidate    (car live-intervals))
               (variable     (car candidate))
               (interval     (cdr candidate))
               (first-index  (car interval))
               (last-index   (cdr interval))
               (variable-use (mark-used-till variable-use variable last-index))
               (register     (or (assq-ref predefined variable)
                                 (find-available register-use first-index)))
               (recursion    (lambda (result register)
                               (linear-allocate (cdr live-intervals)
                                                (mark-used-till register-use register last-index)
                                                variable-use
                                                (assq-set result variable register))))]
          (if register
            (recursion result register)
            (let* [(spill-candidate (longest-use variable-use))
                   (register        (assq-ref result spill-candidate))]
              (recursion (assq-set result spill-candidate #f) register))))))
  (linear-allocate (sort-live-intervals live-intervals (map car predefined))
                   (initial-register-use registers)
                   '()
                   '()))

(define* (linear-scan-allocate prog #:key (registers default-registers)
                                          (predefined '()))
  "Linear scan register allocation for a given program"
  (let* [(live         (live-analysis prog '())); TODO: specify return values here
         (all-vars     (variables prog))
         (intervals    (live-intervals live all-vars))
         (substitution (linear-scan-coloring intervals registers predefined))]
    (adjust-stack-pointer 8 (substitute-variables prog substitution))))

(let [(a (var <int>))
      (b (var <int>))
      (c (var <int>))]
  (ok (equal? (list (SUB RSP 8) (MOV EAX 42) (ADD RSP 8) (RET))
              (linear-scan-allocate (list (MOV a 42) (RET))))
      "Allocate a single register")
  (ok (equal? (list (SUB RSP 8) (MOV ECX 42) (ADD RSP 8) (RET))
              (linear-scan-allocate (list (MOV a 42) (RET)) #:registers (list RCX RDX)))
      "Allocate a single register using custom list of registers")
  (ok (equal? (list (SUB RSP 8) (MOV EAX 1) (MOV ECX 2) (ADD EAX ECX) (MOV ECX EAX) (ADD RSP 8) (RET))
              (linear-scan-allocate (list (MOV a 1) (MOV b 2) (ADD a b) (MOV c a) (RET))))
      "Allocate multiple registers")
  (ok (equal? (list (SUB RSP 8) (MOV ECX 1) (ADD ECX ESI) (MOV EAX ECX) (ADD RSP 8) (RET))
              (linear-scan-allocate (list (MOV b 1) (ADD b a) (MOV c b) (RET))
                                 #:predefined (list (cons a RSI) (cons c RAX))))
      "Register allocation with predefined registers")
  (ok (equal? '() (set-spill-locations '() 16 8))
      "do nothing if there are no variables")
  (ok (equal? (list (cons a RAX)) (set-spill-locations (list (cons a RAX)) 16 8))
      "ignore variables with allocated register when spilling")
  (ok (equal? (list (cons a RAX) (cons b RCX)) (set-spill-locations (list (cons a RAX) (cons b RCX)) 16 8))
      "ignore two variables with allocated register when spilling")
  (ok (equal? (list (cons a (ptr <int> RSP 16))) (set-spill-locations (list (cons a #f)) 16 8))
      "allocate spill location for a variable")
  (ok (equal? (list (cons a (ptr <int> RSP 16)) (cons b (ptr <int> RSP 24)))
              (set-spill-locations (list (cons a #f) (cons b #f)) 16 8))
      "allocate spill location for two variables")
  (ok (equal? (list (cons a RAX) (cons b (ptr <int> RSP 16)))
              (set-spill-locations (list (cons a RAX) (cons b #f)) 16 8))
      "allocate spill location for second variable"))

(run-tests)
