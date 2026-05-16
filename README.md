# E-commerce ETL & Data Warehouse

## Overview

This repository contains a compact, hands-on learning project that implements an end-to-end ETL pipeline and data warehouse artifacts for a simplified e-commerce domain. The goal was to learn by building: exploring pipeline orchestration, data modeling, and system design through implementation.

## What I built

- Extract, Transform, Load (ETL) pipeline components under `etl_pipeline/` covering extraction, transformation, loading, and watermarking.
- OLTP and OLAP schema examples in `OLTP_Schemas/` and `OLAP_Schemas/` to illustrate schema design and data warehousing concepts.
- A lightweight `scheduler` component used to automate and orchestrate the ETL pipelines on a schedule.

## Scheduler & Automation

The project includes a scheduler for automating ETL runs, enabling regular ingestion and incremental updates without manual intervention. The scheduler demonstrates basic orchestration patterns and how pipelines can be timed and chained.

## What I learned

- System design concepts: service boundaries, orchestration, fault isolation, and simple scheduling strategies.
- Data modeling: designing OLTP schemas and transforming them into OLAP-friendly structures for analytical workloads.
- Practical pipeline engineering: incremental loads, watermarking, data validation, and modular pipeline components.

This work was primarily a learning exercise, I learned by building and iterating on the implementation rather than just reading notes.

## How I did it

Over the past few weeks, I focused on strengthening foundational knowledge needed for modern data infrastructure by building this e-commerce design practice end to end.

- Broke learning into small implementation cycles: design, build, test, refine.
- Focused on core engineering basics first: data modeling, ETL design, scheduling, and system structure.
- Treated tools as interchangeable and skills as durable: tools evolve, but strong engineering foundations remain.
- Used this project as a practical learning strategy to apply concepts in real workflows instead of only reading notes.

