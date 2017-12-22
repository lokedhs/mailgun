(in-package :mailgun)

(defvar *server-url-prefix* "https://api.mailgun.net/v3/")

(defvar *user-domain* nil)
(defvar *api-key* nil)

(define-condition message-send-error (error)
  ((message :type string
            :initarg :message
            :reader message-send-error/message))
  (:report (lambda (condition stream)
             (format stream "Error sending email: ~a" (message-send-error/message condition)))))

(defun make-mailgun-url (user-domain path)
  (concatenate 'string
               *server-url-prefix*
               (if (alexandria:ends-with-subseq "/" *server-url-prefix*) "" "/")
               user-domain
               "/"
               path))

(defun format-addresses (addrs)
  (with-output-to-string (s)
    (loop
      for a in addrs
      for first = t then nil
      unless (stringp a)
        do (error "Destination address must be a string: ~s" a)
      unless first
        do (princ ", " s)
      do (princ a s))))

(defun send-message (from to subject &key
                                       (user-domain *user-domain*)
                                       (api-key *api-key*)
                                       cc bcc content html-content)
  (when (and (null content)
             (null html-content))
    (error "At least one of CONTENT and HTML-CONTENT must be specified"))
  (unless to
    (error "No recipients"))
  (multiple-value-bind (body code headers orig-url stream should-close reason)
        (drakma:http-request (make-mailgun-url user-domain "messages")
                        :method :post
                        :basic-authorization (list "api" api-key)
                        :parameters `(("from" . ,from)
                                      ("to" . ,(format-addresses to))
                                      ("subject" . ,subject)
                                      ,@(if cc `(("cc" . ,(format-addresses cc))))
                                      ,@(if bcc `(("bcc" . ,(format-addresses bcc))))
                                      ,@(if content `(("text" . ,content)))
                                      ,@(if html-content `(("html" . ,html-content)))))
    (declare (ignore headers orig-url stream should-close reason))
    (let ((json (st-json:read-json-from-string (babel:octets-to-string body :encoding :utf-8))))
      (unless (= code 200)
        (error 'message-send-error :message (st-json:getjso "message" json)))
      (list :id (st-json:getjso "id" json)))))
