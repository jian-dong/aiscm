(use-modules (aiscm util)
             (guile-tap))
(planned-tests 11)
(toplevel-define! 'a 0)
(def-once "x" 1)
(def-once "x" 2)
(ok (eqv? 0 a)
    "'toplevel-define! should create a definition for the given symbol")
(ok (eqv? 1 x)
    "'def-once' should only create a definition once")
(ok (not (index 4 '(2 3 5 7)))
    "'index' returns #f if value is not element of list")
(ok (eqv? 2 (index 5 '(2 3 5 7)))
    "'index' returns index of first matching list element")
(ok (equal? '(1 2 3 4 5) (upto 1 5))
    "'upto should create a sequence of numbers")
(ok (eqv? 0 (depth 'a))
    "Depth of a symbol is zero")
(ok (eqv? 1 (depth '(a b)))
    "Depth of a list is one")
(ok (eqv? 2 (depth '(a (b) c)))
    "Depth of a list containing a list is two")
(ok (equal? '((a) (b) (c)) (flatten-n '(((a) (b)) ((c))) 2))
    "'flatten-n' can merge lists to a depth of two")
(ok (equal? '(a b c) (flatten-n '(((a) (b)) ((c))) 1))
    "'flatten-n' can merge lists to a depth of one")
(ok (equal? '((a) (b) (c)) (flatten-n '((((a)) (b)) ((c))) 2))
    "'flatten-n' preferably merges outer lists")
(format #t "~&")
