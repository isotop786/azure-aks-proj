# Spring Boot on Azure AKS with Terraform & Azure DevOps

Deploy a containerized Spring Boot application to **Azure Kubernetes Service (AKS)** using **Terraform** for infrastructure provisioning and **Azure DevOps** for CI/CD.

This project demonstrates an end-to-end cloud deployment workflow:

**Spring Boot → Maven → Docker → Azure Container Registry / Container Image → AKS → Azure DevOps CI/CD → Terraform**

> **Note:** The current application in this repository is the `currency-exchange` Spring Boot service. Some Kubernetes manifests and Maven metadata retain the original `currency-exchange` naming.

## Architecture

```text
┌────────────────────┐
│   Developer        │
│  Git Repository    │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│   Azure DevOps     │
│      Pipeline      │
└─────────┬──────────┘
          │
          ├──────────────► Maven Build & Test
          │
          ├──────────────► Docker Image Build
          │
          └──────────────► Container Registry
                                  │
                                  ▼
                         ┌─────────────────┐
                         │      AKS        │
                         │ Kubernetes      │
                         │                 │
                         │ ┌─────────────┐ │
                         │ │ Spring Boot │ │
                         │ │   Pods      │ │
                         │ └─────────────┘ │
                         └─────────────────┘

              Terraform
                  │
                  ▼
        Azure Infrastructure
```

## Technology Stack

| Component | Technology |
|---|---|
| Application | Spring Boot |
| Language | Java 8 |
| Build Tool | Maven |
| Database | H2 |
| Containerization | Docker |
| Orchestration | Kubernetes / Azure AKS |
| Infrastructure as Code | Terraform |
| CI/CD | Azure DevOps |
| Cloud Platform | Microsoft Azure |

The Maven project uses Spring Boot `2.1.1.RELEASE`, Java 8, Spring Data JPA, Spring Security, Spring Boot Actuator, H2, and Spring Cloud Sleuth. citeturn1view2

## Repository Structure

```text
.
├── configuration/
│   └── kubernetes/
│       └── deployment.yaml
├── pipeline-backups/
├── src/
├── Dockerfile
├── pom.xml
└── readme.md
```

### Key files

- `src/` — Spring Boot application source code.
- `pom.xml` — Maven project configuration and dependencies.
- `Dockerfile` — Builds and packages the application into a Docker image.
- `configuration/kubernetes/` — Kubernetes deployment configuration.
- `pipeline-backups/` — Backup copies of pipeline configuration used during development.

## Application

The application is a Spring Boot currency-exchange microservice.

### API example

```http
GET /currency-exchange/from/USD/to/INR
```

Example response:

```json
{
  "id": 10001,
  "from": "USD",
  "to": "INR",
  "conversionMultiple": 65.00,
  "environmentInfo": "NA"
}
```

The application runs on port **8000**. The repository also includes an H2 console at:

```text
http://localhost:8000/h2-console
```

For the H2 console, the repository documentation specifies:

```text
JDBC URL: jdbc:h2:mem:testdb
```

## Prerequisites

Install the following tools before working with the project:

- Git
- Java 8
- Maven
- Docker
- Azure CLI
- Terraform
- `kubectl`
- An Azure subscription
- An Azure DevOps organization/project

For the Azure deployment, you will also need appropriate Azure permissions to create and manage the required resources.

## Run Locally

### 1. Clone the repository

```bash
git clone https://github.com/isotop786/azure-aks-proj.git
cd azure-aks-proj
```

### 2. Build the application

```bash
mvn clean package
```

The generated JAR is configured as:

```text
target/currency-exchange.jar
```

### 3. Run the application

```bash
java -jar target/currency-exchange.jar
```

The application should then be available at:

```text
http://localhost:8000
```

## Build with Docker

The included Dockerfile uses a multi-stage build. The build stage uses Maven with JDK 8, while the runtime stage uses OpenJDK 8. The resulting container exposes port `8000`. citeturn1view1

### Build the image

```bash
docker build -t currency-exchange:latest .
```

### Run the container

```bash
docker run --rm -p 8000:8000 currency-exchange:latest
```

Then open:

```text
http://localhost:8000
```

## Kubernetes Deployment

The Kubernetes configuration defines a Deployment and a NodePort Service.

The current Deployment:

- Runs **2 replicas**
- Exposes container port **8000**
- Uses rolling updates
- Defines CPU and memory requests/limits
- Includes readiness and liveness HTTP probes
- Uses `/` as the health-check endpoint

The current Service exposes port `8000` and uses `NodePort`. citeturn2view0

### Apply the manifest

```bash
kubectl apply -f configuration/kubernetes/deployment.yaml
```

### Check the deployment

```bash
kubectl get deployments
kubectl get pods
kubectl get services
```

### Check application logs

```bash
kubectl logs -l app=currency-exchange
```

> Before deploying to AKS, update the container image in `deployment.yaml` to the image stored in your Azure Container Registry or other container registry.

## Azure AKS and Terraform

Terraform is intended to provision the Azure infrastructure required for the Kubernetes deployment.

A typical workflow is:

```text
Terraform
   │
   ├── Resource Group
   ├── AKS Cluster
   ├── Container Registry
   └── Supporting Azure Resources
            │
            ▼
           AKS
```

Initialize Terraform:

```bash
terraform init
```

Review the planned infrastructure changes:

```bash
terraform plan
```

Apply the infrastructure:

```bash
terraform apply
```

After the AKS cluster is created, retrieve its credentials:

```bash
az aks get-credentials   --resource-group <RESOURCE_GROUP>   --name <AKS_CLUSTER_NAME>
```

Verify cluster access:

```bash
kubectl get nodes
```

> Terraform configuration should be reviewed against the actual Azure resources and variables in your environment before running `terraform apply`.

## Azure DevOps CI/CD

The intended CI/CD workflow is:

```text
Git Push
   │
   ▼
Azure DevOps Pipeline
   │
   ├── Checkout source
   ├── Maven build
   ├── Run tests
   ├── Build Docker image
   ├── Push image to container registry
   └── Deploy Kubernetes manifests to AKS
```

This approach separates:

- **Infrastructure provisioning** — Terraform
- **Application build** — Maven
- **Container packaging** — Docker
- **Application orchestration** — Kubernetes / AKS
- **Automation** — Azure DevOps

### Recommended pipeline stages

```yaml
stages:
  - Build
  - Docker
  - Deploy
```

A production Azure DevOps pipeline should store Azure credentials, registry credentials, and other secrets in secure pipeline variables, variable groups, or Azure service connections rather than committing them to Git.

## Useful Kubernetes Commands

### View all resources

```bash
kubectl get all
```

### View pods

```bash
kubectl get pods -o wide
```

### Describe a pod

```bash
kubectl describe pod <POD_NAME>
```

### View logs

```bash
kubectl logs <POD_NAME>
```

### Restart deployment

```bash
kubectl rollout restart deployment/currency-exchange
```

### Check rollout status

```bash
kubectl rollout status deployment/currency-exchange
```

## Troubleshooting

### Docker is not running

If Docker commands fail because the Docker daemon is unavailable, make sure Docker is installed and running.

The original project documentation also notes Docker-related errors on macOS when the Docker credential helper is unavailable.

### Pod is not starting

Check:

```bash
kubectl get pods
kubectl describe pod <POD_NAME>
kubectl logs <POD_NAME>
```

Common causes include:

- Incorrect container image name
- Image pull failure
- Insufficient cluster resources
- Application startup failure
- Incorrect port configuration

### Readiness or liveness probe fails

The current Kubernetes manifest checks:

```text
GET /
```

on port `8000`.

If the application's root endpoint does not return a successful response during startup, consider configuring the probes to use an appropriate Spring Boot Actuator health endpoint.

## Security Considerations

Do not commit the following to Git:

- Azure client secrets
- Service principal credentials
- Kubernetes credentials
- Docker registry passwords
- API keys
- Database passwords
- Terraform state containing sensitive information

Use Azure DevOps service connections, secret variables, Azure Key Vault, or another appropriate secret-management solution.

## Project Goals

This project demonstrates practical DevOps and cloud-native concepts:

- Containerizing a Spring Boot application
- Deploying applications to Kubernetes
- Provisioning Azure infrastructure with Terraform
- Running workloads on Azure Kubernetes Service
- Automating application delivery with Azure DevOps
- Using Kubernetes health checks and rolling updates
- Building a repeatable CI/CD deployment workflow

## References

- [Azure Kubernetes Service (AKS)](https://azure.microsoft.com/products/kubernetes-service/)
- [Terraform](https://developer.hashicorp.com/terraform)
- [Azure DevOps](https://azure.microsoft.com/products/devops)
- [Spring Boot](https://spring.io/projects/spring-boot)
- [Kubernetes](https://kubernetes.io/)
- [Docker](https://www.docker.com/)

## License

No license file is currently shown in the repository. Add a `LICENSE` file if you intend to distribute the project under a specific open-source license.
