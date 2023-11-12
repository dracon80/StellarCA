# Kubernetes Configuration Folder
The .k8s-example folder contains examples of the files that should be stored in a .k8s folder within the root of the workspace. These files are used during development and contain Kubernetes secrets, and environment files.  

Once you have cloned the repository you can rename this folder to .k8s and update each of the files with values that will work for your environment. Both the devcontainer and the docker build files reference files found with the .k8s folder.
## ca.crt
This is the root ca file that signs all the certificates your Kubernetes cluster uses.
## devcontainer.env
An environment file that contains both the hostname and port that the Kubernetes API is listening on.
## namespace
A plain text file that contains the namespace that stellar CA will run in under Kubernetes
## sa-token
This is a long lived Kubernetes service account token that the init.sh script will use to read and write secrets and configmaps.
### Kubernetes Service Account yaml
Create a service account token using the following steps.
1. Create a service-account.yaml file and fill with the following content.
```
apiVersion: v1
kind: ServiceAccount
metadata:
    name: stellar-ca-service-account
    labels:
    app: stellar-ca

---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
    name: stellar-ca-secret-creator-reader
rules:
    - apiGroups: [""]
    resources: ["secrets","configmaps"]
    verbs: ["create", "get", "list", "watch"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
    name: stellar-ca-secret-creator-reader-binding
subjects:
    - kind: ServiceAccount
    name: stellar-ca-service-account
roleRef:
    kind: Role
    name: stellar-ca-secret-creator-reader
    apiGroup: rbac.authorization.k8s.io

---
apiVersion: v1
kind: Secret
metadata:
  name: stellar-ca-service-account-token
  annotations:
    kubernetes.io/service-account.name: stellar-ca-service-account
type: kubernetes.io/service-account-token

```
2. Create the service account, role and biding using the following command. Remember to change the NAMESPACE value to the namespace you want to use. kubectl apply -f service-account.yaml -n NAMESPACE
3. Retrive the service account token: kubectl get secret -n NAMESPACE stellar-ca-service-account-token -ojsonpath='{.data.token}' | base64 -d
