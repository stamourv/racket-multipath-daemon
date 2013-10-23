#lang racket/base
;
; Multipath Daemon API
;

(require racket/contract
         racket/string
         racket/format
         racket/class
         unstable/socket)

(provide multipath-daemon%
         multipath-daemon/c)


;; Default according to multipath-tools source as of 2013-10-21.
(define DEFAULT-PATH #"\0/org/kernel/linux/storage/multipathd")


(define multipath-daemon/c
  (class/c
    [init-field [path unix-socket-path?]]

    [reconfigure     (->m boolean?)]
    [list-paths      (->m (listof (hash/c symbol? any/c)))]
    [list-multipaths (->m (listof (hash/c symbol? any/c)))]))


(define/contract multipath-daemon%
                 multipath-daemon/c
  (class object%
    (init-field [path DEFAULT-PATH])

    (define-values (in out)
      (unix-socket-connect path))


    (define/private (read-integer)
      (integer-bytes->integer (read-bytes 8 in) #f (system-big-endian?)))

    (define/private (write-integer i)
      (write-bytes (integer->integer-bytes i 8 #f (system-big-endian?)) out))

    (define/private (command . command)
      (let ([bstr (string->bytes/utf-8 (string-join (map ~s command) " "))])
        (write-integer (bytes-length bstr))
        (write-bytes bstr out)
        (flush-output out))
      (let ([lines (string-split
                     (bytes->string/utf-8
                       (read-bytes (sub1 (read-integer)) in))
                     "\n")])
        (read-byte in)
        (let ([result-lines (map string-trim lines)])
          (case result-lines
            [(("ok"))  #t]
            [(())      null]
            [else      (cdr result-lines)]))))


    (define/public (reconfigure)
      (and (command "reconfigure") #t))

    (define/public (list-paths)
      (for/list ([line (command "list" "paths" "format" "%d %D %o %w")])
        (let-values ([(device major minor status uuid)
                      (apply values (regexp-split #rx"[ \t:]+" line))])
          (hasheq 'device device
                  'major (string->number major)
                  'minor (string->number minor)
                  'status (string->symbol status)
                  'uuid uuid))))

    (define/public (list-multipaths)
      (for/list ([line (command "list" "multipaths")])
        (let-values ([(name device uuid)
                      (apply values (regexp-split #rx"[ \t:]+" line))])
          (hasheq 'device device
                  'name name
                  'uuid uuid))))

    (super-new)))


; vim:set ts=2 sw=2 et:
