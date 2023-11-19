# Stellar Certificate Authority Kubernetes Deployment

Before deploying a Stellar Certificate Authority instance, you must first deploy the web server as it will create the shared pvc that all Certificate Authority certificates will be published too, along with the CRL files. See the [README](../web/README.md) file for the web server component.

## Deploy Root Certificate Authority

Once you have deployed the Web server you can deploy the first or root Certificate authority on your network by following these steps.

1. Make a copy of the example folder in the [overlays folder](./overlays/)
2. Modify the stellar-config.yaml file with your site specific details. There is a [yaml schema](../../stellarca/stellar-schema.json) file with details of what each field relates too for the yaml.
3. Modify the kustomization.yaml file with your preferred deployment details. The 3 fileds that should be modified are;
    - *namespace*: Set this to the kubernetes namespace you want to deploy too.
    - *namePrefix*: Set this to match the basefilename you provided in the stellar-config.yaml file with a trailing -
    - *stellar-ca-name*: Set this to match the name you gave your CA in stellar-config.yaml
4. Deploy the solution by running  `kubectl apply -k ./` from within the overlay folder you just created.

## Deploying a subordinate Certificate Authority

Once the root CA has been deployed you can issue certificates to a subordinate CA. Start by following the instructions in [Deploy Root Certificate Authority](#deploy-root-certificate-authority) to create a new Certificate Authority, **but do not complete step 4**.

1. Execute `kubectl exec -it PODNAME -- stellar subordinate --name="SUBORDINATE" --basename="BASEFILENAME"` to create new CA, CRL, and OCSP signing certificates.
    - *PODNAME*: Replace with the name of the root CA pod that has already been deployed.
    - *SUBORDINATE*: Replace with the "name" you used in the stellar-config.yaml file for this subordinate CA.
    - *BASEFILENAME*: Replace with the "certBaseFileName" you used in the stellar-config.yaml file for this subordinate.
2. Deploy the suboridinate by running  `kubectl apply -k ./` from within the overlay folder you just created for the new subordinate.
