# Overview

This repository contains
* Code for setting up infrastructure
  - Automated Jenkins setup
  - AWS EKS cluster setup using AWS Cloud Formation
  - Scripts for preparing EKS cluster for GitOps
* Project plan
* Documentation

There are three other repositories 
* DevOps_Capstone_Deployment:  Contains the Flux deployment config.
* DevOps_Capstone_Service: Contains the service code
* DevOps_Capstone_Pipeline: Contains the Jenkins pipeline setup for the capstone project

# Project Plan

## Build Pipeline

Two independent pipelines:

###  Project Build Pipeline

#### Branching strategy
Scaled Trunk based development. (https://trunkbaseddevelopment.com/)
- one master branch
- short lived feature branches
- feature branch builds must pass before merging into mainline
- images with version tags are built from releast branches
- images with latest tags are built from trunk
- no images are built on feature branches
- Releases are tagged on mainline

##### General pipeline requirements
- On build failure email is sent to latest committer
- Build on each commit
- Parallel builds

##### Pipeline for mainline and release branches
Clone Project -> Linting -> Build -> Run Unit Tests -> Run Component Tests -> Build Docker Image -> Push to Registry

##### Pipeline for feature branches
Clone Project -> Linting -> Build -> Run Unit Tests -> Run Component Tests 

#### Required Infrastructure

Build server: Runs on K8s cluster. 
Registry: AWS ECR
Repository: GitHub repo
Build server: Jenkins

## Blue/Green deployment pipeline

- Deployment on an AWS EKS cluster, modified AWS Cloud Formation template for setup
- Deployment using Flux and Helm
- Two deployment stages, staging and production
- Rolling deployment in staging
- Automated integration and load testing in staging
- Blue/Green deployment in production
- Automated integration testing in production during Blue/Green deployment

#### Required Infrastructure

K8s Cluster: AWS EKS 
Registry: AWS ECR
Repository for flux deployment config: GitHub repo

# Jenkins setup

- Jenkins is deployed using Helm on K8s
- Custom Jenkins image is used, see jenkins/Dockerfile

