# Docker Troubleshooting - MCR Connectivity Issue

## 🔴 Vấn Đề: MCR (Microsoft Container Registry) Không Khả Dụng

Nếu bạn gặp lỗi:
```
Error response from daemon: Head "https://mcr.microsoft.com/v2/...": EOF
```

**Nguyên nhân**: Vấn đề kết nối khu vực (Region) đến MCR - rất phổ biến tại Việt Nam và các nước Đông Nam Á.

---

## ✅ Giải Pháp 1: Sử Dụng PostgreSQL (Khuyến Nghị)

Thay vì MSSQL Server, dùng PostgreSQL từ Docker Hub (100% khả dụng):

```bash
cd e:\app_kinh_nguyet_thu_vien
docker-compose -f docker-compose.postgres.yml up -d
```

**Ưu điểm**:
- ✅ Hoạt động ngay lập tức (Docker Hub có sẵn)
- ✅ Nhẹ hơn MSSQL
- ✅ Phù hợp cho development
- ⚠️ Cần thay đổi connection string trong `appsettings.json`

---

## ✅ Giải Pháp 2: Sử Dụng Local SQL Server (Windows)

Nếu máy bạn đã cài SQL Server 2019/2022:

1. **Kiểm tra SQL Server đang chạy**:
   ```powershell
   # Mở Services (services.msc)
   # Tìm "SQL Server (MSSQLSERVER)" và đảm bảo nó Running
   ```

2. **Sửa connection string** trong `backend/appsettings.json`:
   ```json
   {
     "ConnectionStrings": {
       "DefaultConnection": "Server=.\\SQLEXPRESS;Database=Floria_2;Integrated Security=true;TrustServerCertificate=True;"
     }
   }
   ```

3. **Chỉ chạy backends không cần database container**:
   ```bash
   docker-compose -f docker-compose.postgres.yml up -d --scale backend=0 --scale backend-py=0
   ```

---

## ✅ Giải Pháp 3: VPN/Proxy cho MCR

Nếu bạn muốn tiếp tục sử dụng MSSQL Server:

### 3.1 Cấu Hình Docker Proxy

**Tạo file**: `%userprofile%\.docker\daemon.json`
```json
{
  "registry-mirrors": [
    "https://docker.nju.edu.cn",
    "https://dockerhub.azk8s.cn"
  ],
  "insecure-registries": [
    "docker.nju.edu.cn",
    "dockerhub.azk8s.cn"
  ]
}
```

Sau đó **restart Docker Desktop** và thử lại.

### 3.2 Hoặc sử dụng Proxy DCCompass

```bash
# Thiết lập proxy cho Docker (nếu có)
$Env:HTTP_PROXY = "http://proxy.company.com:8080"
$Env:HTTPS_PROXY = "http://proxy.company.com:8080"
docker pull mcr.microsoft.com/mssql/server:2022-CU11-ubuntu-22.04
```

---

## ✅ Giải Pháp 4: Sử Dụng DockerHub Mirror

Pull image từ mirror nhân bản:

```bash
# Từ Docker Hub (hoạt động tốt)
docker pull mcr.io/mssql/server:2022-CU11-ubuntu-22.04

# Hoặc sử dụng Azure Container Registry của bạn (nếu có)
# docker pull your-registry.azurecr.io/mssql/server:2022
```

---

## 🔧 Quick Fix: Chuyển sang PostgreSQL

### Bước 1: Sử dụng docker-compose.postgres.yml

```bash
docker-compose -f docker-compose.postgres.yml up -d
```

### Bước 2: Cập nhật C# Backend

Cài đặt NuGet package cho PostgreSQL:
```bash
# Trong backend folder
dotnet add package Npgsql.EntityFrameworkCore.PostgreSQL
```

### Bước 3: Cập nhật appsettings.json

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Port=5432;Database=floria_db;Username=postgres;Password=postgres123;"
  }
}
```

### Bước 4: Cập nhật Program.cs

```csharp
// Thay thế SQL Server với PostgreSQL
builder.Services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(builder.Configuration.GetConnectionString("DefaultConnection")));
```

### Bước 5: Chạy migrations

```bash
dotnet ef database update
```

---

## 📊 Comparison

| Tính Năng | MSSQL Server | PostgreSQL | Local SQL |
|-----------|--------------|-----------|----------|
| Kích thước | 3GB+ | 400MB | N/A |
| Pull từ Docker | ❌ MCR lỗi | ✅ Docker Hub | N/A |
| Development | ✅ Tốt | ✅ Tốt | ✅ Tương tự Production |
| Production Ready | ✅ | ✅ | ❌ |
| Thiết lập | Phức tạp | Đơn giản | Rất đơn giản |

---

## 🔍 Kiểm Tra Kết Nối

```bash
# Test kết nối MCR
docker pull nginx:alpine  # Nếu hoạt động → Docker Hub OK
docker pull mcr.microsoft.com/azuretools:latest  # Kiểm tra MCR

# Nếu MCR lỗi
docker logs <container-id>
```

---

## 📞 Liên Hệ/Hỗ Trợ

Nếu vẫn gặp sự cố:
1. ✅ Thử Giải Pháp 1 (PostgreSQL) - Nên hoạt động ngay
2. ✅ Thử Giải Pháp 3.1 (Docker Proxy)
3. ✅ Liên hệ IT của công ty để cấu hình proxy
4. ✅ Sử dụng Local SQL Server (Giải Pháp 2)

---

## 📝 Tóm Tắt

**Nhanh nhất**: Dùng `docker-compose.postgres.yml` - hoạt động 100%
```bash
docker-compose -f docker-compose.postgres.yml up -d
```

Xem logs:
```bash
docker-compose -f docker-compose.postgres.yml logs -f
```
