# UAF-Data-Base

Universal Agent Framework - PostgreSQL 数据库项目

## 📖 简介

这是 Universal Agent Framework (UAF) 的独立数据库项目，提供 PostgreSQL 数据库服务。

**特点**:
- 🐘 PostgreSQL 16（Alpine 版本）
- 🐳 Docker Compose 一键启动
- 🔄 自动初始化数据库扩展
- 💾 持久化数据卷
- 🛠️ 性能优化配置
- 📦 备份脚本支持

---

## 🚀 快速开始

### 1. 配置环境变量

```bash
cp .env.example .env
# 编辑 .env，修改数据库密码（推荐）
```

### 2. 启动数据库

```bash
docker-compose up -d
```

### 3. 验证连接

```bash
# 查看日志
docker-compose logs -f postgres

# 连接到数据库
docker exec -it uaf-postgres psql -U postgres -d universal_agent

# 查看版本
docker exec -it uaf-postgres psql -U postgres -d universal_agent -c "SELECT version();"
```

### 4. 停止数据库

```bash
docker-compose down
```

---

## 📂 目录结构

```
UAF-Data-Base/
├── docker/
│   └── init-db.sql           # 数据库初始化脚本
├── scripts/                  # 运维脚本
│   ├── backup.sh            # 备份脚本
│   ├── restore.sh           # 恢复脚本
│   └── check.sh             # 健康检查脚本
├── backups/                  # 备份目录（自动生成）
├── docker-compose.yml        # Docker Compose 配置
├── .env                      # 环境变量（不提交）
├── .env.example              # 环境变量模板
├── .gitignore                # Git 忽略文件
└── README.md                 # 本文件
```

---

## 🔧 配置说明

### 环境变量

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `DB_USER` | `postgres` | 数据库用户名 |
| `DB_PASSWORD` | `postgres` | 数据库密码（⚠️ 生产环境请修改） |
| `DB_NAME` | `universal_agent` | 数据库名称 |
| `DB_PORT` | `5432` | 主机端口映射 |
| `POSTGRES_SHARED_BUFFERS` | `256MB` | 共享缓冲区（系统 RAM 的 25%） |
| `POSTGRES_MAX_CONNECTIONS` | `200` | 最大连接数 |
| `POSTGRES_WORK_MEM` | `4MB` | 每个连接的工作内存 |

### 性能调优

默认配置适合开发环境，生产环境建议：

| 系统内存 | shared_buffers | max_connections | work_mem |
|----------|----------------|-----------------|----------|
| 2GB      | 512MB          | 100             | 4MB      |
| 4GB      | 1GB            | 200             | 4MB      |
| 8GB      | 2GB            | 200             | 8MB      |
| 16GB     | 4GB            | 400             | 16MB     |

---

## 🔄 备份与恢复

### 手动备份

```bash
# 备份为压缩格式（推荐）
docker exec uaf-postgres pg_dump -U postgres -Fc universal_agent > backups/manual-$(date +%Y%m%d-%H%M%S).dump

# 备份为 SQL 文本
docker exec uaf-postgres pg_dump -U postgres universal_agent > backups/manual-$(date +%Y%m%d-%H%M%S).sql
```

### 恢复数据

```bash
# 从压缩格式恢复
docker exec -i uaf-postgres pg_restore -U postgres -d universal_agent < backups/manual-20240109.dump

# 从 SQL 文本恢复
docker exec -i uaf-postgres psql -U postgres -d universal_agent < backups/manual-20240109.sql
```

---

## 🔌 连接到数据库

### 从应用连接

**开发环境**（应用在本地）:
```
DATABASE_URL=postgresql+asyncpg://postgres:postgres@localhost:5432/universal_agent
```

**Docker 环境**（应用在容器内）:
```
DATABASE_URL=postgresql+asyncpg://postgres:postgres@uaf-postgres:5432/universal_agent
```

### 从其他工具连接

```bash
# psql
psql -h localhost -U postgres -d universal_agent

# TablePlus、DataGrip 等 GUI 工具
Host: localhost
Port: 5432
User: postgres
Password: postgres
Database: universal_agent
```

---

## 🛠️ 常用命令

### Docker Compose

```bash
# 启动
docker-compose up -d

# 停止
docker-compose down

# 重启
docker-compose restart

# 查看日志
docker-compose logs -f postgres

# 查看状态
docker-compose ps

# 删除所有数据（⚠️ 谨慎使用）
docker-compose down -v
```

### PostgreSQL

```bash
# 连接到数据库
docker exec -it uaf-postgres psql -U postgres -d universal_agent

# 执行 SQL 命令
docker exec -it uaf-postgres psql -U postgres -d universal_agent -c "SELECT * FROM sessions;"

# 查看数据库大小
docker exec -it uaf-postgres psql -U postgres -d universal_agent -c "SELECT pg_size_pretty(pg_database_size('universal_agent'));"

# 查看连接数
docker exec -it uaf-postgres psql -U postgres -d universal_agent -c "SELECT count(*) FROM pg_stat_activity;"
```

---

## 📊 监控

### 健康检查

```bash
# Docker healthcheck
docker inspect uaf-postgres | grep -A 10 Health

# 手动检查
docker exec uaf-postgres pg_isready -U postgres
```

### 查看性能

```bash
# 活跃连接
docker exec -it uaf-postgres psql -U postgres -d universal_agent -c "
SELECT state, count(*) FROM pg_stat_activity GROUP BY state;
"

# 慢查询（需要 pg_stat_statements 扩展）
docker exec -it uaf-postgres psql -U postgres -d universal_agent -c "
SELECT query, calls, mean_time FROM pg_stat_statements ORDER BY mean_time DESC LIMIT 10;
"
```

---

## 🔐 安全建议

1. **修改默认密码**
   ```bash
   # 编辑 .env
   DB_PASSWORD=your_strong_password_here
   ```

2. **限制网络访问**
   ```yaml
   # docker-compose.yml 中注释掉 ports
   # ports:
   #   - "5432:5432"
   ```

3. **启用 SSL**（生产环境）
   ```yaml
   environment:
     POSTGRES_SSL_MODE: require
   ```

4. **定期备份**
   - 设置 cron 任务自动备份
   - 备份文件存储到异地

---

## 🚀 部署到生产

### 迁移到云数据库

```bash
# 1. 导出数据
docker exec uaf-postgres pg_dump -U postgres -Fc universal_agent > backup.dump

# 2. 导入到云数据库
pg_restore -h CLOUD_DB_HOST -U postgres -d universal_agent backup.dump

# 3. 更新应用配置
# 修改 Universal-Agent-Backend/.env
DATABASE_URL=postgresql+asyncpg://user:pass@CLOUD_DB_HOST:5432/universal_agent
```

---

## 📝 License

Apache License 2.0

---

## 🔗 相关项目

- [Universal-Agent-Backend](https://github.com/your-org/Universal-Agent-Backend) - 应用后端项目
- [Universal-Agent-Framework](https://github.com/your-org/Universal-Agent-Framework) - 完整框架文档

---

**最后更新**: 2024-01-09
