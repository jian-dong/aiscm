(use-modules (oop goops) (aiscm llvm) (aiscm util) (system foreign) (rnrs bytevectors) (aiscm basictype) (srfi srfi-1) (srfi srfi-26))

((llvm-typed (list <int>)
  (lambda (n)
    (let [(block-begin (make-basic-block "block-begin"))
          (block-start (make-basic-block "block-start"))
          (block-end   (make-basic-block "block-end"  ))]
      (with-llvm-values (i j)
        (build-branch block-begin)
        (position-builder-at-end block-begin)
        (llvm-set i (typed-constant <int> 0))
        (build-branch block-start)
        (position-builder-at-end block-start)
        (llvm-set j (+ (phi (list i j) (list block-begin block-start)) (typed-constant <int> 1)))
        (build-cond-branch (lt i n) block-start block-end)
        (position-builder-at-end block-end)
        j)))) 3)


(define-method (test (x <number>))
  (add-method! test
               (make <method>
                     #:specializers (list (class-of x))
                     #:procedure (llvm-typed (list (native-type x)) (lambda (x) (- x)))))
  (test x))
