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
                              [(r (reg r_ fun))
                               (a (reg a_ fun))
                               (b (reg b_ fun))
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
                               (b   (reg b_ fun))
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
                              (CMP *rx *r)
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
                               (a   (reg a_ fun))
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
                              (CMP *rx *r)
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
                              (CMP *rx *r)
                              (JNE 'loop)
                              'return))))]
    (add-method! + m)
    (+ a b)))

(define-method (- (a <element>))
  (let* [(ca (class-of a))
         (cr ca)
         (m  (jit-wrap ctx cr (ca)
                       (lambda (fun r_ a_)
                         (env fun
                              [(r (reg r_ fun))
                               (a (reg a_ fun))]
                              (MOV r a)
                              (NEG r)))))]
    (add-method! - m)
    (- a)))
(define-method (- (a <sequence<>>))
  (let* [(ca (class-of a))
         (ta (typecode ca))
         (cr ca)
         (tr (typecode cr))
         (m  (jit-wrap ctx cr (ca)
                       (lambda (fun r_ a_)
                         (env fun
                              [(*r  (reg (get-value r_) fun))
                               (r+  (reg (last (strides r_)) fun))
                               (*a  (reg (get-value a_) fun))
                               (a+  (reg (last (strides a_)) fun))
                               (r   (reg tr fun))
                               (n   (reg (last (shape r_)) fun))
                               (*rx (reg <long> fun))]
                              (IMUL n r+)
                              (LEA *rx (ptr tr *r n))
                              (IMUL r+ r+ (size-of tr))
                              (IMUL a+ a+ (size-of ta))
                              (CMP *r *rx)
                              (JE 'return)
                              'loop
                              (MOV r (ptr ta *a))
                              (NEG r)
                              (MOV (ptr tr *r) r)
                              (ADD *r r+)
                              (ADD *a a+)
                              (CMP *rx *r)
                              (JNE 'loop)
                              'return))))]
    (add-method! - m)
    (- a)))
(define-method (- (a <element>) (b <element>))
  (let* [(ca (class-of a))
         (cb (class-of b))
         (cr (coerce ca cb))
         (m  (jit-wrap ctx cr (ca cb)
                       (lambda (fun r_ a_ b_)
                         (env fun
                              [(r (reg r_ fun))
                               (a (reg a_ fun))
                               (b (reg b_ fun))
                               (w (reg cr fun))]
                              ((if (eqv? (size-of ca) (size-of cr))
                                 MOV
                                 (if (signed? ca) MOVSX MOVZX)) r a)
                              (if (eqv? (size-of cb) (size-of cr))
                                (SUB r b)
                                (append
                                  ((if (signed? cb) MOVSX MOVZX) w b)
                                  (SUB r w)))))))]
    (add-method! - m)
    (- a b)))
(define-method (- (a <element>) (b <integer>))
  (- a (make (match b) #:value b)))
(define-method (- (a <integer>) (b <element>))
  (- (make (match a) #:value a) b))
(define-method (- (a <sequence<>>) (b <element>))
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
                               (*a  (reg (get-value a_) fun))
                               (a+  (reg (last (strides a_)) fun))
                               (b   (reg b_ fun))
                               (r   (reg tr fun))
                               (w   (reg tr fun))
                               (n   (reg (last (shape r_)) fun))
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
                                (SUB r b)
                                (append
                                  ((if (signed? cb) MOVSX MOVZX) w b)
                                  (SUB r w)))
                              (MOV (ptr tr *r) r)
                              (ADD *r r+)
                              (ADD *a a+)
                              (CMP *rx *r)
                              (JNE 'loop)
                              'return))))]
    (add-method! - m)
    (- a b)))
(define-method (- (a <element>) (b <sequence<>>))
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
                               (a   (reg a_ fun))
                               (*b  (reg (get-value b_) fun))
                               (b+  (reg (last (strides b_)) fun))
                               (r   (reg tr fun))
                               (w   (reg tr fun))
                               (n   (reg (last (shape r_)) fun))
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
                                (SUB r (ptr tb *b))
                                (append
                                  ((if (signed? tb) MOVSX MOVZX) w (ptr tb *b))
                                  (SUB r w)))
                              (MOV (ptr tr *r) r)
                              (ADD *r r+)
                              (ADD *b b+)
                              (CMP *rx *r)
                              (JNE 'loop)
                              'return))))]
    (add-method! - m)
    (- a b)))
(define-method (- (a <sequence<>>) (b <sequence<>>))
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
                                (SUB r (ptr tb *b))
                                (append
                                  ((if (signed? tb) MOVSX MOVZX) w (ptr tb *b))
                                  (SUB r w)))
                              (MOV (ptr tr *r) r)
                              (ADD *r r+)
                              (ADD *a a+)
                              (ADD *b b+)
                              (CMP *rx *r)
                              (JNE 'loop)
                              'return))))]
    (add-method! - m)
    (- a b)))

(define (fill t n value); TODO: replace with tensor operation
  (let [(retval (make (sequence t) #:size n))]
    (store retval value)
    retval))
