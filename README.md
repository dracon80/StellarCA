# Stellar Certificate Authority

Stellar Certificate Authority is a simply collection of shell script and kubernetes definitions to help deploy a root certificate authority and subordinate certificate authorities in Kubernetes.

Openssl is used as the Certificate Authority and OCSP responder and a shared nginx web server to distribute the generated certificate chains, and CRL files for each of the Certificate Authorities.

## Kubernetes

Instructions for deploying the solution to kubernetes are available for the [Web Server](./kubernetes/web/README.md) and [Certificate Server](./kubernetes/certificate-authority/README.md).

## Configuration File - _stellar-config.yaml_

The configuration is made by editing a [stellar-config.yaml](./stellarca/stellar-config.yaml) file and mounting it at _/app/stellar-config.yaml_ in the deployed image. The stellar-config yaml file has a [json schema available](./stellarca/stellar-schema.json) to help you edit the file and make sure you have valid settings.

The properties available in the yaml file are;

### Yaml Schema

The schema **does not** accept any additional properties.

**_Properties_**

**configVersion** `required`

- _Type_: `integer`
- _Default_: `1`
- _Range_: between 1 and 1
- _Description_: The configuration version is used by Stellar CA to validate the configuration values in the yaml configuration as newer versions become available

---
**openssl** `required`

- _Type_: `object`
- _Description_: Settings related to configuring openssl are all contained in this yaml key.

  ---
  **name** `required`

  - _Type_: `string`
  - _Description_: A name that will be used when creating a certificate for this Certificate Authority. This will be the name that the CA is known as when looking at the issued by field on certificates the CA issues.

  ---
  **certBaseFileName** `required`

  - _Type_: `string`
  - _Minimum Length_: `2`
  - _Description_: All certificates generated related directly to this CA will use this value as a base file name

  ---
  **ocspBaseURL** `required`

  - _Type_: `string`
  - _Description_: The base URL, including protocol that the ocsp will be available at. e.g <http://ocsp.example.com:9002/> or <http://ocsp.example.com/>

  ---

  **aiaBaseURL** `required`
  - _Type_: `string`
  - _Description_: The base URL, including protocol that the CA certificate will be available from. For example <http://pki.example.com/> or <http://pki.example.com:8080/> . Please note that a certificate file with a name based on certBaseFileName will be appended to the end of this URL

  ---

  **crlBaseURL** `required`
  - _Type_: `string`
  - _Description_: The base URL, including protocol that the CRL will be available from. For example <http://pki.example.com/> or <http://pki.example.com:8080/> . Please note that a CRL file with a name based on certBaseFileName will be appended to the end of this URL",

  ---

  **country** `required`
  - _Type_: `string`
  - _Minimum Length_: `2`
  - _Maximum Length_: `2`
  - _Description_: The 2 letter alpha code for the country the CA is running in

  ---

  **organizationName** `required`
  - _Type_: `string`
  - _Description_: The name of the organization that is running the Certificate Authority

  ---

  **organizationUnit** `required`
  - _Type_: `string`
  - _Description_: The name of the organizational unit that is responsible for running the Certificate Authority

  ---

  **state** `required`
  - _Type_: `string`
  - _Description_: The name of the state that the Certificate Authority is located in

  ---

  **location** `required`
  - _Type_: `string`
  - _Description_: The name of the city, town or general location that is Certificate Authority is located

  ---

  **lifeTimeDays** `required`
  - _Type_: `int`
  - _Description_: The number of days from the date of creation that the Certificate for the CA will be valid

  ---

  **defaultDays** `required`
  - _Type_: `int`
  - _Default_: `731`
  - _Description_: The default number of days a newly created certificate will be valid for
