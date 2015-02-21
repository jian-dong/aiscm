(use-modules (oop goops)
             (system foreign)
             (aiscm element)
             (aiscm int)
             (aiscm jit)
             (guile-tap))
(planned-tests 62)
(ok (equal? (integer 32 signed) (integer 32 signed))
    "equality of classes")
(ok (equal? <int> (integer 32 signed))
    "equality of predefined classes")
(ok (eqv? 64 (bits (integer 64 signed)))
    "number of bits of integer class")
(ok (signed? (integer 64 signed))
    "signed-ness of signed integer class")
(ok (not (signed? (integer 64 unsigned)))
    "signed-ness of unsigned integer class")
(ok (eqv? 1 (size-of <byte>))
    "storage size of byte")
(ok (eqv? 2 (size-of <sint>))
    "storage size of short integer")
(ok (eqv? 4 (size-of <uint>))
    "storage size of unsigned integer")
(ok (eqv? 8 (size-of <long>))
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
(ok (equal? int8 (foreign-type (integer 8 signed)))
    "foreign type of byte")
(ok (equal? uint16 (foreign-type (integer 16 unsigned)))
    "foreign type of unsigned short int")
(ok (equal? <ubyte> (match 255))
    "type matching for 255")
(ok (equal? <usint> (match 256))
    "type matching for 256")
(ok (equal? <usint> (match 65535))
    "type matching for 65535")
(ok (equal? <uint> (match 65536))
    "type matching for 65536")
(ok (equal? <uint> (match 4294967295))
    "type matching for 4294967295")
(ok (equal? <ulong> (match 4294967296))
    "type matching for 4294967296")
(ok (equal? <ulong> (match 18446744073709551615))
    "type matching for 18446744073709551615")
(ok (throws? (match 18446744073709551616))
    "type matching for 18446744073709551616")
(ok (equal? <byte> (match -128))
    "type matching for -128")
(ok (equal? <sint> (match -129))
    "type matching for -129")
(ok (equal? <sint> (match -32768))
    "type matching for -32768")
(ok (equal? <int> (match -32769))
    "type matching for -32769")
(ok (equal? <int> (match -2147483648))
    "type matching for -2147483648")
(ok (equal? <long> (match -2147483649))
    "type matching for -2147483649")
(ok (equal? <long> (match -9223372036854775808))
    "type matching for -9223372036854775808")
(ok (throws? (match -9223372036854775809))
    "type matching for -9223372036854775809")
(ok (eqv? 123 (get (make <int> #:value 123)))
    "get value of integer")
(ok (eqv? 123 (let [(i (make <int> #:value 0))] (set i 123) (get-value i)))
    "set value of integer")
(ok (eqv? 123 (set (make <int> #:value 0) 123))
    "return-value of setting integer")
(ok (equal? (list <sint>) (types <sint>))
    "'types' returns the type itself")
(ok (equal? '(42) (content 42))
    "'content' returns integer values")
(ok (let [(v (make <var> #:type <int> #:symbol 'v))]
      (equal? v (param <int> (list v))))
    "'param' passes integer variables through")
