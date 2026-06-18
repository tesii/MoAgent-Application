# MoAgent APP

## Overview

MTN Agent Analytics Dashboard is a Flutter based data visualization and intelligence platform designed to analyze agent transaction behavior across different geographic regions (Province → District → Sector).

The system focuses on **cash in vs cash out transaction patterns over time**, enabling regional managers to make data driven decisions, identify underperforming areas, and understand transaction behavior trends across MTN mobile money agents.

It transforms raw transaction data into **interactive, real time analytics and actionable insights**.

   

## Problem Statement

Regional managers often lack clear visibility into:

  Which regions are underperforming in agent transactions
  Cash in vs cash out balance across regions
  Time periods when transaction activity drops
  Why certain areas show low agent performance

This leads to delayed decision making and inefficient regional support strategies.

The MTN Agent Analytics Dashboard solves this by providing real time, visual, and intelligent insights.

   

## Key Features

### 📊 Transaction Analytics
  Cash in vs cash out comparison
  Region based performance tracking (Province, District, Sector)
  Daily, weekly, and monthly trends
  Agent level transaction breakdown

### 📈 Interactive Visualizations
  Real time charts and dashboards
  Time series analysis of transactions
  Region comparison graphs
  Drill down from province → district → sector

### 🧠 Smart Insights
  Identification of low performing regions
  Detection of low activity time periods
  Behavioral trends of MTN agents
  Performance anomalies and insights

### 🗺 Regional Intelligence
  Province level aggregation
  District level comparison
  Sector level performance tracking
  Geo based performance analysis

   

## Technologies Used

### Frontend (Mobile / Dashboard)
  Flutter
  Dart
  State Management (Provider / Riverpod)
  Charts (fl_chart / Syncfusion Flutter Charts)

### Backend (if applicable)
  Spring Boot / Node.js
  REST APIs
  JSON data processing

### Database
  MySQL / PostgreSQL

   

## System Architecture

The system follows a layered analytics architecture:

  **Flutter Frontend** → Interactive dashboards and charts
  **Backend API Layer** → Processes transaction data
  **Database Layer** → Stores agent transaction records
  **Analytics Engine** → Aggregates and computes regional insights

   

## How to Run the Project

### Prerequisites
  Flutter SDK (latest stable)
  Dart SDK
  Android Studio / VS Code
  Backend API (if applicable)

   

### Step 1: Clone Repository

```bash
git clone https://github.com/yourusername/mtn agent dashboard.git
