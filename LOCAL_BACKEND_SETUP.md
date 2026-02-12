# 🚀 Local Backend Setup (MCR Workaround)

**Status**: ✅ Infrastructure (PostgreSQL + Redis) đang chạy trên Docker
**Cần làm**: Chạy C# Backend + Python Backend trên local

---

## 📋 Prerequisites

### C# Backend
- ✅ .NET 8.0 SDK ([Download](https://dotnet.microsoft.com/download))
- Visual Studio Code + C# Dev Kit

### Python Backend
- ✅ Python 3.11+ ([Download](https://www.python.org/downloads/))
- pip (thường có sẵn)

---

## 🛠️ Setup & Run

### Step 1: Kiểm tra Connection Strings

PostgreSQL đang chạy tại:
```
Host: localhost
Port: 5432
Database: floria_db
User: postgres
Password: postgres123
```

### Step 2: Cấu Hình C# Backend

**Chỉnh sửa** `backend/appsettings.Development.json`:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5432;Database=floria_db;Username=postgres;Password=postgres123;SSL Mode=Disable;"
  },
  "Jwt": {
    "Issuer": "FloriaAPI",
    "Audience": "FloriaApp",
    "Key": "floria-super-secure-secret-key-min-32-chars-2024!",
    "AccessTokenMinutes": 60
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*"
}
```

**Cài đặt PostgreSQL NuGet package**:

```bash
cd backend
dotnet add package Npgsql.EntityFrameworkCore.PostgreSQL
```

**Cập nhật Program.cs**:

Tìm dòng:
```csharp
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseSqlServer(...));
```

Thay bằng:
```csharp
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));
```

**Chạy migrations**:

```bash
cd backend

# Xóa migrations cũ (nếu có)
# rm -r Migrations

# Tạo migration mới cho PostgreSQL
dotnet ef migrations add InitialCreate

# Cập nhật database
dotnet ef database update
```

**Chạy C# Backend**:

```bash
cd backend
dotnet run
```

**Output mong đợi**:
```
Building...
info: Microsoft.EntityFrameworkCore.Infrastructure[10403]
      Entity Framework Core initialized 'AppDbContext' using provider 'Npgsql.EntityFrameworkCore.PostgreSQL'...
info: Microsoft.Hosting.Lifetime[14]
      Now listening on: http://localhost:5000
```

✅ C# API: http://localhost:5000

---

### Step 3: Cấu Hình Python Backend

**Tạo/chỉnh sửa** `backend_py/.env`:

```env
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1,backend-py

# PostgreSQL
DATABASE_URL=postgresql://postgres:postgres123@localhost:5432/floria_db

# Django
SECRET_KEY=your-django-secret-key-change-in-production
DJANGO_SETTINGS_MODULE=config.settings

# JWT
JWT_SECRET=floria-super-secure-secret-key-min-32-chars-2024!

# Redis (optional, nếu sử dụng caching)
REDIS_URL=redis://localhost:6379/0
```

**Cài đặt dependencies**:

```bash
cd backend_py

# Tạo virtual environment
python -m venv venv

# Activate venv
# Windows:
venv\Scripts\activate
# Linux/Mac:
# source venv/bin/activate

# Cài packages
pip install -r requirements.txt
```

**Update Django settings** `backend_py/config/settings.py`:

Tìm database configuration và sửa thành:
```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'floria_db',
        'USER': 'postgres',
        'PASSWORD': 'postgres123',
        'HOST': 'localhost',
        'PORT': '5432',
    }
}
```

**Chạy migrations**:

```bash
cd backend_py
python manage.py migrate
```

**Chạy Python Backend**:

```bash
python manage.py runserver 0.0.0.0:8000
```

**Output mong đợi**:
```
Watching for file changes with StatReloader
Quit the server with CTRL-BREAK.
Starting development server at http://0.0.0.0:8000/
```

✅ Python API: http://localhost:8000

---

### Step 4: Chạy Flutter Frontend

```bash
cd flutter

# Build web
flutter build web

# Serve locally (development)
flutter run -d web-server --web-port=8080
```

✅ Flutter Web: http://localhost:8080

---

## 📊 Status Check

**Kiểm tra tất cả services**:

```bash
# Check Docker containers
docker ps

# Test C# Backend
curl http://localhost:5000/health

# Test Python Backend
curl http://localhost:8000/admin/

# Test Redis
redis-cli ping
# Output: PONG

# Test PostgreSQL
psql -h localhost -U postgres -d floria_db -c "SELECT 1;"
```

---

## 🗂️ File Structure

```
project/
├── backend/                    # C# ASP.NET Core
│   ├── appsettings.Development.json  (✏️ UPDATE)
│   ├── Program.cs                    (✏️ UPDATE)
│   └── Migrations/                   (✨ CREATE NEW)
│
├── backend_py/                 # Python Django
│   ├── .env                         (✏️ CREATE/UPDATE)
│   ├── config/settings.py           (✏️ UPDATE)
│   └── manage.py
│
├── flutter/                    # Flutter Frontend
│   └── pubspec.yaml
│
└── docker-compose.infra.yml   # Infrastructure only
```

---

## 🔌 API Endpoints

| Service | URL | Status |
|---------|-----|--------|
| **C# Backend** | http://localhost:5000 | ✅ Local |
| **Python Backend** | http://localhost:8000 | ✅ Local |
| **Flutter Web** | http://localhost:8080 | ✅ Local |
| **PostgreSQL** | localhost:5432 | ✅ Docker |
| **Redis** | localhost:6379 | ✅ Docker |

---

## 📝 Quick Start Commands

**Terminal 1 - C# Backend**:
```bash
cd backend
dotnet run
```

**Terminal 2 - Python Backend**:
```bash
cd backend_py
source venv/bin/activate  # or venv\Scripts\activate on Windows
python manage.py runserver
```

**Terminal 3 - Flutter Frontend**:
```bash
cd flutter
flutter run -d web-server
```

**Terminal 4 - Docker Infrastructure** (already running):
```bash
docker-compose -f docker-compose.infra.yml logs -f
```

---

## ❌ Troubleshooting

### PostgreSQL Connection Error

```
Exception: could not translate host name "localhost" to address
```

**Fix**: Kiểm tra PostgreSQL đang chạy:
```bash
docker ps | grep postgres
```

Nếu không có, start lại:
```bash
docker-compose -f docker-compose.infra.yml up -d postgres
```

### Migration Error

```
Relational database does not support ..Database operation
```

**Fix**: 
1. Xóa `Migrations` folder
2. Chạy `dotnet ef migrations add InitialCreate`
3. Chạy `dotnet ef database update`

### Python Dependencies Error

```
ModuleNotFoundError: No module named 'django'
```

**Fix**: Chắc chắn activate venv:
```bash
# Windows:
venv\Scripts\activate

# Linux/Mac:
source venv/bin/activate

pip install -r requirements.txt
```

### Port Already in Use

```
Address already in use
```

**Fix**: Thay đổi port hoặc kill process:
```bash
# Windows - find & kill process on port 5000
netstat -ano | findstr :5000
taskkill /PID <PID> /F

# Linux/Mac
lsof -i :5000
kill -9 <PID>
```

---

## ✅ Next Steps

1. ✅ Infrastructure (PostgreSQL + Redis) đang chạy
2. ⏳ Setup & chạy C# Backend (xem Step 2)
3. ⏳ Setup & chạy Python Backend (xem Step 3)
4. ⏳ Chạy Flutter Frontend (xem Step 4)

---

## 📞 Support

Gặp lỗi? Kiểm tra:
1. Tất cả ports không bị sử dụng
2. Python venv được activate
3. PostgreSQL container đang chạy
4. .env file được cấu hình đúng
5. Dependencies được cài đủ

