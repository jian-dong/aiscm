(define-module (aiscm op)
  #:use-module (oop goops)
  #:use-module (srfi srfi-1)
  #:use-module (aiscm util)
  #:use-module (aiscm jit)
  #:use-module (aiscm mem)
  #:use-module (aiscm element)
  #:use-module (aiscm pointer)
  #:use-module (aiscm int)
  #:use-module (aiscm sequence)
  #:export (fill)
  #:re-export (+ -))
(define ctx (make <jit-context>))

(define-method (+ (a <element>)) a)
(define-method (+ (a <element>) (b <element>))
  (let* [(ca (class-of a))
         (cb (class-of b))
         (cr (coerce ca cb))
         (m  (jit-wrap ctx cr (ca cb)
                       (lambda (fun r_ a_ b_)
                         (env fun
                              [(r (reg (get-value r_) fun))
                               (a (reg (get-value a_) fun))
                               (b (reg (get-value b_) fun))
                               (w (reg cr fun))]
                              ((if (eqv? (size-of ca) (size-of cr))
                                 MOV
                                 (if (signed? ca) MOVSX MOVZX)) r a)
                              (if (eqv? (size-of cb) (size-of cr))
                                (ADD r b)
                                (append
                                  ((if (signed? cb) MOVSX MOVZX) w b)
                                  (ADD r w)))))))]
    (add-method! + m)
    (+ a b)))
(define-method (+ (a <element>) (b <integer>))
  (+ a (make (match b) #:value b)))
(define-method (+ (a <integer>) (b <element>))
  (+ (make (match a) #:value a) b))
(define-method (+ (a <sequence<>>) (b <element>))
  (let* [(ca (class-of a))
         (cb (class-of b))
         (cr (coerce ca cb))
         (ta (typecode ca))
         (tr (typecode cr))
         (m  (jit-wrap ctx cr (ca cb)
                       (lambda (fun r_ a_ b_)
                         (env fun
                              [(*r  (reg (get-value r_) fun))
                               (r+  (reg (last (strides r_)) fun))
                               (n   (reg (last (shape r_)) fun))
                               (*a  (reg (get-value a_) fun))
                               (a+  (reg (last (strides a_)) fun))
                               (b   (reg (get-value b_) fun))
                               (r   (reg tr fun))
                               (w   (reg tr fun))
                               (*rx (reg <long> fun))]
                              (IMUL n r+)
                              (LEA *rx (ptr tr *r n))
                              (IMUL r+ r+ (size-of tr))
                              (IMUL a+ a+ (size-of ta))
                              (CMP *r *rx)
                              (JE 'return)
                              'loop
                              ((if (eqv? (size-of ta) (size-of tr))
                                 MOV
                                 (if (signed? ta) MOVSX MOVZX)) r (ptr ta *a))
                              (if (eqv? (size-of cb) (size-of tr))
                                (ADD r b)
                                (append
                                  ((if (signed? cb) MOVSX MOVZX) w b)
                                  (ADD r w)))
                              (MOV (ptr tr *r) r)
                              (ADD *r r+)
                              (ADD *a a+)
                              (CMP *r *rx)
                              (JNE 'loop)
                              'return))))]
    (add-method! + m)
    (+ a b)))
(define-method (+ (a <element>) (b <sequence<>>))
  (let* [(ca (class-of a))
         (cb (class-of b))
         (cr (coerce ca cb))
         (tb (typecode cb))
         (tr (typecode cr))
         (m  (jit-wrap ctx cr (ca cb)
                       (lambda (fun r_ a_ b_)
                         (env fun
                              [(*r  (reg (get-value r_) fun))
                               (r+  (reg (last (strides r_)) fun))
                               (n   (reg (last (shape r_)) fun))
                               (a   (reg (get-value a_) fun))
                               (*b  (reg (get-value b_) fun))
                               (b+  (reg (last (strides b_)) fun))
                               (r   (reg tr fun))
                               (w   (reg tr fun))
                               (*rx (reg <long> fun))]
                              (IMUL n r+)
                              (LEA *rx (ptr tr *r n))
                              (IMUL r+ r+ (size-of tr))
                              (IMUL b+ b+ (size-of tb))
                              (CMP *r *rx)
                              (JE 'return)
                              'loop
                              ((if (eqv? (size-of ca) (size-of tr))
                                 MOV
                                 (if (signed? ca) MOVSX MOVZX)) r a)
                              (if (eqv? (size-of tb) (size-of tr))
                                (ADD r (ptr tb *b))
                                (append
                                  ((if (signed? tb) MOVSX MOVZX) w (ptr tb *b))
                                  (ADD r w)))
                              (MOV (ptr tr *r) r)
                              (ADD *r r+)
                              (ADD *b b+)
                              (CMP *r *rx)
                              (JNE 'loop)
                              'return))))]
    (add-method! + m)
    (+ a b)))
(define-method (+ (a <sequence<>>) (b <sequence<>>))
  (let* [(ca (class-of a))
         (cb (class-of b))
         (cr (coerce ca cb))
         (ta (typecode ca))
         (tb (typecode cb))
         (tr (typecode cr))
         (m  (jit-wrap ctx cr (ca cb)
                       (lambda (fun r_ a_ b_)
                         (env fun
                              [(*r  (reg (get-value r_) fun))
                               (r+  (reg (last (strides r_)) fun))
                               (*a  (reg (get-value a_) fun))
                               (a+  (reg (last (strides a_)) fun))
                               (*b  (reg (get-value b_) fun))
                               (b+  (reg (last (strides b_)) fun))
                               (r   (reg tr fun))
                               (w   (reg tr fun))
                               (n   (reg (last (shape r_)) fun))
                               (*rx (reg <long> fun))]
                              (IMUL n r+)
                              (LEA *rx (ptr tr *r n))
                              (IMUL r+ r+ (size-of tr))
                              (IMUL a+ a+ (size-of ta))
                              (IMUL b+ b+ (size-of tb))
                              (CMP *r *rx)
                              (JE 'return)
                              'loop
                              ((if (eqv? (size-of ta) (size-of tr))
                                 MOV
                                 (if (signed? ta) MOVSX MOVZX)) r (ptr ta *a))
                              (if (eqv? (size-of tb) (size-of tr))
                                (ADD r (ptr tb *b))
                                (append
                                  ((if (signed? tb) MOVSX MOVZX) w (ptr tb *b))
                                  (ADD r w)))
                              (MOV (ptr tr *r) r)
                              (ADD *r r+)
                              (ADD *a a+)
                              (ADD *b b+)
                              (CMP *r *rx)
                              (JNE 'loop)
                              'return))))]
    (add-method! + m)
    (+ a b)))

(define-method (unary-minus (fun <jit-function>) (r_ <element>) (a_ <element>))
  (env fun
       [(r (reg (get-value r_) fun))
        (a (reg (get-value a_) fun))]
         (MOV r a)
         (NEG r)))
(define-method (unary-minus (fun <jit-function>) (r_ <pointer<>>) (a_ <pointer<>>))
  (env fun
       [(r (reg (typecode r_) fun))]
         (MOV r (ptr (typecode a_) (get-value a_)))
         (NEG r)
         (MOV (ptr (typecode r_) (get-value r_)) r)))
(define-method (unary-minus (fun <jit-function>) (r_ <sequence<>>) (a_ <sequence<>>))
  (env fun
       [(r+  (reg (last (strides r_)) fun))
        (a+  (reg (last (strides a_)) fun))
        (n   (reg (last (shape r_)) fun))
        (*p  (reg <long> fun))
        (*q  (reg <long> fun))
        (*rx (reg <long> fun))]
       (IMUL n r+)
       (MOV *p (get-value r_))
       (MOV *q (get-value a_))
       (LEA *rx (ptr (typecode r_) *p n))
       (IMUL r+ r+ (size-of (typecode r_)))
       (IMUL a+ a+ (size-of (typecode a_)))
       (CMP *p *rx)
       (JE 'return)
       'loop
       (unary-minus fun (project (rebase *p r_)) (project (rebase *q a_)))
       (ADD *p r+)
       (ADD *q a+)
       (CMP *p *rx)
       (JNE 'loop)
       'return))
(define-method (- (a <element>))
  (add-method! - (jit-wrap ctx
                           (class-of a)
                           ((class-of a))
                           (lambda (fun r_ a_) (unary-minus fun r_ a_))))
  (- a))

(define-method (binary-minus (fun <jit-function>) (r_ <element>) (a_ <element>) (b_ <element>))
  (env fun
       [(r (reg (get-value r_) fun))
        (a (reg (get-value a_) fun))
        (b (reg (get-value b_) fun))
        (w (reg (class-of r_) fun))]
       ((if (eqv? (size-of (class-of a_)) (size-of (class-of r_)))
          MOV
          (if (signed? (class-of a_)) MOVSX MOVZX)) r a)
       (if (eqv? (size-of (class-of b_)) (size-of (class-of r_)))
         (SUB r b)
         (append
           ((if (signed? (class-of b_)) MOVSX MOVZX) w b)
           (SUB r w)))))
(define-method (binary-minus (fun <jit-function>) (r_ <pointer<>>) (a_ <pointer<>>) (b_ <element>))
  (env fun
       [(r (reg (typecode r_) fun))
        (w (reg (typecode r_) fun))
        (b (reg (get-value b_) fun))]
       ((if (eqv? (size-of (typecode a_)) (size-of (typecode r_)))
          MOV
          (if (signed? (typecode a_)) MOVSX MOVZX)) r (ptr (typecode a_) (get-value a_)))
       (if (eqv? (size-of (class-of b_)) (size-of (typecode r_)))
         (SUB r b)
         (append
           ((if (signed? (class-of b_)) MOVSX MOVZX) w b)
           (SUB r w)))
       (MOV (ptr (typecode r_) (get-value r_)) r)))
(define-method (binary-minus (fun <jit-function>) (r_ <pointer<>>) (a_ <element>) (b_ <pointer<>>))
   (env fun
       [(r (reg (typecode r_) fun))
        (w (reg (typecode r_) fun))
        (a (reg (get-value a_) fun))
        (*b (reg (get-value b_) fun))]
       ((if (eqv? (size-of (class-of a_)) (size-of (typecode r_)))
          MOV
          (if (signed? (class-of a_)) MOVSX MOVZX)) r a)
       (if (eqv? (size-of (typecode b_)) (size-of (typecode r_)))
         (SUB r (ptr (typecode b_) *b))
         (append
           ((if (signed? (typecode b_)) MOVSX MOVZX) w (ptr (typecode b_) *b))
           (SUB r w)))
       (MOV (ptr (typecode r_) (get-value r_)) r)))
(define-method (binary-minus (fun <jit-function>) (r_ <pointer<>>) (a_ <pointer<>>) (b_ <pointer<>>))
  (env fun
       [(r (reg (typecode r_) fun))
        (w (reg (typecode r_) fun))]
       ((if (eqv? (size-of (typecode a_)) (size-of (typecode r_)))
          MOV
          (if (signed? (typecode a_)) MOVSX MOVZX)) r (ptr (typecode a_) (get-value a_)))
       (if (eqv? (size-of (typecode b_)) (size-of (typecode r_)))
         (SUB r (ptr (typecode b_) (get-value b_)))
         (append
           ((if (signed? (typecode b_)) MOVSX MOVZX) w (ptr (typecode b_) (get-value b_)))
           (SUB r w)))
       (MOV (ptr (typecode r_) (get-value r_)) r)))
(define-method (binary-minus (fun <jit-function>) (r_ <sequence<>>) (a_ <sequence<>>) (b_ <element>))
  (env fun
       [(r+  (reg (last (strides r_)) fun))
        (a+  (reg (last (strides a_)) fun))
        (n   (reg (last (shape r_)) fun))
        (*p  (reg <long> fun))
        (*q  (reg <long> fun))
        (*rx (reg <long> fun))]
       (IMUL n r+)
       (MOV *p (get-value r_))
       (MOV *q (get-value a_))
       (LEA *rx (ptr (typecode r_) *p n))
       (IMUL r+ r+ (size-of (typecode r_)))
       (IMUL a+ a+ (size-of (typecode a_)))
       (CMP *p *rx)
       (JE 'return)
       'loop
       (binary-minus fun (project (rebase *p r_)) (project (rebase *q a_)) b_)
       (ADD *p r+)
       (ADD *q a+)
       (CMP *p *rx)
       (JNE 'loop)
       'return))
(define-method (binary-minus (fun <jit-function>) (r_ <sequence<>>) (a_ <element>) (b_ <sequence<>>))
  (env fun
       [(r+  (reg (last (strides r_)) fun))
        (a   (reg (get-value a_) fun))
        (*b  (reg (get-value b_) fun))
        (b+  (reg (last (strides b_)) fun))
        (n   (reg (last (shape r_)) fun))
        (*p  (reg <long> fun))
        (*q  (reg <long> fun))
        (*rx (reg <long> fun))]
       (IMUL n r+)
       (MOV *p (get-value r_))
       (MOV *q *b)
       (LEA *rx (ptr (typecode r_) *p n))
       (IMUL r+ r+ (size-of (typecode r_)))
       (IMUL b+ b+ (size-of (typecode b_)))
       (CMP *p *rx)
       (JE 'return)
       'loop
       (binary-minus fun (project (rebase *p r_)) a_ (project (rebase *q b_)))
       (ADD *p r+)
       (ADD *q b+)
       (CMP *p *rx)
       (JNE 'loop)
       'return))
(define-method (binary-minus (fun <jit-function>) (r_ <sequence<>>) (a_ <sequence<>>) (b_ <sequence<>>))
  (env fun
       [(*r  (reg (get-value r_) fun))
        (r+  (reg (last (strides r_)) fun))
        (*a  (reg (get-value a_) fun))
        (a+  (reg (last (strides a_)) fun))
        (*b  (reg (get-value b_) fun))
        (b+  (reg (last (strides b_)) fun))
        (n   (reg (last (shape r_)) fun))
        (*p  (reg <long> fun))
        (*q  (reg <long> fun))
        (*s  (reg <long> fun))
        (*rx (reg <long> fun))]
       (IMUL n r+)
       (MOV *p *r)
       (MOV *q *a)
       (MOV *s *b); TODO: (get-value b_) does not work here
       (LEA *rx (ptr (typecode r_) *p n))
       (IMUL r+ r+ (size-of (typecode r_)))
       (IMUL a+ a+ (size-of (typecode a_)))
       (IMUL b+ b+ (size-of (typecode b_)))
       (CMP *p *rx)
       (JE 'return)
       'loop
       (binary-minus fun
                     (project (rebase *p r_))
                     (project (rebase *q a_))
                     (project (rebase *s b_)))
       (ADD *p r+)
       (ADD *q a+)
       (ADD *s b+)
       (CMP *p *rx)
       (JNE 'loop)
       'return))

(define-method (- (a <element>) (b <element>))
  (add-method! - (jit-wrap ctx
                           (coerce (class-of a) (class-of b))
                           ((class-of a) (class-of b))
                           (lambda (fun r_ a_ b_) (binary-minus fun r_ a_ b_))))
  (- a b))
(define-method (- (a <element>) (b <integer>))
  (- a (make (match b) #:value b)))
(define-method (- (a <integer>) (b <element>))
  (- (make (match a) #:value a) b))

(define (fill t n value); TODO: replace with tensor operation
  (let [(retval (make (sequence t) #:size n))]
    (store retval value)
    retval))
