(define-module (aiscm obj)
  #:use-module (oop goops)
  #:use-module (system foreign)
  #:use-module (rnrs bytevectors)
  #:use-module (aiscm util)
  #:use-module (aiscm element)
  #:use-module (aiscm bool)
  #:use-module (aiscm int)
  #:use-module (aiscm pointer)
  #:use-module (aiscm method)
  #:use-module (aiscm asm)
  #:use-module (aiscm scalar)
  #:export (<obj> <meta<obj>>
            <pointer<obj>> <meta<pointer<obj>>>
            obj-negate scm-lognot obj-zero-p obj-nonzero-p obj-not scm-sum
            scm-difference scm-product scm-divide scm-remainder
            scm-logand scm-logior scm-logxor obj-and obj-or scm-min scm-max scm-ash obj-shr
            obj-equal-p obj-nequal-p obj-less-p obj-leq-p obj-gr-p obj-geq-p
            obj-from-bool scm-to-bool
            scm-to-uint8 scm-from-uint8 scm-to-int8 scm-from-int8
            scm-to-uint16 scm-from-uint16 scm-to-int16 scm-from-int16
            scm-to-uint32 scm-from-uint32 scm-to-int32 scm-from-int32
            scm-to-uint64 scm-from-uint64 scm-to-int64 scm-from-int64
            scm-eol scm-cons))
(define-class* <obj> <scalar> <meta<obj>> <meta<scalar>>)
(define-method (size-of (self <meta<obj>>)) 8)
(define-method (pack (self <obj>))
  (uint-list->bytevector (list (scm->address (get self))) (native-endianness) 8))
(define-method (unpack (self <meta<obj>>) (packed <bytevector>))
  (let [(value (car (bytevector->uint-list packed (native-endianness) (size-of self))))]
    (make self #:value (address->scm value))))
(define-method (coerce a b) <obj>)
(define-method (write (self <obj>) port)
  (format port "#<~a ~a>" (class-name (class-of self)) (get self)))
(define-method (native-type o . args) <obj>)
(define-method (unbuild (type <meta<obj>>) self) (list (scm->address self)))
(define-method (pointerless? (self <meta<obj>>)) #f)
(define-method (signed? (self <meta<obj>>)) #f)

(pointer <obj>)

(define main (dynamic-link))
(define guile-aiscm-obj (dynamic-link "libguile-aiscm-obj"))

; various operations for Scheme objects (SCM values)
(define obj-negate      (native-method <obj>   (list <obj>        ) (dynamic-func "obj_negate"      guile-aiscm-obj)))
(define scm-lognot      (native-method <obj>   (list <obj>        ) (dynamic-func "scm_lognot"      main           )))
(define obj-zero-p      (native-method <bool>  (list <obj>        ) (dynamic-func "obj_zero_p"      guile-aiscm-obj)))
(define obj-nonzero-p   (native-method <bool>  (list <obj>        ) (dynamic-func "obj_nonzero_p"   guile-aiscm-obj)))
(define obj-not         (native-method <bool>  (list <obj>        ) (dynamic-func "obj_not"         guile-aiscm-obj)))
(define scm-sum         (native-method <obj>   (list <obj>   <obj>) (dynamic-func "scm_sum"         main           )))
(define scm-difference  (native-method <obj>   (list <obj>   <obj>) (dynamic-func "scm_difference"  main           )))
(define scm-product     (native-method <obj>   (list <obj>   <obj>) (dynamic-func "scm_product"     main           )))
(define scm-divide      (native-method <obj>   (list <obj>   <obj>) (dynamic-func "scm_divide"      main           )))
(define scm-remainder   (native-method <obj>   (list <obj>   <obj>) (dynamic-func "scm_remainder"   main           )))
(define scm-logand      (native-method <obj>   (list <obj>   <obj>) (dynamic-func "scm_logand"      main           )))
(define scm-logior      (native-method <obj>   (list <obj>   <obj>) (dynamic-func "scm_logior"      main           )))
(define scm-logxor      (native-method <obj>   (list <obj>   <obj>) (dynamic-func "scm_logxor"      main           )))
(define obj-and         (native-method <obj>   (list <obj>   <obj>) (dynamic-func "obj_and"         guile-aiscm-obj)))
(define obj-or          (native-method <obj>   (list <obj>   <obj>) (dynamic-func "obj_or"          guile-aiscm-obj)))
(define scm-min         (native-method <obj>   (list <obj>   <obj>) (dynamic-func "scm_min"         main           )))
(define scm-max         (native-method <obj>   (list <obj>   <obj>) (dynamic-func "scm_max"         main           )))
(define scm-ash         (native-method <obj>   (list <obj>   <obj>) (dynamic-func "scm_ash"         main           )))
(define obj-shr         (native-method <obj>   (list <obj>   <obj>) (dynamic-func "obj_shr"         guile-aiscm-obj)))
(define obj-equal-p     (native-method <bool>  (list <obj>   <obj>) (dynamic-func "obj_equal_p"     guile-aiscm-obj)))
(define obj-nequal-p    (native-method <bool>  (list <obj>   <obj>) (dynamic-func "obj_nequal_p"    guile-aiscm-obj)))
(define obj-less-p      (native-method <bool>  (list <obj>   <obj>) (dynamic-func "obj_less_p"      guile-aiscm-obj)))
(define obj-leq-p       (native-method <bool>  (list <obj>   <obj>) (dynamic-func "obj_leq_p"       guile-aiscm-obj)))
(define obj-gr-p        (native-method <bool>  (list <obj>   <obj>) (dynamic-func "obj_gr_p"        guile-aiscm-obj)))
(define obj-geq-p       (native-method <bool>  (list <obj>   <obj>) (dynamic-func "obj_geq_p"       guile-aiscm-obj)))

; conversions for Scheme objects (SCM values)
(define scm-to-bool     (native-method <bool>  (list <obj>        ) (dynamic-func "scm_to_bool"     main           )))
(define obj-from-bool   (native-method <obj>   (list <bool>       ) (dynamic-func "obj_from_bool"   guile-aiscm-obj)))
(define scm-to-uint8    (native-method <ubyte> (list <obj>        ) (dynamic-func "scm_to_uint8"    main           )))
(define scm-from-uint8  (native-method <obj>   (list <ubyte>      ) (dynamic-func "scm_from_uint8"  main           )))
(define scm-to-int8     (native-method <byte>  (list <obj>        ) (dynamic-func "scm_to_int8"     main           )))
(define scm-from-int8   (native-method <obj>   (list <byte>       ) (dynamic-func "scm_from_int8"   main           )))
(define scm-to-uint16   (native-method <usint> (list <obj>        ) (dynamic-func "scm_to_uint16"   main           )))
(define scm-from-uint16 (native-method <obj>   (list <usint>      ) (dynamic-func "scm_from_uint16" main           )))
(define scm-to-int16    (native-method <sint>  (list <obj>        ) (dynamic-func "scm_to_int16"    main           )))
(define scm-from-int16  (native-method <obj>   (list <sint>       ) (dynamic-func "scm_from_int16"  main           )))
(define scm-to-uint32   (native-method <uint>  (list <obj>        ) (dynamic-func "scm_to_uint32"   main           )))
(define scm-from-uint32 (native-method <obj>   (list <uint>       ) (dynamic-func "scm_from_uint32" main           )))
(define scm-to-int32    (native-method <int>   (list <obj>        ) (dynamic-func "scm_to_int32"    main           )))
(define scm-from-int32  (native-method <obj>   (list <int>        ) (dynamic-func "scm_from_int32"  main           )))
(define scm-to-uint64   (native-method <ulong> (list <obj>        ) (dynamic-func "scm_to_uint64"   main           )))
(define scm-from-uint64 (native-method <obj>   (list <ulong>      ) (dynamic-func "scm_from_uint64" main           )))
(define scm-to-int64    (native-method <long>  (list <obj>        ) (dynamic-func "scm_to_int64"    main           )))
(define scm-from-int64  (native-method <obj>   (list <long>       ) (dynamic-func "scm_from_int64"  main           )))

; Scheme list manipulation
(define scm-eol (native-value <obj> (scm->address '())))
(define scm-cons (native-method <obj> (list <obj> <obj>) (dynamic-func "scm_cons" main)))
