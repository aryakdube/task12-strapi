 🚀 Strapi Blog API Setup

This repository contains the initial setup for a **Strapi backend** with a sample `blog-post` content type, fulfilling the Day 1 task requirements. The goal is to explore Strapi's capabilities, understand its structure, and prepare it for API-driven content management.

---

## 📌 Task Objective

As per the task guidelines:

> Clone the Strapi repository from https://github.com/strapi/strapi  
> Run it locally, explore the folder structure, start the admin panel, and create a sample content type.  
> Push your setup to GitHub and document the steps taken in a README.md file.  
> At the end of the day, post your work update in the team channel with a pull request link and a Loom video.

---

## ✅ Completed Steps

### 1. ✅ Clone Strapi Repository

git clone https://github.com/strapi/strapi.git
cd strapi
Cloned the official Strapi repository to explore its structure and start development.

2. 🏗️ Initialize Strapi App Locally

npx create-strapi-app@latest my-strapi-project --quickstart
cd my-strapi-project
Installed dependencies

Auto-started Strapi dev server

Opened admin panel at http://localhost:1337/admin

3. 👤 Admin Panel Setup
Created a new admin user
Logged into the Strapi dashboard

4. 🧱 Created Content Type: blog-post
  I created a sample content type called BlogPost. I go to the Content-Type Builder, then click on Create new collection type

  Entered the name as BlogPost, and add two fields: a Title as Text, and Content as Rich Text. After saving, Strapi automatically restarts to apply changes.

  After creating the BlogPost type, I go to the Content Manager, click on BlogPost, and add a new entry.
  Here I’ve added sample title: My First Blog and sample content. Then I saved and published the entry

5. 🚀 Code Committed & Pushed to GitHub

https://github.com/aryakdube/strapi-project

6. 🎥 Loom Video Link
Explained the setup process, content-type creation, and Strapi dashboard usage.

https://www.loom.com/share/dcbd7e956d88495fa0464a1b871ae93c?sid=1726b845-df25-40fb-b7f0-7ffd74d81950


🚀 Task 2: Dockerize the Strapi Application
This task involves creating a Dockerfile to containerize the Strapi application and run it locally using Docker.

https://www.loom.com/share/058c0bf7e189437c83bcbfc63584feec?sid=e06ecff2-1b91-4f84-8133-7600de1f5a6e


🚀 Task 3: Dockerized Strapi Setup with PostgreSQL and Nginx

This task sets up a production-like development environment using Docker to run a Strapi backend, connect it with a PostgreSQL database, and expose it via an Nginx reverse proxy on port 80.

https://www.loom.com/share/b943933a549f4985a4368f94f67a08ad?sid=6dfcd0fc-e167-4210-b215-c6ab293e73ab