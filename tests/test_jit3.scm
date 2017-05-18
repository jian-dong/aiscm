;; AIscm - Guile extension for numerical arrays and tensors.
;; Copyright (C) 2013, 2014, 2015, 2016, 2017 Jan Wedekind <jan@wedesoft.de>
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;
(use-modules (srfi srfi-1)
             (srfi srfi-26)
             (srfi srfi-64)
             (oop goops)
             (rnrs bytevectors)
             (aiscm util)
             (aiscm asm)
             (aiscm variable)
             (aiscm command)
             (aiscm program)
             (aiscm mem)
             (aiscm register-allocate)
             (aiscm compile)
             (aiscm expression)
             (aiscm jit)
             (aiscm element)
             (aiscm int)
             (aiscm obj)
             (aiscm pointer)
             (aiscm sequence)
             (aiscm bool)
             (aiscm rgb)
             (aiscm complex))


(test-begin "aiscm jit3")

(load-extension "libguile-aiscm-tests" "init_tests")
(define ctx (make <context>))


(test-equal "multiply sequence with a number"
  '(6 9 15) (to-list (* (seq 2 3 5) 3)))
(test-equal "left-shift sequence"
  '(2 4 6) (to-list (<< (seq 1 2 3) 1)))
(test-equal "right-shift sequence"
  '(1 2 3) (to-list (>> (seq 4 8 12) 2)))
(test-equal "'duplicate' creates copy of slice"
  '(1 4) (to-list (duplicate (project (roll (arr (1 2 3) (4 5 6)))))))
(test-assert "'ensure-default-strides' should do nothing by default"
  (let [(m (make (multiarray <int> 2) #:shape '(6 4)))] (eq? m (ensure-default-strides m))))
(test-assert "'ensure-default-strides' should create a compact clone if the input is not contiguous"
  (let [(m (make (multiarray <int> 2) #:shape '(6 4)))] (equal? '(1 4) (strides (ensure-default-strides (roll m))))))
(test-equal "element-wise bit-wise and"
  '(3 0 1) (to-list (& (seq 3 4 5) 3)))
(test-equal "element-wise bit-wise or"
  '(3 7 7) (to-list (| 3 (seq 3 4 5))))
(test-equal "element-wise bit-wise xor"
  '(1 7 1) (to-list (^ (seq 2 3 4) (seq 3 4 5))))
(test-eq "typecast for scalar type"
  <int> (convert-type <int> <byte>))
(test-eq "typecast element-type of array type"
  (sequence <int>) (convert-type <int> (sequence <byte>)))
(test-equal "compare bytes with zero"
  '(#f #t #f) (to-list (=0 (seq -1 0 1))))
(test-equal "check whether bytes are not zero"
  '(#t #f #t) (to-list (!=0 (seq -1 0 1))))
(test-equal "element-wise and with three arguments"
  '(#f #t #f #f) (to-list (&& (seq #f #t #t #t) (seq #t #t #t #f) (seq #t #t #f #f))))
(test-equal "element-wise and with array and boolean argument"
  '(#f #t) (to-list (&& (seq #f #t) #t)))
(test-equal "element-wise or"
  '(#f #t #t #t) (to-list (|| (seq #f #t #f #t) (seq #f #f #t #t))))
(test-equal "element-wise not for booleans"
  '(#f #t #f) (to-list (! (seq #t #f #t))))
(test-equal "element-wise array-scalar comparison"
  '(#f #t #f) (to-list (= (seq <int> 1 2 3) 2)))
(test-equal "Element-wise scalar-array comparison"
  '(#f #t #f) (to-list (= 2 (seq <int> 1 2 3))))
(test-equal "Element-wise array-array comparison"
  '(#f #t #f) (to-list (= (seq <int> 3 2 1) (seq <int> 1 2 3))))
(test-equal "Element-wise comparison with integers of different size (first case)"
  '(#f #t #f) (to-list (= (seq <int> 3 2 1) (seq <byte> 1 2 3))))
(test-equal "Element-wise comparison with integers of different size (second case)"
  '(#f #t #f) (to-list (= (seq <byte> 3 2 1) (seq <int> 1 2 3))))
(test-equal "element-wise array-scalar non-equal comparison"
  '(#t #f #t) (to-list (!= (seq <int> 1 2 3) 2)))
(test-equal "element-wise lower-than"
  '(#t #f #f) (to-list (< (seq 3 4 255) 4)))
(test-equal "element-wise lower-than with signed values"
  '(#t #f #f) (to-list (< (seq -1 0 1) 0)))
(test-equal "element-wise lower-than with signed values"
  '(#f #f #t) (to-list (< 0 (seq -1 0 1))))
(test-equal "element-wise lower-equal with unsigned values"
  '(#t #t #f) (to-list (<= (seq 3 4 255) 4)))
(test-equal "element-wise lower-equal with signed values"
  '(#t #t #f) (to-list (<= (seq -1 0 1) 0)))
(test-equal "element-wise greater-than with signed values"
  '(#f #f #t) (to-list (> (seq 3 4 255) 4)))
(test-equal "element-wise lower-equal with signed values"
  '(#f #f #t) (to-list (> (seq -1 0 1) 0)))
(test-equal "element-wise greater-equal with unsigned values"
  '(#f #t #t) (to-list (>= (seq 3 4 255) 4)))
(test-equal "element-wise greater-equal with signed values"
  '(#f #t #t) (to-list (>= (seq -1 0 1) 0)))
(test-equal "element-wise lower-than with unsigned and signed byte"
  '(#f #f #f) (to-list (< (seq 1 2 128) -1)))
(test-equal "element-wise signed byte division"
  '(1 2 -3) (to-list (/ (seq 3 6 -9) 3)))
(test-equal "element-wise modulo"
  '(2 0 1) (to-list (% (seq 2 3 4) 3)))
(test-eq "check result type of parameter type conversion"
  <int> (type (to-type <int> (parameter <ubyte>))))
(test-equal "compile and run type conversion of scalar"
  42 ((jit ctx (list <byte>) (cut to-type <int> <>)) 42))
(test-equal "compile and run element-wise conversion of array to integer"
  '(2 3 5) (to-list ((jit ctx (list (sequence <byte>)) (cut to-type <int> <>)) (seq <byte> 2 3 5))))
(test-eq "type conversion uses specified element type for return value"
  <int> (typecode (to-type <int> (seq 2 3 5))))
(test-equal "type conversion preserves content"
  '(2 3 5) (to-list (to-type <int> (seq 2 3 5))))
(test-equal "compile and run element-wise conversion of array to byte"
  '(2 3 5) (to-list ((jit ctx (list (sequence <int>)) (cut to-type <byte> <>)) (seq <int> 2 3 5))))
(test-equal "typecasting to smaller integer type"
  '(255 0 1) (to-list (to-type <ubyte> (seq 255 256 257))))
(let [(a   (skeleton <sint>))
      (tmp (skeleton <sint>))]
  (test-equal "Use intermediate value"
    (attach (code tmp a) tmp) (insert-intermediate a tmp list))
  (test-equal "Use empty code"
    (code tmp a) (insert-intermediate a tmp (const '()))))
(let* [(a (parameter <sint>))
       (f (~ a))]
  (test-assert "parameter is not a pointer"
    (not (is-pointer? (parameter <int>))))
  (test-assert "pointer parameter is a pointer"
    (is-pointer? (parameter (pointer <int>))))
  (test-assert "no conversion required if types are the same"
    (not (need-conversion? <sint> <sint>)))
  (test-assert "conversion required if types are different"
    (need-conversion? <int> <sint>))
  (test-assert "no conversion required if integers have the same size"
    (not (need-conversion? <byte> <ubyte>)))
  (test-assert "no conversion required when changing bytes to booleans"
    (not (need-conversion? <byte> <bool>)))
  (test-assert "no conversion required when changing boolean to bytes"
    (not (need-conversion? <bool> <ubyte>)))
  (test-assert "Compilation of function always requires intermediate value"
    (code-needs-intermediate? <sint> f))
  (test-assert "Value does not require intermediate value"
    (not (code-needs-intermediate? <sint> a)))
  (test-assert "Value of different size requires intermediate value"
    (code-needs-intermediate? <int> a))
  (test-assert "Compilation of function always requires intermediate value"
    (call-needs-intermediate? <sint> f))
  (test-assert "Value does not require intermediate value"
    (not (call-needs-intermediate? <sint> a)))
  (test-assert "Value of different size requires intermediate value"
    (call-needs-intermediate? <int> a))
  (test-assert "Pointer requires intermediate value"
    (call-needs-intermediate? <obj> (parameter (pointer <int>)))))
(let [(a   (parameter <sint>))]
  (test-equal "Pass through parameters to specified function by default"
    (list a) (force-parameters (list <sint>) (list a) code-needs-intermediate? identity))
  (let* [(forced       (force-parameters (list <int>) (list a) code-needs-intermediate? identity))
         (intermediate (last forced))]
    (test-equal "Create parameter of target type if type is different"
      <int> (type intermediate))
    (test-equal "Create preamble for initialising intermediate values"
      (attach (code intermediate a) intermediate) forced)
    (test-equal "Alternatively force all parameters to the same type"
      <int> (type (last (force-parameters <int> (list a) code-needs-intermediate? identity))))))
(let [(a (parameter <int>))
      (b (parameter <sint>))
      (c (parameter <ubyte>))
      (r (parameter <long>))]
  (test-skip 1)
  (test-equal "Coerce to output value when using multiple mutating operations"
    (list (SUB RSP 8) (MOVSX RSI EDX) (MOVSX RDX CX) (ADD RSI RDX) (MOVZX RCX AL) (ADD RSI RCX) (ADD RSP 8) (RET))
    (jit-compile (flatten-code (attach ((term (+ a b c)) r) (RET))))))
(test-equal "Compiling and run plus operation with three numbers"
  9 ((jit ctx (list <int> <int> <int>) +) 2 3 4))
(test-equal "Compile and run binary mutating operating with nested second parameter"
  9 ((jit ctx (list <int> <int> <int>) (lambda (x y z) (+ x (+ y z)))) 2 3 4))
(test-assert "compile and run unary functional operation with nested parameter"
  ((jit ctx (list <int> <int>) (lambda (x y) (=0 (+ x y)))) -3 3))
(test-assert "compile and run binary functional operation with nested first parameter"
  ((jit ctx (list <int> <int> <int>) (lambda (a b c) (= a (+ b c)))) 5 2 3))
(test-assert "compile and run binary functional operation with nested first parameter"
  ((jit ctx (list <int> <int> <int>) (lambda (a b c) (= (+ a b) c))) 2 3 5))
(let [(i (parameter <int>))]
  (test-equal "Integer decomposes to itself"
    i (decompose-value <int> i)))
(test-equal "get minor number of two integers (first case)"
  2 ((jit ctx (list <usint> <usint>) min) 2 3))
(test-equal "get minor number of two integers (second case)"
  2 ((jit ctx (list <usint> <usint>) min) 3 2))
(test-equal "get minor number of two unsigned integers (first case)"
  32767 ((jit ctx (list <usint> <usint>) min) 32767 32768))
(test-equal "get minor number of two unsigned integers (second case)"
  32767 ((jit ctx (list <usint> <usint>) min) 32768 32767))
(test-equal "get minor number of two signed integers"
  -1 ((jit ctx (list <sint> <sint>) min) -1 1))
(test-equal "get major number of two unsigned integers (first case)"
  32768 ((jit ctx (list <usint> <usint>) max) 32767 32768))
(test-equal "get major number of two unsigned integers (second case)"
  32768 ((jit ctx (list <usint> <usint>) max) 32768 32767))
(test-equal "get major number of two signed integers"
  1 ((jit ctx (list <sint> <sint>) max) -1 1))
(test-equal "get major number of signed and unsigned short integers"
  32768 ((jit ctx (list <sint> <usint>) max) -1 32768))
(test-equal "get minor number of two unsigned bytes (first case)"
  2 ((jit ctx (list <ubyte> <ubyte>) min) 2 3))
(test-equal "get minor number of two unsigned bytes (second case)"
  2 ((jit ctx (list <ubyte> <ubyte>) min) 3 2))
(test-equal "get major number of two unsigned bytes (first case)"
  3 ((jit ctx (list <ubyte> <ubyte>) max) 2 3))
(test-equal "get major number of two unsigned bytes (second case)"
  3 ((jit ctx (list <ubyte> <ubyte>) max) 3 2))
(test-equal "get minor number of two bytes (first case)"
  -1 ((jit ctx (list <byte> <byte>) min) -1 1))
(test-equal "get minor number of two bytes (second case)"
  -1 ((jit ctx (list <byte> <byte>) min) 1 -1))
(test-equal "get major number of two bytes (first case)"
  1 ((jit ctx (list <byte> <byte>) max) -1 1))
(test-equal "get major number of two bytes (second case)"
  1 ((jit ctx (list <byte> <byte>) max) 1 -1))
(let [(r (parameter <ubyte>))
      (a (parameter <ubyte>))
      (b (parameter <ubyte>))]
  (test-equal "handle lack of support for 8-bit conditional move"
    (list (SUB RSP 8) (MOV DL AL) (CMP DL SIL) (JNBE #x3) (MOV DL SIL) (ADD RSP 8) (RET))
    (resolve-jumps (jit-compile (attach (flatten-code ((term (max a b)) r)) (RET))))))
(test-equal "get minor number of signed bytes"
  -1 ((jit ctx (list <byte> <byte>) min) -1 1))

(let [(a (parameter <int>))]
  (test-equal "Passing register parameters creates copy instructions"
    (MOV EDI (get (delegate a))) (car (pass-parameters (list a) (NOP)))))
(let [(args (map parameter (make-list 7 <int>)))]
  (test-equal "Passing stack parameters pushes the parameters on the stack"
    (PUSH (get (delegate (list-ref args 6)))) (list-ref (pass-parameters args (NOP)) 6))
  (test-equal "Stack pointer gets corrected after stack parameters have been used"
    (ADD RSP #x08) (last (pass-parameters args (NOP)))))
(test-eq "Scheme objects are represented using unsigned 64-bit integers"
  <ulong> (typecode (var <obj>)))
(let [(o (skeleton <obj>))]
  (test-assert "skeleton of top object is of type obj"
    (is-a? o <obj>))
  (test-assert "value of object skeleton is a variable"
    (is-a? (value o) <var>))
  (test-eq "value of object skeleton is of type unsigned long integer"
    <ulong> (typecode (value o))))
(test-assert "do not decompose variables"
  (is-a? (car (content <obj> (var <long>))) <var>))
(test-eq "compile and run identity function accepting Scheme object"
  'symbol ((jit ctx (list <obj>) identity) 'symbol))
(test-eq "make sure \"content\" enforces SCM object arguments"
  42 ((jit ctx (list <obj>) identity) 42))
(test-eq "negation of Scheme object"
  -300 ((jit ctx (list <obj>) -) 300))
(test-eq "bitwise logical not using Scheme objects"
  -124 ((jit ctx (list <obj>) ~) 123))
(test-equal "comparison of Scheme object with zero"
  '(#f #t) (map (jit ctx (list <obj>) =0) '(3 0)))
(test-equal "Scheme object not equal to zero"
  '(#t #f) (map (jit ctx (list <obj>) !=0) '(3 0)))
(test-equal "compiled logical not for Scheme objects"
  '(#t #f #f #f #f) (map (jit ctx (list <obj>) !) '(#f #t () 0 1)))
(test-eq "compiled plus operation using Scheme objects"
  300 ((jit ctx (list <obj> <obj>) +) 100 200))
(test-eq "compiled unary plus using Scheme objects"
  300 ((jit ctx (list <obj>) +) 300))
(test-eq "compiled minus operation using Scheme objects"
  100 ((jit ctx (list <obj> <obj>) -) 300 200))
(test-eq "compiled multiplication using Scheme objects"
  600 ((jit ctx (list <obj> <obj>) *) 20 30))
(test-eq "compiled division using Scheme objects"
  5 ((jit ctx (list <obj> <obj>) /) 15 3))
(test-eq "compiled modulo using Scheme objects"
  33 ((jit ctx (list <obj> <obj>) %) 123 45))
(test-eq "bitwise and using Scheme objects"
  72 ((jit ctx (list <obj> <obj>) &) 123 456))
(test-eq "bitwise or using Scheme objects"
  507 ((jit ctx (list <obj> <obj>) |) 123 456))
(test-eq "bitwise exclusive-or using Scheme objects"
  435 ((jit ctx (list <obj> <obj>) ^) 123 456))
(test-equal "logical and for Scheme objects"
  '(#f b) (map (jit ctx (list <obj> <obj>) &&) '(#f a) '(b b)))
(test-equal "logical or for Scheme objects"
  '(b a) (map (jit ctx (list <obj> <obj>) ||) '(#f a) '(b b)))
(test-eq "compiled minimum using Scheme objects"
  123 ((jit ctx (list <obj> <obj>) min) 123 456))
(test-eq "compiled maximum using Scheme objects"
  456 ((jit ctx (list <obj> <obj>) max) 123 456))
(test-eq "compiled shift-left using Scheme objects"
  1968 ((jit ctx (list <obj> <obj>) <<) 123 4))
(test-eq "compiled shift-right using Scheme objects"
  123 ((jit ctx (list <obj> <obj>) >>) 1968 4))
(test-equal "compiled equal comparison of Scheme objects"
  (list #f #t) (map (jit ctx (list <obj> <obj>) =) '(21 42) '(42 42)))
(test-equal "compiled unequal comparison of Scheme objects"
  (list #t #f) (map (jit ctx (list <obj> <obj>) !=) '(21 42) '(42 42)))
(test-equal "compiled lower-than comparison for Scheme objects"
  (list #t #f #f) (map (jit ctx (list <obj> <obj>) <) '(3 5 7) '(5 5 5)))
(test-equal "compiled lower-equal comparison for Scheme objects"
  (list #t #t #f) (map (jit ctx (list <obj> <obj>) <=) '(3 5 7) '(5 5 5)))
(test-equal "compiled greater-than comparison for Scheme objects"
  (list #f #f #t) (map (jit ctx (list <obj> <obj>) >) '(3 5 7) '(5 5 5)))
(test-equal "compiled greater-equal comparison for Scheme objects"
  (list #f #t #t) (map (jit ctx (list <obj> <obj>) >=) '(3 5 7) '(5 5 5)))
(test-eq "convert Scheme object to integer in compiled code"
  42 ((jit ctx (list <obj>) (cut to-type <int> <>)) 42))
(test-equal "compile and run identity function for sequence of objects"
  '(2 3 5) (to-list ((jit ctx (list (sequence <obj>)) identity) (seq <obj> 2 3 5))))
(test-equal "dereference pointer when doing bitwise negation"
  '(-3 -4 -6) (to-list ((jit ctx (list (sequence <obj>)) ~) (seq <obj> 2 3 5))))
(test-equal "convert unsigned byte to boolean"
  '(#f #t) (map (jit ctx (list <ubyte>) (cut to-type <bool> <>)) '(0 1)))
(test-equal "convert integer to boolean"
  '(#f #t) (map (jit ctx (list <int>) (cut to-type <bool> <>)) '(0 1)))
(test-equal "convert boolean to unsigned byte"
  '(0 1) (map (jit ctx (list <bool>) (cut to-type <ubyte> <>)) '(#f #t)))
(test-eqv "convert integer to object"
  42 ((jit ctx (list <int>) (cut to-type <obj> <>)) 42))
(test-equal "convert object to boolean"
  '(#f #t) (map (jit ctx (list <obj>) (cut to-type <bool> <>)) '(#f #t)))
(test-equal "convert boolean to object"
  '(#f #t) (map (jit ctx (list <bool>) (cut to-type <obj> <>)) '(#f #t)))
(test-equal "convert integer RGB sequence to object RGB sequence"
  (list (rgb 2 3 5)) (to-list (to-type (rgb <obj>) (seq (rgb 2 3 5)))))
(test-equal "convert object RGB sequence to integer RGB sequence"
  (list (rgb 2 3 5)) (to-list (to-type (rgb <int>) (seq (rgb <obj>) (rgb 2 3 5)))))
(test-eqv "plus for object and integer"
  7 ((jit ctx (list <obj> <int>) +) 3 4))
(test-eqv "plus for integer and object"
  7 ((jit ctx (list <int> <obj>) +) 3 4))

(test-equal "generate code to package an object in a list"
  '(a) ((jit ctx (list <obj>) package-return-content) 'a))
(test-equal "generate code to return the content of an RGB value"
  '(2 3 5) ((jit ctx (list <intrgb>) package-return-content) (rgb 2 3 5)))
(test-equal "build a list of values in compiled code"
  '(2 3 5) ((jit ctx (list <int> <int> <int>) build-list) 2 3 5))
(let [(i (skeleton <int>))]
  (test-equal "generate code create, define, and package return value"
    '(123)
    (address->scm ((asm ctx <long> (list <int>)
                        (apply virtual-variables (apply assemble (generate-return-code (list i)
                                                        (parameter <int>) (parameter i)))))
                   123))))
(test-eqv "get dimension of sequence"
  3 ((jit ctx (list (sequence <ubyte>)) dimension) (seq 2 3 5)))
(test-eqv "get stride of sequence"
  1 ((jit ctx (list (sequence <ubyte>)) stride) (seq 2 3 5)))
(test-eqv "number multiplied with nothing returns same number"
  5 ((jit ctx (list <int>) *) 5))
(test-equal "sequence multiplied with nothing returns same sequence"
  '(2 3 5) (to-list (* (seq 2 3 5))))
(test-eqv "determine size of integer in compiled code"
  2 ((jit ctx (list <sint>) size-of) 42))
(test-eqv "determine size of sequence (compiled)"
  6 ((jit ctx (list (sequence <sint>)) size-of) (seq <sint> 2 3 5)))
(let [(i (parameter <int>))]
  (test-eqv "assign native integer constant to parameter"
    42 ((asm ctx <int> '() (apply virtual-variables (assemble (list (delegate i)) '() (code i 42)))))))
(test-assert "compile function returning empty list"
  (null? ((jit ctx '() (lambda () scm-eol)))))
(test-equal "call \"cons\" from compiled code"
  (cons 'a 'b) ((jit ctx (list <obj> <obj>) scm-cons) 'a 'b))
(test-equal "compile function putting object into a one-element list"
  '(a) ((jit ctx (list <obj>) (cut scm-cons <> scm-eol)) 'a))
(test-equal "compile function putting integer into a one-element list"
  '(42) ((jit ctx (list <int>) (cut scm-cons <> scm-eol)) 42))
(test-equal "compile function putting result of expression into a one-element list"
  '(170) ((jit ctx (list <int> <int>) (lambda (i j) (scm-cons (+ i j) scm-eol))) 100 70))
(test-assert "allocate memory in compiled method"
  ((jit ctx (list <ulong>) scm-gc-malloc-pointerless) 128))
(test-assert "allocate memory in compiled method"
  ((jit ctx (list <ulong>) scm-gc-malloc) 128))

(test-begin "list operations")
  (test-assert "+ is an operation"
    (memv '+ operations))
  (test-assert "- is an operation"
    (memv '- operations))
  (test-assert "* is an operation"
    (memv '* operations))
(test-end "list operations")
(test-end "aiscm jit3")
