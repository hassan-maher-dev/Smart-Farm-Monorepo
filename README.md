# 🌱 Smart Farm Infrastructure Platform

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-Web%20%2B%20Mobile-blue?style=for-the-badge&logo=flutter" />
  <img src="https://img.shields.io/badge/Python-Flask-yellow?style=for-the-badge&logo=python" />
  <img src="https://img.shields.io/badge/Docker-Containerized-blue?style=for-the-badge&logo=docker" />
  <img src="https://img.shields.io/badge/Kubernetes-Orchestration-326CE5?style=for-the-badge&logo=kubernetes" />
  <img src="https://img.shields.io/badge/Jenkins-CI%2FCD-red?style=for-the-badge&logo=jenkins" />
  <img src="https://img.shields.io/badge/ArgoCD-GitOps-orange?style=for-the-badge&logo=argo" />
  <img src="https://img.shields.io/badge/AWS-Cloud-orange?style=for-the-badge&logo=amazonaws" />
  <img src="https://img.shields.io/badge/PostgreSQL-Database-blue?style=for-the-badge&logo=postgresql" />
</p>

---

# 📌 Overview

Smart Farm Infrastructure Platform is an end-to-end cloud-native agriculture system that combines:

- 🌿 IoT automation
- 🤖 AI plant disease detection
- ☁️ Cloud infrastructure
- 🚀 CI/CD & GitOps workflows
- 📱 Cross-platform Flutter application

The platform simulates a real smart farming environment where sensors continuously monitor environmental conditions and automatically control farm devices such as water pumps and grow lights.

In addition, the system includes an AI-powered plant disease detection service using TensorFlow Lite models.

---

# 🏗️ System Architecture

```text
                          ┌────────────────────┐
                          │   Flutter App      │
                          │ (Web + Mobile)     │
                          └─────────┬──────────┘
                                    │
                    ┌───────────────┴────────────────┐
                    │                                │
                    ▼                                ▼
          ┌──────────────────┐            ┌──────────────────┐
          │   IoT Service    │            │    AI Service    │
          │ Flask + SQLA     │            │ Flask + TFLite   │
          └────────┬─────────┘            └────────┬─────────┘
                   │                               │
                   ▼                               ▼
          ┌──────────────────┐           ┌──────────────────┐
          │   PostgreSQL     │           │ TensorFlow Lite  │
          │   Sensor Data    │           │ Disease Model    │
          └────────┬─────────┘           └──────────────────┘
                   │
                   ▼
          ┌──────────────────┐
          │ ESP32 Simulator  │
          │ IoT Sensors      │
          └──────────────────┘
```

---

# 🚀 Key Features

## 🌡️ Real-Time IoT Monitoring

- Temperature monitoring
- Humidity tracking
- Soil moisture analysis
- Light intensity monitoring
- Water level tracking
- Air quality analysis
- UV index monitoring

---

## 🤖 Smart Automation System

Automatic farm control logic:

### 💧 Water Pump Automation

- Turns ON when soil moisture drops below threshold
- Turns OFF when soil becomes sufficiently wet

### 💡 Grow Lights Automation

- Automatically enables lights in dark environments
- Turns OFF lights during sufficient daylight

---

## 🧠 AI Plant Disease Detection

AI microservice powered by TensorFlow Lite:

- Upload plant images
- Predict diseases
- Return confidence score
- Lightweight inference optimized for deployment

Supported diseases include:

- Early Blight
- Late Blight
- Leaf Mold
- Mosaic Virus
- Powdery Mildew
- Bacterial Spot
- Healthy Plants Detection

---

## 📱 Flutter Cross-Platform Application

Supports:

- Android
- iOS
- Web

Features:

- Dashboard monitoring
- Device control
- Sensor visualization
- Disease detection interface
- Farm history tracking

---

# 🐳 Containerized Microservices

The platform uses Dockerized services:

```text
Smart-Farm-Backend/
├── ai_service/
└── iot_service/
```

Each service includes:

- Independent Dockerfile
- Isolated dependencies
- Scalable deployment architecture

---

# ☁️ Cloud & DevOps Architecture

Designed for cloud-native deployment using:

- AWS EKS
- DockerHub
- Jenkins CI/CD
- ArgoCD GitOps
- Kubernetes
- NGINX Ingress
- Terraform Infrastructure as Code

---

# 🔄 CI/CD & GitOps Workflow

```text
Developer Push
       ↓
GitHub Repository
       ↓
Jenkins Pipeline
       ↓
Docker Image Build
       ↓
Push to DockerHub
       ↓
ArgoCD Sync
       ↓
Kubernetes Deployment
       ↓
Production Environment
```

---

# 🧰 Tech Stack

| Category | Technologies |
|---|---|
| Frontend | Flutter |
| Backend | Python Flask |
| AI | TensorFlow Lite |
| Database | PostgreSQL |
| ORM | SQLAlchemy |
| Containerization | Docker |
| Orchestration | Kubernetes |
| CI/CD | Jenkins |
| GitOps | ArgoCD |
| Cloud | AWS |
| IaC | Terraform |
| Version Control | Git & GitHub |

---

# 📂 Project Structure

```text
Smart-Farm-Monorepo/
│
├── Smart-Farm-Backend/
│   ├── ai_service/
│   └── iot_service/
│
├── Smart-Farm-Flutter/
│
└── Infrastructure/
    ├── Terraform/
    ├── Kubernetes/
    └── Jenkins/
```

---

# 🔌 AI Service API

## POST `/predict`

Upload plant image for disease prediction.

### Response Example

```json
{
  "diseaseLabel": "Early_blight",
  "confidence": 96.4
}
```

---

# 🌐 IoT Service API

## POST `/api/data`

Receives sensor data and returns automation commands.

### Example Response

```json
{
  "status": "success",
  "commands": {
    "water_pump": true,
    "grow_lights": false
  }
}
```

---

# 📊 Future Improvements

- MQTT Integration
- Real ESP32 Hardware Deployment
- Prometheus Monitoring
- Grafana Dashboards
- Multi-user Authentication
- AI Model Retraining Pipeline
- AWS Auto Scaling
- Helm Charts
- Real-time Notifications

---

# 🔐 Security Improvements

The production-ready version uses:

- Environment variables
- Kubernetes Secrets
- GitHub Secrets
- Secure CI/CD pipelines

Sensitive credentials are excluded from public repositories.

---

# 🎯 Learning Outcomes

This project demonstrates practical experience in:

- Cloud Infrastructure Engineering
- DevOps & GitOps Workflows
- Kubernetes Deployment
- AI Service Integration
- IoT Automation Systems
- Flutter Cross-Platform Development
- Dockerized Microservices
- CI/CD Pipeline Design

---

# 👨‍💻 Author

## Hassan Maher Hassan

Electronics & Communications Engineering Student  
Specializing in Cloud Infrastructure & DevOps Engineering

- GitHub: https://github.com/hassan-maher-dev
- LinkedIn: https://linkedin.com/in/hassan-maher-ec/

---

# ⭐ Repository Goals

This project was built as a production-style smart agriculture platform to demonstrate:

- Real-world DevOps workflows
- Cloud-native infrastructure
- AI + IoT integration
- Scalable microservices architecture

If you like the project, consider giving it a ⭐ on GitHub.