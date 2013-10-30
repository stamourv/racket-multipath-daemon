#lang racket/base
;
; Multipath Daemon API
;

(require racket/contract
         racket/string
         racket/format
         racket/class
         unstable/socket
         unstable/error)

(provide multipath-daemon%
         multipath-daemon/c)


;; Default according to multipath-tools source as of 2013-10-21.
(define DEFAULT-PATH #"\0/org/kernel/linux/storage/multipathd")


(define multipath-daemon/c
  (class/c
    [init-field [path unix-socket-path?]]

    [list-paths           (->m (listof (hash/c symbol? any/c)))]
    [list-maps            (->m (listof (hash/c symbol? any/c)))]
    [reconfigure          (->m boolean?)]
    [add-path             (->m string? void?)]
    [remove-path          (->m string? void?)]
    [add-map              (->m string? void?)]
    [remove-map           (->m string? void?)]
    [suspend-map          (->m string? void?)]
    [resume-map           (->m string? void?)]
    [resize-map           (->m string? void?)]
    [reset-map            (->m string? void?)]
    [reload-map           (->m string? void?)]
    [fail-path            (->m string? void?)]
    [reinstate-path       (->m string? void?)]
    [disable-map-queuing  (->m string? void?)]
    [disable-queuing      (->m void?)]
    [restore-map-queuing  (->m string? void?)]
    [restore-queuing      (->m void?)]))

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
            [(("ok"))
             (void)]

            [(("fail"))
             (error* 'multipath-daemon
                     "remote command failed"
                     '("command" value) command)]

            [(())
             null]

            [else
             (cdr result-lines)]))))

    (define/public (list-paths)
      (for/list ([line (command "list" "paths" "format" "%d %D %o %w")])
        (let*-values ([(device devno status uuid)
                       (apply values (regexp-split #rx"[ \t]+" line))]
                      [(major minor)
                       (apply values (string-split devno ":"))])
          (hasheq 'device device
                  'major (string->number major)
                  'minor (string->number minor)
                  'status (string->symbol status)
                  'uuid uuid))))

    (define/public (list-maps)
      (for/list ([line (command "list" "maps")])
        (let-values ([(name device uuid)
                      (apply values (regexp-split #rx"[ \t]+" line))])
          (hasheq 'device device
                  'name name
                  'uuid uuid))))

    (define/public (reconfigure)
      (void (command "reconfigure")))

    (define/public (add-path path)
      (void (command "add" "path" path)))

    (define/public (remove-path path)
      (void (command "remove" "path" path)))

    (define/public (add-map map)
      (void (command "add" "map" map)))

    (define/public (remove-map map)
      (void (command "remove" "map" map)))

    (define/public (suspend-map map)
      (void (command "suspend" "map" map)))

    (define/public (resume-map map)
      (void (command "resume" "map" map)))

    (define/public (resize-map map)
      (void (command "resize" "map" map)))

    (define/public (reset-map map)
      (void (command "reset" "map" map)))

    (define/public (reload-map map)
      (void (command "reload" "map" map)))

    (define/public (fail-path path)
      (void (command "fail" "path" path)))

    (define/public (reinstate-path path)
      (void (command "reinstate" "path" path)))

    (define/public (disable-map-queuing map)
      (void (command "disablequeueing" "map" map)))

    (define/public (disable-queuing)
      (void (command "disablequeueing" "maps")))

    (define/public (restore-map-queuing map)
      (void (command "restorequeueing" "map" map)))

    (define/public (restore-queuing)
      (void (command "restorequeueing" "maps")))

    (super-new)))


; vim:set ts=2 sw=2 et:
