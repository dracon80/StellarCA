#!/bin/sh

if [ "$1" = 'stellarca' ]; then
    #Check that config.yaml exists
    if [ ! -e "config.yaml" ]; then
        echo -e "config.yaml not found."
        echo -e "config.yaml is required to complete configuration of CA"
        echo -e "\e[31mExiting script!\e[0m"
        exit 1
    fi

    #Make all these variables env variables
    set -o allexport

    # Run yq to extract the config data supplied
    openssl_name=$(yq '.openssl.name' config.yaml)
    openssl_certBaseFileName=$(yq '.openssl.certBaseFileName' config.yaml)
    openssl_ocspBaseURL=$(yq '.openssl.ocspBaseURL' config.yaml)
    openssl_aiaBaseURL=$(yq '.openssl.aiaBaseURL' config.yaml)
    openssl_crlBaseURL=$(yq '.openssl.crlBaseURL' config.yaml)
    openssl_country=$(yq '.openssl.country' config.yaml)
    openssl_organizationName=$(yq '.openssl.organizationName' config.yaml)
    openssl_organizationUnit=$(yq '.openssl.organizationUnit' config.yaml)
    openssl_state=$(yq '.openssl.state' config.yaml)
    openssl_location=$(yq '.openssl.location' config.yaml)
    openssl_lifeTimeDays=$(yq '.openssl.lifeTimeDays' config.yaml)
    openssl_defaultDays=$(yq '.openssl.defaultDays' config.yaml)

    #Turn off the auto export of variables
    set +o allexport

    ######Static Config paths######
    ca_etc_path=/etc/ca
    conf_path=$ca_etc_path/config
    public_path=$ca_etc_path/certs                      # Self Signed Certificate, or certificate for parent.
    private_path=$ca_etc_path/private                   # Private Certificates for this CA
    passwords_path=$ca_etc_path/passwords               # Plain text files with passwords to decrypt private certs
    ######Static Config Files######
    conf_file=$conf_path/openssl.conf
    ca_password_file=$passwords_path/ca_password
    crl_password_file=$passwords_path/crl_password
    ocsp_password_file=$passwords_path/ocsp_password
    ######Working folders for new Certificates######
    ca_var_path=/var/ca
    csr_path=$ca_var_path/csr
    newcerts_path=$ca_var_path/certs
    db_path=$ca_var_path/db
    ######Kubernetes Config Map and Secrets######
    openssl_configmap=$openssl_certBaseFileName-configmap
    passwords_secret=$openssl_certBaseFileName-passwords
    certs_secret=$openssl_certBaseFileName-certs
    ######Shared Web distributing CRL and CRT######
    web_path=/var/www/html

    ####################################################################
    ## Begin Script
    ####################################################################
    #Create the required folders.
    mkdir -p $conf_path
    mkdir -p $public_path
    mkdir -p $private_path
    mkdir -p $passwords_path
    mkdir -p $csr_path
    mkdir -p $newcerts_path
    mkdir -p $db_path
    mkdir -p $web_path

    #Create random seed data
    dd if=/dev/urandom of=$ca_etc_path/random bs=256 count=1 status=none

    #Confirm the random data was created
    if [ ! -e "$ca_etc_path/random" ]; then
        echo -e "\nFailed to create random seed data file!"
        echo -e "\e[31mFatal Error\e[0m"
        exit 1
    fi

    #Check for openssl config file in configmap, and if present use it, otherwise create a new file one from template and create a configmap in kubernetes.
    if kubectl get configmap "$openssl_configmap" >/dev/null 2>&1; then
        echo -e "\e[32m----------------------------------------------------------------------------\e[0m"
        echo -e "\e[32m---\e[0m Using existing configmap $openssl_configmap"
        echo -e "\e[32m----------------------------------------------------------------------------\e[0m"

        kubectl get configmap $openssl_configmap -o jsonpath='{.data.openssl\.conf}' > $conf_file
    else
        echo -e "\n\e[36m----------------------------------------------------------------------------\e[0m"
        echo -e "\e[36m---\e[0m Creating a new Config file for $openssl_name"
        echo -e "\e[36m----------------------------------------------------------------------------\e[0m"

        echo -e "replacing tokens in openssl.conf template with values from config.yaml"

        #Create the openssl config file by substituting any place holders with Environment variables
        envsubst '$openssl_name,$openssl_certBaseFileName,$openssl_ocspBaseURL,$openssl_aiaBaseURL,$openssl_crlBaseURL,
        $openssl_country,$openssl_organizationName,$openssl_organizationUnit,$openssl_state,$openssl_location,
        $openssl_lifeTimeDays,$openssl_defaultDays' < "$(pwd)/openssl.conf" > "$conf_file"

        if [ ! -s "$conf_file" ]; then
            echo -e "\nFailed to generate openssl configuration $conf"
            echo -e "\e[31mFatal Error\e[0m"
            exit 1
        else
            echo -e "$conf_file successfully created"
        fi

        #upload the newly created openssl.conf file into the configmap
        kubectl create configmap $openssl_configmap --from-file=$conf_path
    fi

    #Check for secrets and use them if present, else create new ones an save to kubernetes.
    if kubectl get secret $passwords_secret >/dev/null 2>&1; then
        echo -e "\e[32m----------------------------------------------------------------------------\e[0m"
        echo -e "\e[32m---\e[0m Using private key passwords found in secret $passwords_secret"
        echo -e "\e[32m----------------------------------------------------------------------------\e[0m"

        echo $(kubectl get secret $passwords_secret -o jsonpath='{.data.ca_password}' | base64 -d) > $ca_password_file
        echo $(kubectl get secret $passwords_secret -o jsonpath='{.data.crl_password}' | base64 -d) > $crl_password_file
        echo $(kubectl get secret $passwords_secret -o jsonpath='{.data.ocsp_password}' | base64 -d) > $ocsp_password_file

    else
        echo -e "\n\e[36m----------------------------------------------------------------------------\e[0m"
        echo -e "\e[36m---\e[0m Generating random passwords"
        echo -e "\e[36m----------------------------------------------------------------------------\e[0m"

        #Create the CA key passwords to be used
        echo $(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32 ; echo '') > $ca_password_file
        echo $(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32 ; echo '') > $crl_password_file
        echo $(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 32 ; echo '') > $ocsp_password_file

        if [ ! -s "$ca_password_file" ]; then
            echo -e "\nFailed to generate random password!"
            echo -e "\e[31mFatal Error\e[0m"
            exit 1
        fi
        if [ ! -s "$crl_password_file" ]; then
            echo -e "\nFailed to generate random crl signing password!"
            echo -e "\e[31mFatal Error\e[0m"
            exit 1
        fi
        if [ ! -s "$ocsp_password_file" ]; then
            echo -e "\nFailed to generate random ocsp signing password!"
            echo -e "\e[31mFatal Error\e[0m"
            exit 1
        fi

        #create the Kubernetes Secrets from the generated password files
        echo -e "\nSaving random passwords in kubernetes secret!"
        kubectl create secret generic $passwords_secret --from-file=$passwords_path --type=ca-passwords
    fi

    #Check for existing Certificates (CA, CRL, OSCP) and load them, otherwise create a self signed certificate along with CRL and OSCP. Then save to kubernetes.
    if kubectl get secret $certs_secret >/dev/null 2>&1; then
        echo -e "\e[32m----------------------------------------------------------------------------\e[0m"
        echo -e "\e[32m---\e[0m Using Certificates found in $certs_secret"
        echo -e "\e[32m----------------------------------------------------------------------------\e[0m"

        # Get all keys in the secret. There should be a *.key and *.crt pair for each certificate
        certs=$(kubectl get secret $certs_secret -o jsonpath="{.data}" | yq eval 'keys | .[]' -)

        # Iterate through the private and public certs and create a file for each
        for cert in $certs; do
            #escape the dot in the filename
            key=$(echo "$cert" | sed 's/\./\\./g')

            if echo "$cert" | grep -qE '\.key$'; then
                # Get the value for the private certificate
                value=$(kubectl get secret $certs_secret -o jsonpath="{.data.$key}" | base64 -d)

                # Create a private key for the certificate
                echo "$value" > "$private_path/$cert"
            fi

            if echo "$cert" | grep -qE '\.crt$'; then
                # Get the value for the public certificate
                value=$(kubectl get secret $certs_secret -o jsonpath="{.data.$key}" | base64 -d)

                # Create a private key for the certificate
                echo "$value" > "$public_path/$cert"

                #Copy certs to web distrubution
                echo -e "Publishing $cert to web server"
                cp -f "$public_path/$cert" "$web_path/"
            fi
        done

    else
        echo -e "\e[36m----------------------------------------------------------------------------\e[0m"
        echo -e "\e[36m---\e[0m Generating a new self signed certificate for $openssl_name"
        echo -e "\e[36m----------------------------------------------------------------------------\e[0m"

        #Create the required files to operate as a CA.
        echo "Creating Certificate Authority text database file"
        rm -f $db_path/index
        touch $db_path/index

        echo "Creating Certificate Authority serial file"
        rm -f $db_path/serial
        openssl rand -hex 16  > $db_path/serial

        #Confirm that the above files were actually created.
        if [ ! -e "$db_path/index" ]; then
            echo -e "\nFailed to create text database file!"
            echo -e "\e[31mFatal Error\e[0m"
            exit 1
        fi
        if [ ! -e "$db_path/serial" ]; then
            echo -e "\nFailed to create random database serial!"
            echo -e "\e[31mFatal Error\e[0m"
            exit 1
        fi

        #Define file names for certificates
        private_cert_file="$private_path/$openssl_certBaseFileName.key"
        public_cert_file="$public_path/$openssl_certBaseFileName.crt"
        csr_file="$csr_path/$openssl_certBaseFileName.csr"

        echo -e "Generating 4096 bit Certificate Signing Request"
        #Create the self signed root CA certificate
        openssl req -new -config $conf_file -newkey rsa:4096 \
            -subj "/C=$openssl_country/ST=$openssl_state/L=$openssl_location/O=$openssl_organizationName/OU=$openssl_organizationUnit/CN=$openssl_name" \
            -out $csr_file \
            -keyout $private_cert_file \
            -passout file:$ca_password_file

        echo -e "\e[36m----------------------------------------------------------------------------\e[0m"
        echo -e "\e[36m---\e[0m Self Signing CSR"
        echo -e "\e[36m----------------------------------------------------------------------------\e[0m"
        
        openssl ca -selfsign -config $conf_file -in $csr_file -out $public_cert_file \
            -extensions root_ca_ext -passin file:$ca_password_file -days $openssl_lifeTimeDays -batch

        #check that the self signed certificate was created and exists.
        if [ ! -s "$public_cert_file" ]; then
            echo -e "\nFailed to succesfully generate a self signed root certificate"
            echo -e "\e[31mFatal Error\e[0m"
            exit 1
        else
            #copy the certificate into the shared web folder so it can be served up by the web server
            echo -e "Publishing CA Certificate"
            cp -f "$public_cert_file" "$web_path/"
        fi

        echo -e "\e[36m----------------------------------------------------------------------------\e[0m"
        echo -e "\e[36m---\e[0m Generating OCSP signing certificate for $openssl_name"
        echo -e "\e[36m----------------------------------------------------------------------------\e[0m"

        #Define file names for certificates
        private_cert_file="$private_path/$openssl_certBaseFileName-ocsp.key"
        public_cert_file="$public_path/$openssl_certBaseFileName-ocsp.crt"
        csr_file="$csr_path/$openssl_certBaseFileName-ocsp.csr"

        echo -e "Generating 4096 bit Certificate Signing Request"
        openssl req -new -config $conf_file -newkey rsa:4096 \
            -subj "/C=$openssl_country/ST=$openssl_state/L=$openssl_location/O=$openssl_organizationName/OU=$openssl_organizationUnit/CN=$openssl_name OCSP Responder" \
            -keyout $private_cert_file \
            -out $csr_file \
            -passout file:$ocsp_password_file

        openssl ca -config $conf_file -in $csr_file -out $public_cert_file \
            -extensions ocsp_ext -passin file:$ca_password_file -days $openssl_lifeTimeDays -batch

        #check that the self signed certificate was created and exists.
        if [ ! -s "$public_cert_file" ]; then
            echo -e "Failed to generate a ocsp signing certificate"
            echo -e "\e[31mFatal Error\e[0m"
            exit 1
        else
            #copy the certificate into the shared web folder so it can be served up by the web server
            echo -e "Publishing OCSP Certificate"
            cp -f "$public_cert_file" "$web_path/"
        fi

        echo -e "\e[36m----------------------------------------------------------------------------\e[0m"
        echo -e "\e[36m---\e[0m Generating CRL signing certificate for $openssl_name"
        echo -e "\e[36m----------------------------------------------------------------------------\e[0m"

        #Define file names for certificates
        private_cert_file="$private_path/$openssl_certBaseFileName-crl.key"
        public_cert_file="$public_path/$openssl_certBaseFileName-crl.crt"
        csr_file="$csr_path/$openssl_certBaseFileName-crl.csr"

        echo -e "Generating 4096 bit Certificate Signing Request"

        openssl req -new -config $conf_file -newkey rsa:4096 \
            -subj "/C=$openssl_country/ST=$openssl_state/L=$openssl_location/O=$openssl_organizationName/OU=$openssl_organizationUnit/CN=$openssl_name CRL Signer" \
            -keyout $private_cert_file \
            -out $csr_file \
            -passout file:$crl_password_file

        openssl ca -config $conf_file -in $csr_file -out $public_cert_file \
            -extensions crl_ext -passin file:$ca_password_file -days $openssl_lifeTimeDays -batch

        #check that the self signed certificate was created and exists.
        if [ ! -s "$public_cert_file" ]; then
            echo -e "Failed to generate a ocsp signing certificate"
            echo -e "\e[31mFatal Error\e[0m"
            exit 1
        else
            #copy the certificate into the shared web folder so it can be served up by the web server
            echo -e "Publishing CRL Certificate"
            cp -f "$public_cert_file" "$web_path/"
        fi

        # Create YAML file for private key files
        kubectl create secret generic --type="ca-certs" "$certs_secret" --from-file=$private_path --dry-run=client -o yaml > "$(pwd)/tmp/private.yaml"
        # Create YAML file for certificate files
        kubectl create secret generic --type="ca-certs" "$certs_secret" --from-file=$public_path --dry-run=client -o yaml > "$(pwd)/tmp/cert.yaml"
        #merge the 2 yaml files
        yq ". *= load(\"$(pwd)/tmp/cert.yaml\")" "$(pwd)/tmp/private.yaml" > "$(pwd)/tmp/secret.yaml"

        # Apply the merged YAML file to create or update the secret
        kubectl apply -f tmp/secret.yaml

        # Clean up temporary files
        rm "tmp/private.yaml" "tmp/cert.yaml" "tmp/secret.yaml"

    fi

    #Update the CRL using the current text database
    echo -e "\e[32m----------------------------------------------------------------------------\e[0m"
    echo -e "\e[32m---\e[0m Updating CRL for $openssl_name"
    echo -e "\e[32m----------------------------------------------------------------------------\e[0m"
    openssl ca -gencrl -config $conf_file \
        -cert $public_path/$openssl_certBaseFileName-crl.crt \
        -keyfile $private_path/$openssl_certBaseFileName-crl.key \
        -passin file:$crl_password_file \
        -out $web_path/$openssl_certBaseFileName.crl

    #Finally run openssl OCSP responder server.
    echo -e "\e[32m----------------------------------------------------------------------------\e[0m"
    echo -e "\e[32m---\e[0m Starting OCSP Responder on $openssl_ocspBaseURL"
    echo -e "\e[32m----------------------------------------------------------------------------\e[0m"

    exec openssl ocsp -index $db_path/index \
        -port 9801 \
        -rsigner $public_path/$openssl_certBaseFileName-ocsp.crt \
        -rkey $private_path/$openssl_certBaseFileName-ocsp.key \
        -passin file:$ocsp_password_file \
        -CA $public_path/$openssl_certBaseFileName.crt
fi

#Another command is being exec in the container
exec "$@"