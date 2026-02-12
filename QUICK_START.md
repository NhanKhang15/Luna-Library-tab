# 📱 Docker Setup - QUICK REFERENCE

## ✅ Current Status

```
✅ PostgreSQL (Docker)  - localhost:5432
✅ Redis (Docker)       - localhost:6379
⏳ C# Backend (Local)    - localhost:5000
⏳ Python Backend (Local) - localhost:8000
⏳ Flutter Web (Local)   - localhost:8080
```

**Running Docker**:
```bash
docker-compose -f docker-compose.infra.yml ps
docker-compose -f docker-compose.infra.yml logs
```

---

## 🚀 Start Everything (3 Terminal Windows)

### Terminal 1 - C# Backend
```bash
cd backend
dotnet run
# http://localhost:5000
```

### Terminal 2 - Python Backend
```bash
cd backend_py
venv\Scripts\activate          # Windows
# source venv/bin/activate     # Linux/Mac
python manage.py runserver
# http://localhost:8000
```

### Terminal 3 - Flutter Web
```bash
cd flutter
flutter run -d web-server --web-port=8080
# http://localhost:8080
```

---

## 📝 Configuration Files Changed

✏️ **backend/appsettings.Development.json** - Update connection string

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5432;Database=floria_db;Username=postgres;Password=postgres123;SSL Mode=Disable;"
  }
}
```

✏️ **backend_py/.env** - Create this file

```env
DATABASE_URL=postgresql://postgres:postgres123@localhost:5432/floria_db
DEBUG=True
SECRET_KEY=your-secret-key
```

✏️ **backend/Program.cs** - Change database provider (line ~13)

```csharp
// FROM:
options.UseSqlServer(...)

// TO:
options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection"))
```

---

## 🔧 One-Time Setup

### C# Backend
```bash
cd backend
dotnet add package Npgsql.EntityFrameworkCore.PostgreSQL
dotnet ef migrations add InitialCreate
dotnet ef database update
```

### Python Backend
```bash
cd backend_py
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
python manage.py migrate
```

### Flutter
```bash
cd flutter
flutter pub get
```

---

## 🐳 Docker Commands

```bash
# View running containers
docker ps

# View logs (infrastructure only)
docker-compose -f docker-compose.infra.yml logs -f

# Restart infrastructure
docker-compose -f docker-compose.infra.yml restart

# Stop everything
docker-compose -f docker-compose.infra.yml down

# Clean up
docker system prune -a --volumes
```

---

## 🔗 Access Points

| Service | URL | User/Pass |
|---------|-----|-----------|
| **C# API** | http://localhost:5000 | N/A |
| **Python API** | http://localhost:8000 | N/A |
| **Flutter Web** | http://localhost:8080 | N/A |
| **PostgreSQL** | localhost:5432 | postgres / postgres123 |
| **Redis** | localhost:6379 | N/A |

---

## ✅ Verification

```bash
# Check C# backend
curl http://localhost:5000/

# Check Python backend  
curl http://localhost:8000/admin/

# Check PostgreSQL
psql -h localhost -U postgres -d floria_db -c "SELECT 1;"

# Check Redis
redis-cli ping
```

---

## ❌ Common Issues

| Issue | Solution |
|-------|----------|
| Port already in use | Kill process: `netstat -ano \| findstr :PORT` |
| Module not found (Python) | Activate venv: `venv\Scripts\activate` |
| PostgreSQL won't connect | Check Docker: `docker ps \| grep postgres` |
| EF migrations error | Delete Migrations folder, create fresh migrations |

---

## 📚 Full Docs

- **MCR Issues**: [DOCKER_MCR_TROUBLESHOOTING.md](DOCKER_MCR_TROUBLESHOOTING.md)
- **Detailed Setup**: [LOCAL_BACKEND_SETUP.md](LOCAL_BACKEND_SETUP.md)
- **Docker Overview**: [README.DOCKER.md](README.DOCKER.md)

---

Generated: 2026-02-12 | Infrastructure: ✅ Running
