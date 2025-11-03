# 🏥 Sistema de Gestión Clínica Veterinaria

## 📋 Descripción
Sistema integral de gestión para clínicas veterinarias con arquitectura monorepo.

## 🏗️ Estructura del Proyecto
```
veterinaria-system/
├── backend/    (Java 17 + Spring Boot)
└── frontend/   (React)
```

## 🛠️ Stack Tecnológico

### Backend
- Java 17
- Spring Boot 3.x
- Spring Data JPA (Hibernate)
- PostgreSQL 15
- Flyway (migraciones)
- Maven

### Frontend
- React
- Axios
- TailwindCSS (o la librería que elijas)

## 🗄️ Configuración de Base de Datos
- **Host:** localhost
- **Puerto:** 5432
- **Base de datos:** veterinaria_db
- **Usuario:** vet_admin
- **Password:** VetPass2024!

## 📦 Módulos del Sistema

### Backend (7 módulos)
1. Gestión de Usuarios
2. Gestión de Inventario
3. Gestión de Pacientes
4. Prestación de Servicios
5. Gestión de Notificaciones
6. Configuración del Sistema
7. Reportes y Estadísticas

## 🚀 Instalación y Ejecución

### Requisitos Previos
- Java 17 JDK
- Maven 3.8+
- PostgreSQL 17
- Node.js 18+ (para frontend)
- Docker Desktop

### Levantar PostgreSQL
```bash
docker-compose up -d
```

### Backend
```bash
cd backend
mvn clean install
mvn spring-boot:run
```

### Frontend
```bash
cd frontend
npm install
npm start
```

## 👥 Equipo
Proyecto universitario - 4 integrantes

## 📄 Licencia
Proyecto académico
