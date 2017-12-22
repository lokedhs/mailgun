(asdf:defsystem #:mailgun
  :description "Mailgun client"
  :license "Apache"
  :serial t
  :depends-on (:alexandria
               :drakma
               :st-json)
  :components ((:module "src"
                        :serial t
                        :components ((:file "package")
                                     (:file "mailgun")))))
