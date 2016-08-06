(use-modules (guile-tap))
(load-extension "libguile-aiscm-tests" "init_tests")
(ok (eqv? 42 (forty-two))
    "Run simple native method")
(ok (null? (from-array-empty))
    "Convert empty integer array to Scheme array")
(ok (equal? '(2 3 5) (from-array-three-elements))
    "Convert integer array with three elements to Scheme array")
(ok (equal? '(2 3 5) (from-array-stop-at-zero))
    "Convert integer array to Scheme array stopping at first zero element")
(ok (equal? '(0) (from-array-at-least-one))
    "Convert zero array with minimum number of elements")
(ok (first-offset-is-zero)
    "First value of offset-array is zero")
(ok (second-offset-correct)
    "Second value of offset-array correct")
(ok (zero-offset-for-null-pointer)
    "Set offset values for null pointers to zero")
(ok (pack-byte-audio-sample)
    "Pack byte audio sample")
(ok (pack-byte-audio-samples)
    "Pack byte audio samples")
(ok (pack-short-int-audio-samples)
    "Pack short integer audio samples")
(ok (ringbuffer-fetch-empty)
    "Fetching from empty ring buffer should return no data")
(ok (ringbuffer-initial-size)
    "Ring buffer initial size is as specified")
(ok (ringbuffer-add-data)
    "Adding data to ring buffer sets fill")
(ok (ringbuffer-store-and-fetch)
    "Ring buffer should allow fetching stored data")
(ok (ringbuffer-store-appends-data)
    "Adding more data to ring buffer appends to it")
(ok (ringbuffer-fetch-limit)
    "Do not fetch more than the specified number of bytes")
(ok (ringbuffer-fetching-advances)
    "Fetching from ring buffer advances it")
(ok (ringbuffer-storing-respects-offset)
    "Storing to ring buffer should be aware of offset")
(ok (ringbuffer-wrap-around)
    "Ring buffer should wrap around")
(ok (ringbuffer-grow)
    "Ringbuffer should grow n size if required")
(run-tests)
