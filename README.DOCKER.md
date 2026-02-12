# Docker Setup Guide

Hướng dẫn thiết lập và chạy ứng dụng với Docker.

## Cấu trúc Dự án

```
app_kinh_nguyet_thu_vien/
├── backend/                 # C# ASP.NET Core API
├── backend_py/             # Python Django + FastAPI
├── flutter/                # Flutter Frontend
├── docker-compose.yml      # Production compose file
├── docker-compose.dev.yml  # Development compose file
└── .dockerignore           # Docker ignore patterns
```

## Yêu cầu

- Docker Desktop (phiên bản 20.10+)
- Docker Compose (phiên bản 2.0+)
- Ít nhất 4GB RAM được cấp cho Docker

## Các Services

### 1. C# Backend (Port 5000)
- **Image**: `backend:latest`
- **Dockerfile**: `backend/Dockerfile`
- **Phụ thuộc**: MSSQL Database
- **Variables**: JWT Config, Connection String

### 2. Python Backend (Port 8000)
- **Image**: `backend-py:latest`
- **Dockerfile**: `backend_py/Dockerfile`
- **Phụ thuộc**: MSSQL Database
- **Framework**: Django + FastAPI

### 3. Flutter Web Frontend (Port 80)
- **Image**: `app_kinh_nguyet_thu_vien-frontend-web:latest`
- **Dockerfile**: `Dockerfile.web`
- **Build**: Production build của Flutter web

### 4. MSSQL Database (Port 1433)
- **Image**: `mcr.microsoft.com/mssql/server:2022-latest`
- **Password**: Được định cấu hình trong compose file
- **Volume**: `mssql_data` (persistent storage)

### 5. Redis Cache (Port 6379)
- **Image**: `redis:7-alpine`
- **Optional**: Sử dụng cho caching và sessions

## Cách Chạy

### Development Environment

```bash
# Tạo và chạy containers
docker-compose -f docker-compose.dev.yml up -d

# Xem logs
docker-compose -f docker-compose.dev.yml logs -f

# Dừng containers
docker-compose -f docker-compose.dev.yml down
```

### Production Environment

```bash
# Tạo và chạy containers
docker-compose up -d

# Xem logs
docker-compose logs -f

# Dừng containers
docker-compose down
```

## URLs Truy Cập

| Service | URL | Port |
|---------|-----|------|
| C# Backend API | http://localhost:5000 | 5000 |
| Python Backend | http://localhost:8000 | 8000 |
| Flutter Web | http://localhost | 80 |
| MSSQL | localhost:1433 | 1433 |
| Redis | localhost:6379 | 6379 |

## Environment Variables

### C# Backend
- `ASPNETCORE_ENVIRONMENT`: Development/Production
- `ConnectionStrings__DefaultConnection`: MSSQL connection string
- `Jwt__Key`: JWT secret key
- `Jwt__Issuer`: JWT issuer
- `Jwt__Audience`: JWT audience

### Python Backend
- `DEBUG`: True/False
- `SECRET_KEY`: Django secret key
- `DATABASE_URL`: Database connection string
- `JWT_SECRET`: JWT secret key

## Khắc Phục Sự Cố

### 1. Port đã được sử dụng
```bash
# Kiểm tra process sử dụng port
netstat -ano | findstr :5000

# Hoặc thay đổi port trong docker-compose.yml
```

### 2. Database connection failed
```bash
# Kiểm tra MSSQL container
docker-compose logs mssql

# Chạy database migrations
docker-compose exec backend dotnet ef database update
```

### 3. Python dependencies error
```bash
# Cài đặt lại dependencies
docker-compose exec backend-py pip install --no-cache-dir -r requirements.txt
```

### 4. Xóa volumes và rebuild
```bash
# Dừng containers
docker-compose down -v

# Xóa images
docker-compose down --rmi all

# Rebuild từ đầu
docker-compose build --no-cache
docker-compose up
```

## Development Tips

### Hot Reload
- **C# Backend**: Sử dụng `dotnet watch` (được cấu hình trong Dockerfile.dev)
- **Python Backend**: Sử dụng `--reload` flag khi khởi động Django
- **Flutter**: Rebuild khi thay đổi code

### Debugging
```bash
# Xem logs real-time
docker-compose logs -f backend

# Truy cập container shell
docker-compose exec backend /bin/bash

# Chạy command một lần
docker-compose exec backend dotnet ef migrations add InitialCreate
```

## Build Images Riêng

### Build C# Backend
```bash
docker build -t app-backend:latest ./backend -f ./backend/Dockerfile
```

### Build Python Backend
```bash
docker build -t app-backend-py:latest ./backend_py -f ./backend_py/Dockerfile
```

### Build Flutter Web
```bash
docker build -t app-frontend-web:latest . -f Dockerfile.web
```

## Production Deployment

1. **Cập nhật credentials** trong docker-compose.yml:
   - Thay đổi `SA_PASSWORD`
   - Thay đổi JWT keys
   - Cập nhật `ASPNETCORE_ENVIRONMENT` thành Production

2. **Sử dụng environment file**:
   ```bash
   docker-compose --env-file .env.production up -d
   ```

3. **Backup database**:
   ```bash
   docker-compose exec mssql /opt/mssql-tools18/bin/sqlcmd \
     -S localhost -U sa -P "YourPassword" \
     -Q "BACKUP DATABASE [Floria_2] TO DISK = '/var/opt/mssql/backup/floria.bak'"
   ```

## Security Considerations

⚠️ **IMPORTANT**: Thay đổi các giá trị mặc định trước khi production:
- ✅ Thay đổi mật khẩu SA
- ✅ Thay đổi JWT secret keys
- ✅ Thay đổi SECRET_KEY Django
- ✅ Sử dụng HTTPS/SSL certificates
- ✅ Giới hạn quyền truy cập database
- ✅ Cấu hình firewall rules

## Tài Liệu Tham Khảo

- [Docker Documentation](https://docs.docker.com)
- [Docker Compose Documentation](https://docs.docker.com/compose)
- [.NET Docker Guide](https://docs.microsoft.com/en-us/dotnet/core/docker)
- [Flutter Docker Guide](https://flutter.dev/docs/deployment/web)
