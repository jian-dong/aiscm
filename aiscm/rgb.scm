(define-module (aiscm rgb)
  #:use-module (oop goops)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-26)
  #:use-module (rnrs bytevectors)
  #:use-module (ice-9 optargs)
  #:use-module (aiscm util)
  #:use-module (aiscm element)
  #:use-module (aiscm composite)
  #:use-module (aiscm bool)
  #:use-module (aiscm pointer)
  #:use-module (aiscm int)
  #:use-module (aiscm asm)
  #:use-module (aiscm jit)
  #:use-module (aiscm sequence)
  #:export (<rgb>
            <rgb<>> <meta<rgb<>>>
            <pointer<rgb<>>> <meta<pointer<rgb>>>>
            <ubytergb> <rgb<int<8,unsigned>>>  <meta<rgb<int<8,unsigned>>>>
            <bytergb>  <rgb<int<8,signed>>>    <meta<rgb<int<8,signed>>>>
            <usintrgb> <rgb<int<16,unsigned>>> <meta<rgb<int<16,unsigned>>>>
            <sintrgb>  <rgb<int<16,signed>>>   <meta<rgb<int<16,signed>>>>
            <uintrgb>  <rgb<int<32,unsigned>>> <meta<rgb<int<32,unsigned>>>>
            <intrgb>   <rgb<int<32,signed>>>   <meta<rgb<int<32,signed>>>>
            <ulonggb>  <rgb<int<64,unsigned>>> <meta<rgb<int<64,unsigned>>>>
            <longrgb>  <rgb<int<64,signed>>>   <meta<rgb<int<64,signed>>>>
            rgb red green blue)
  #:re-export (+ -))

(define ctx (make <context>))

(define-class <rgb> ()
  (red   #:init-keyword #:red   #:getter red)
  (green #:init-keyword #:green #:getter green)
  (blue  #:init-keyword #:blue  #:getter blue))
(define-method (rgb r g b) (make <rgb> #:red r #:green g #:blue b))
(define-method (write (self <rgb>) port)
  (format port "(rgb ~a ~a ~a)" (red self) (green self) (blue self)))
(define-method (red   self) self)
(define-method (green self) self)
(define-method (blue  self) self)
(define-class* <rgb<>> <composite> <meta<rgb<>>> <meta<composite>>)
(define-method (rgb (t <meta<element>>))
  (template-class (rgb t) <rgb<>>
    (lambda (class metaclass)
      (define-method (base (self metaclass))t)
      (define-method (size-of (self metaclass)) (* 3 (size-of t))))))
(define-method (rgb (t <meta<sequence<>>>)) (multiarray (rgb (typecode t)) (dimensions t)))
(define-method (rgb (r <meta<element>>) (g <meta<element>>) (b <meta<element>>))
  (rgb (reduce coerce #f (list r g b))))
(define-method (red   (self <rgb<>>)) (make (base (class-of self)) #:value (red   (get self))))
(define-method (green (self <rgb<>>)) (make (base (class-of self)) #:value (green (get self))))
(define-method (blue  (self <rgb<>>)) (make (base (class-of self)) #:value (blue  (get self))))
(define-method (write (self <rgb<>>) port)
  (format port "#<~a ~a>" (class-name (class-of self)) (get self)))
(define-method (base (self <meta<sequence<>>>)) (multiarray (base (typecode self)) (dimensions self)))
(define-method (pack (self <rgb<>>)) (bytevector-concat (map pack (content <rgb<>> self))))
(define-method (unpack (self <meta<rgb<>>>) (packed <bytevector>))
  (let* [(size    (size-of (base self)))
         (vectors (map (cut bytevector-sub packed <> size) (map (cut * size <>) (iota 3))))]
    (make self #:value (apply rgb (map (lambda (vec) (get (unpack (base self) vec))) vectors)))))
(define <ubytergb> (rgb <ubyte>))
(define <bytergb>  (rgb <byte> ))
(define <usintrgb> (rgb <usint>))
(define <sintrgb>  (rgb <sint> ))
(define <uintrgb>  (rgb <uint> ))
(define <intrgb>   (rgb <int>  ))
(define <ulongrgb> (rgb <ulong>))
(define <longrgb>  (rgb <long> ))
(define-method (coerce (a <meta<rgb<>>>) (b <meta<element>>)) (rgb (coerce (base a) b)))
(define-method (coerce (a <meta<element>>) (b <meta<rgb<>>>)) (rgb (coerce a (base b))))
(define-method (coerce (a <meta<rgb<>>>) (b <meta<rgb<>>>)) (rgb (coerce (base a) (base b))))
(define-method (coerce (a <meta<rgb<>>>) (b <meta<sequence<>>>)) (multiarray (coerce a (typecode b)) (dimensions b)))
(define-method (native-type (c <rgb>) . args)
  (rgb (apply native-type (concatenate (map-if (cut is-a? <> <rgb>) (cut content <rgb<>> <>) list (cons c args))))))
(define-method (build (self <meta<rgb<>>>) value) (fetch value))
(define-method (content (type <meta<rgb<>>>) (self <rgb>)) (map (cut <> self) (list red green blue) ))
(define-method (content (type <meta<rgb<>>>) (self <rgb<>>)) (map (cut <> self) (list red green blue) ))
(define-method (typecode (self <rgb>)) (rgb (reduce coerce #f (map typecode (content <rgb<>> self)))))
(define-syntax-rule (unary-rgb-op op) (define-method (op (a <rgb>)) (apply rgb (map op (content <rgb<>> a)))))
(unary-rgb-op -)
(unary-rgb-op ~)
(define-syntax-rule (binary-rgb-op op)
  (begin
    (define-method (op (a <rgb>)  b       ) (apply rgb (map (cut op <> b) (content <rgb<>> a)                    )))
    (define-method (op  a        (b <rgb>)) (apply rgb (map (cut op a <>)                     (content <rgb<>> b))))
    (define-method (op (a <rgb>) (b <rgb>)) (apply rgb (map op            (content <rgb<>> a) (content <rgb<>> b))))
    (define-method (op (a <rgb>)     (b <element>)) (op (wrap a) b))
    (define-method (op (a <element>) (b <rgb>)    ) (op a (wrap b)))))
(binary-rgb-op +  )
(binary-rgb-op -  )
(binary-rgb-op *  )
(binary-rgb-op &  )
(binary-rgb-op |  )
(binary-rgb-op ^  )
(binary-rgb-op << )
(binary-rgb-op >> )
(binary-rgb-op /  )
(binary-rgb-op %  )
(binary-rgb-op max)
(binary-rgb-op min)
(define-syntax-rule (binary-rgb-cmp op f)
  (begin
    (define-method (op (a <rgb>)  b       ) (apply f (map (cut op <> b) (content <rgb<>> a)                    )))
    (define-method (op  a        (b <rgb>)) (apply f (map (cut op a <>)                     (content <rgb<>> b))))
    (define-method (op (a <rgb>) (b <rgb>)) (apply f (map op            (content <rgb<>> a) (content <rgb<>> b))))))
(binary-rgb-cmp equal? equal?)
(binary-rgb-cmp =  &&)
(binary-rgb-cmp != ||)

(define-method (copy-value (typecode <meta<rgb<>>>) a b)
  (append-map (lambda (channel) (code (channel a) (channel b))) (list red green blue)))

(define-method (var (self <meta<rgb<>>>)) (let [(type (base self))] (rgb (var type) (var type) (var type))))
(define-method (component (type <meta<rgb<>>>) self offset)
  (let* [(type (base (typecode self)))]
    (set-pointer-offset (pointer-cast type self) (* offset (size-of type)))))
(pointer <rgb<>>)
(define-method (red   (self <pointer<int<>>>)) self)
(define-method (green (self <pointer<int<>>>)) self)
(define-method (blue  (self <pointer<int<>>>)) self)
(define-method (red   (self <pointer<rgb<>>>)) (component (typecode self) self 0))
(define-method (green (self <pointer<rgb<>>>)) (component (typecode self) self 1))
(define-method (blue  (self <pointer<rgb<>>>)) (component (typecode self) self 2))

(define-jit-method base red   1 unary-extract red  )
(define-jit-method base green 1 unary-extract green)
(define-jit-method base blue  1 unary-extract blue )

(define-jit-method rgb rgb 3)

(define-method (decompose-value (target <meta<rgb<>>>) x)
  (make <rgb> #:red   (parameter (red   (delegate x)))
              #:green (parameter (green (delegate x)))
              #:blue  (parameter (blue  (delegate x)))))

(define-method (to-type (target <meta<rgb<>>>) (self <rgb>))
  (apply rgb (map (cut to-type (base target) <>) (content <rgb<>> self))))
