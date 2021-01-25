













openssl x509 -in minikube.test.pem -text

C=US, ST=MA, L=Beverly, O=Me, OU=Engineering, CN=minikube.test/emailAddress=foo@bar.com





SSL_SUBJECT="/C=US/ST=MA/L=Beverly/O=Me/OU=Engineering/CN=minikube.test/emailAddress=foo@bar.com"

openssl req -x509 -new -nodes -key minikube.test.key -reqexts v3_req -extensions v3_ca -config ../../conf/ssl/openssl.conf -sha256 -days 1825 -out minikube.test.pem -subj "/C=US/ST=MA/L=Beverly/O=Me/OU=Engineering/CN=minikube.test/emailAddress=foo@bar.com"
