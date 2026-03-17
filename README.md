# Roadmap Creator

A lightweight, professional web application that generates a product roadmap from a Jira CSV extract.

## Core Capabilities

- Upload Jira CSV or Excel (XLSX) data and automatically extract:
	- `application`
	- `feature_name`
	- `quarter`
	- `month`
	- `year`
- Dynamic filters across all roadmap parameters.
- Clean enterprise-style UI for planning and reporting.
- Kubernetes-ready deployment with health checks.

## Tech Stack

- FastAPI (Python)
- Jinja2 + modern vanilla JavaScript UI
- Docker
- Kubernetes manifests (Deployment, Service, Ingress)

## Run Locally

### 1) Install dependencies

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 2) Start app

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Open: `http://localhost:8000`

## Run with Docker

```bash
docker build -t roadmap-creator:latest .
docker run --rm -p 8000:8000 roadmap-creator:latest
```

Open: `http://localhost:8000`

## Deploy to Kubernetes

### 1) Build and push image

```bash
docker build -t your-registry/roadmap-creator:latest .
docker push your-registry/roadmap-creator:latest
```

### 2) Update image reference

Edit `k8s/deployment.yaml` and confirm the container image matches your registry.

### 3) Apply manifests

```bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/ingress.yaml
```

### 4) Verify rollout

```bash
kubectl rollout status deployment/roadmap-creator
kubectl get svc roadmap-creator
kubectl get ingress roadmap-creator
```

## Jira CSV Notes

The parser handles common Jira export header variations (for example `Summary`, `Project`, `Component/s`, `Due Date`).

If quarter/month/year are not explicitly present, it attempts to derive them from date columns.

Supported upload formats: `.csv`, `.xlsx`

## Sample Data and Smoke Test

A sample Jira-style CSV is included at `samples/sample_jira_extract.csv`.

Run a quick smoke test (health + upload + schema validation):

```bash
bash scripts/smoke_test.sh http://localhost:8000 samples/sample_jira_extract.csv
```

The repository also includes a CI workflow at `.github/workflows/smoke-test.yml` that starts the app and runs this smoke test on pushes and pull requests.

## Excel Template

An Excel template is included at `templates/roadmap_template.xlsx`.

It contains the required roadmap columns:

- `application`
- `feature_name`
- `quarter`
- `month`
- `year`

To regenerate the template:

```bash
python3 scripts/create_excel_template.py
```

## Production Recommendations

- Put the app behind your enterprise ingress controller and SSO gateway.
- Store container images in your private registry.
- Use namespace-level resource quotas and autoscaling based on your standards.
