(use-modules (aiscm element)
             (aiscm int)
             (oop goops)
             (guile-tap))
(planned-tests 37)
(ok (eqv? 64 (bits (integer 64 signed)))
    "number of bits of integer class")
(ok (signed? (integer 64 signed))
    "signed-ness of signed integer class")
(ok (not (signed? (integer 64 unsigned)))
    "signed-ness of unsigned integer class")
(ok (eqv? 1 (storage-size <byte>))
    "storage size of byte")
(ok (eqv? 2 (storage-size <sint>))
    "storage size of short integer")
(ok (eqv? 4 (storage-size <uint>))
    "storage size of unsigned integer")
(ok (eqv? 8 (storage-size <long>))
    "storage size of long integer")
(ok (equal? (make <ubyte> #:value #x21) (make <ubyte> #:value #x21))
    "equal integer objects")
(ok (not (equal? (make <ubyte> #:value #x21) (make <usint> #:value #x4321)))
    "unequal integer objects")
(ok (not (equal? (make <ubyte> #:value #x21) (make <usint> #:value #x21)))
    "unequal integer objects of different classes")
(ok (eqv? 128 (bits (integer 128 signed)))
    "integer class maintains number of bits")
(ok (signed? (integer 128 signed))
    "integer class maintains signedness for signed integer")
(ok (not (signed? (integer 128 unsigned)))
    "integer class maintains signedness for unsigned integer")
(ok (equal? #vu8(#x01 #x02)
            (pack (make (integer 16 unsigned) #:value #x0201)))
    "pack custom integer value")
(ok (equal? #vu8(#xff) (pack (make <ubyte> #:value #xff)))
    "pack unsigned byte value")
(ok (equal? #vu8(#x01 #x02) (pack (make <usint> #:value #x0201)))
    "pack unsigned short integer value")
(ok (equal? #vu8(#x01 #x02 #x03 #x04) (pack (make <uint> #:value #x04030201)))
    "pack unsigned integer value")
(ok (equal? (unpack <ubyte> #vu8(#xff)) (make <ubyte> #:value #xff))
    "unpack unsigned byte value")
(ok (equal? (unpack <usint> #vu8(#x01 #x02)) (make <usint> #:value #x0201))
    "unpack unsigned short integer value")
(ok (equal? (unpack <uint> #vu8(#x01 #x02 #x03 #x04))
            (make <uint> #:value #x04030201))
    "unpack unsigned integer value")
(ok (eqv? 127 (get-value (unpack <byte> (pack (make <byte> #:value 127)))))
    "pack and unpack signed byte")
(ok (eqv? -128 (get-value (unpack <byte> (pack (make <byte> #:value -128)))))
    "pack and unpack signed byte with negative number")
(ok (eqv? 32767 (get-value (unpack <sint> (pack (make <sint> #:value 32767)))))
    "pack and unpack signed short integer")
(ok (eqv? -32768 (get-value (unpack <sint> (pack (make <sint> #:value -32768)))))
    "pack and unpack signed short integer with negative number")
(ok (eqv? 2147483647
          (get-value (unpack <int> (pack (make <int> #:value 2147483647)))))
    "pack and unpack signed integer")
(ok (eqv? -2147483648
          (get-value (unpack <int> (pack (make <int> #:value -2147483648)))))
    "pack and unpack signed integer with negative number")
(ok (equal? (make <byte> #:value 123) (subst (make <byte> #:value 123) '()))
    "ignores substitutions")
(ok (eqv? 1 (size (make <int> #:value 123)))
    "querying element size of integer")
(ok (null? (shape (make <int> #:value 123)))
    "querying shape of integer")
(ok (equal? "#<<int<16,signed>> 1234>"
            (call-with-output-string (lambda (port) (display (make <sint> #:value 1234) port))))
    "display short integer object")
(ok (equal? "#<<int<16,signed>> 1234>"
            (call-with-output-string (lambda (port) (write (make <sint> #:value 1234) port))))
    "write short integer object")
(ok (equal? 32 (bits (coerce (integer 16 signed) (integer 32 signed))))
    "coercion returns largest integer type")
(ok (equal? 16 (bits (coerce (integer 8 signed) (integer 16 signed))))
    "coercion returns largest integer type")
(ok (not (signed? (coerce (integer 8 unsigned) (integer 16 unsigned))))
    "coercion of signed-ness")
(ok (signed? (coerce (integer 8 unsigned) (integer 16 signed)))
    "coercion of signed-ness")
(ok (signed? (coerce (integer 8 signed) (integer 16 unsigned)))
    "coercion of signed-ness")
(ok (signed? (coerce (integer 8 signed) (integer 16 signed)))
    "coercion of signed-ness")
(format #t "~&")
