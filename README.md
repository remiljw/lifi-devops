# Bird Application [![HTTP Service](https://github.com/remiljw/lifi-devops/actions/workflows/main.yml/badge.svg)](https://github.com/remiljw/lifi-devops/actions/workflows/main.yml)

This is the bird Application! It gives us birds!!!

The app is written in Golang and contains 2 APIs:
- the bird API
- the birdImage API

![pipeline_diagram](https://github.com/remiljw/lifi-devops/blob/main/ci_cd_pipeline.png?raw=true)

![architecture_diagram](https://github.com/remiljw/lifi-devops/blob/main/bird_application_with_monitoring.jpeg?raw=true)

![infrastructure_diagram]

This repo demonstrates a process of deploying an HTTP service to a K8s cluster  running on an EC2 instance. To get this setup running, you need to have this in place:

# Prerequisites
- AWS Account
- Terraform

# Setup
- Configure your AWS Account credentials on your CLI

- `cd` into the the terraform directory and apply the IaC.

- The output contains a Load Balancer DNS Name.Wait for a while before accessing it in your browser

Listed below are the available endpoints
- - Application: `/`
- - Metrics  : `/metrics`
- - ArgoCD : `/argo`
- - Prometheus - `/prometheus`
