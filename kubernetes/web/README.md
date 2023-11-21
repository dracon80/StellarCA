# Stellar Certificate Authority Web Server

The certificates created for each Certificate Authority are stored in a shared PVC and made available by this nginx deployment.
To help keep things simple this kubernetes deployment is stand alone to the CA components found in the certificate-authority [overlays folder](../certificate-authority/overlays/). However there is a dependency between the 2 components in that they all share a single pvc that contains all the Certificate Authority certificates. For this reason the web server deployment must be deployed first as it creates the shared PVC.

To deploy the web server, edit the kustomize.yaml file and set the namespace that you would like to use, this should match the name space that the CA components are deployed too.
Then execute `kubectl apply -k ./` while in the web folder.
