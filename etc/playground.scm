(use-modules (oop goops)
             (srfi srfi-1)
             (srfi srfi-26)
             (srfi srfi-64)
             (system foreign)
             (aiscm element)
             (aiscm int)
             (aiscm sequence)
             (aiscm mem)
             (aiscm pointer)
             (aiscm rgb)
             (aiscm complex)
             (aiscm obj)
             (aiscm asm)
             (aiscm jit)
             (aiscm method)
             (aiscm util))

(define-syntax-rule (d expr) (format #t "~a = ~a~&" (quote expr) expr))

(test-begin "tensors")

(define ctx (make <context>))


(define s (parameter (sequence <ubyte>)))
(define t (parameter (sequence <ubyte>)))
(define m (parameter (multiarray <ubyte> 2)))
(define f (+ s t))
(define g (tensor (dimension s) k (+ (get s k) (get t k))))

(define-method (typecode (self <lookup>)) (typecode (type self)))

(define-method (lookups (self <indexer>)) (lookups self (index self)))
(define-method (lookups (self <indexer>) (idx <var>)) (lookups (delegate self) idx))
(define-method (lookups (self <lookup>) (idx <var>)) (if (eq? (index self) idx) (list self) (lookups (delegate self) idx)))
(define-method (lookups (self <function>)) (append-map lookups (arguments self)))
(define-method (lookups (self <function>) (idx <var>)) (append-map (cut lookups <> idx) (arguments self)))

(define-method (project (self <param>) (idx <var>)) self)
(define-method (project (self <indexer>) (idx <var>))
  (if (eq? (index self) idx)
      (project (delegate self) idx)
      (indexer (dimension self) (index self) (project (delegate self) idx))))
(define-method (project (self <lookup>) (idx <var>))
  (if (eq? (index self) idx)
      (delegate self)
      (lookup (index self) (project (delegate self) idx) (stride self) (iterator self) (step self))))

(define-method (rebase value (self <indexer>))
  (indexer (dimension self) (index self) (rebase value (delegate self))))
(define-method (rebase value (self <lookup>))
  (lookup (index self) (rebase value (delegate self)) (stride self) (iterator self) (step self)))
(define-method (rebase value (self <lookup>))
  (rebase value (delegate self)))

(define-method (setup (self <lookup>))
  (list (IMUL (step self) (get (delegate (stride self))) (size-of (typecode self)))
        (MOV (iterator self) (value self))))

(define-method (increment (self <lookup>))
  (list (ADD (iterator self) (step self))))

(let* [(s (parameter (sequence <ubyte>)))
       (u (parameter (sequence <ubyte>)))
       (m (parameter (multiarray <ubyte> 2)))
       (v (var <long>))
       (i (var <long>))]
  (test-equal "get lookup object of sequence"
    (list (delegate s)) (lookups s))
  (test-equal "get first lookup object of 2D array"
    (list (delegate (delegate m))) (lookups m))
  (test-equal "get second lookup object of 2D array"
    (list (delegate (delegate (delegate m)))) (lookups (delegate m)))
  (test-equal "get lookup objects of binary plus"
    (list (delegate s) (delegate u)) (lookups (+ s u)))
  (test-equal "get lookup based on same object when using tensor"
    (list (delegate (delegate s))) (map delegate (lookups (tensor (dimension s) k (get s k)))))
  (test-equal "get lookup using replaced variable"
    (list i) (map index (lookups (indexer (dimension s) i (get s i)))))
  (test-equal "get lookup based on same objects when using binary tensor"
    (list (delegate (delegate s)) (delegate (delegate u)))
    (map delegate (lookups (indexer (dimension s) i (+ (get s i) (get u i))))))
  (test-equal "get lookup using replaced variable"
    (list i i) (map index (lookups (indexer (dimension s) i (+ (get s i) (get u i))))))
  (test-eq "typecode of lookup object"
    <ubyte> (typecode (delegate s)))
  (test-equal "set up an iterator"
    (list (IMUL (step s) (get (delegate (stride s))) (size-of (typecode s))) (MOV (iterator s) (value s)))
    (setup (delegate s)))
  (test-equal "advance an iterator"
    (list (ADD (iterator s) (step s))) (increment (delegate s)))
  (test-eq "rebase a pointer"
    v (value (rebase v (make (pointer <byte>) #:value (var <long>)))))
  (test-eq "rebase parameter wrapping a pointer"
    v (value (rebase v (parameter (make (pointer <byte>) #:value (var <long>))))))
  (test-eq "rebase a sequence object"
    v (value (rebase v s)))
  (test-equal "rebase maintains sequence shape"
    (shape s) (shape (rebase v s)))
  (test-assert "projecting a sequence should drop a dimension"; specified by the index
    (null? (shape (project (indexer (dimension s) i (get s i)) i))))
  (test-equal "do not drop a dimension if the specified index is a different one"
    (shape s) (shape (project s i)))
  (test-equal "should drop the last dimension of a two-dimensional array"
    (take (shape m) 1) (shape (project m (index m))))
  (test-equal "should drop the last dimension of a two-dimensional array"
    (cdr (shape m)) (shape (project m (index (delegate m))))))

; unify indices when adding two sequences?
; TODO: body/project, rebase, for tensor expressions

; (jit ctx (list (sequence <ubyte>) (sequence <ubyte>)) (lambda (s u) (tensor (dimension s) k (+ (get s k) (get u k)))))

(test-end "tensors")
