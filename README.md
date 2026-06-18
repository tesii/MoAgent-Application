# MoAgent App

## Overview

MTN Agent Analytics Dashboard is a cross platform analytics system designed to monitor and analyze MTN mobile money agent transactions across geographic regions (Province → District → Sector).

The system analyzes **cash in vs cash out behavior over time**, helping regional managers identify low performing areas, understand transaction trends, and make data driven operational decisions.

The platform combines:
  Flutter frontend for interactive dashboards
  PHP backend for data services and APIs
  Python for data cleaning, processing, and visualization

   

## Problem Statement

Regional managers often lack clear visibility into:

  Cash in vs cash out imbalance across regions
  Performance differences between provinces, districts, and sectors
  Time periods of low transaction activity
  Reasons behind underperforming regions

This leads to delayed decisions and inefficient regional strategy.

This system solves this by transforming raw transaction data into structured insights and visual analytics.

   

## Key Features

### 📊 Transaction Analytics
  Cash in vs cash out comparison
  Region based performance (Province → District → Sector)
  Time based analysis (daily, weekly, monthly)
  Agent level transaction behavior tracking

### 📈 Interactive Dashboards
  Real time charts and visual analytics
  Drill down regional analysis
  Time series trend visualization
  Comparative region performance graphs

### 🧠 Smart Insights
  Identification of low performing regions
  Detection of low activity time periods
  Transaction behavior patterns
  Performance anomaly detection

### 🐍 Data Processing & Analytics (Python)
  Data cleaning and preprocessing of raw transactions
  Generation of statistical insights
  Creation of analytical graphs and reports
  Data transformation for dashboard consumption

   

## Technologies Used

### Frontend
  Flutter (Dart)
  Interactive UI dashboards
  Chart libraries (fl_chart / Syncfusion Charts)

### Backend
  PHP
  RESTful APIs
  JSON based communication

### Data Processing & Analytics
  Python
  Pandas (data cleaning & transformation)
  Matplotlib / Seaborn (data visualization)
  NumPy (data processing)

### Database
  MySQL

   

## System Architecture

The system is built using a multi layer architecture:

  **Flutter Frontend**
    Displays dashboards and charts
    Provides user interaction

  **PHP Backend**
    Handles API requests
    Manages business logic and data flow

  **Python Analytics Engine**
    Cleans and processes raw transaction data
    Generates insights and graphs
    Prepares structured datasets for the dashboard

  **MySQL Database**
    Stores transaction and regional data

## Video
https://www.youtube.com/watch?v=YEoUPgPRy3s

