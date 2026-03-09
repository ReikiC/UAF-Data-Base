# UAF-Data-Base

Universal Agent Framework - PostgreSQL 数据库项目

## 📖 简介

这是 Universal Agent Framework (UAF) 的独立数据库项目，提供 PostgreSQL 数据库服务。

**特点**:
- 🐘 PostgreSQL 16（Alpine 版本）
- 🐳 Docker Compose 一键启动
- 🎨 pgAdmin 4 Web 管理界面
- 🔄 自动初始化数据库扩展
- 💾 持久化数据卷
- 🛠️ 性能优化配置
- 📦 备份脚本支持

---

## 关联项目

### UAF 核心项目
| 项目 | 说明 | 地址 |
|------|------|------|
| **UAF-Orchestrator** | Agent 编排框架（LangChain + LangGraph） | [https://github.com/ReikiC/UAF-Orchestrator](https://github.com/ReikiC/UAF-Orchestrator) |
| **UAF-Frontend-nuomi** | 前端界面（React + TypeScript + Vite） | [https://github.com/ReikiC/UAF-Frontend-nuomi](https://github.com/ReikiC/UAF-Frontend-nuomi) |
| **UAF-Data-Base** | PostgreSQL 数据库配置 | [https://github.com/ReikiC/UAF-Data-Base](https://github.com/ReikiC/UAF-Data-Base) |

### RAG 业务模块

| 项目 | 说明 | 地址 |
|------|------|------|
| **UAF-MCP-RAG-Frontend** | 知识库前端界面 | [https://github.com/ReikiC/UAF-MCP-RAG-Frontend](https://github.com/ReikiC/UAF-MCP-RAG-Frontend) |
| **UAF-MCP-RAG-Server** | RAG 后端服务（MCP 协议） | [https://github.com/ReikiC/UAF-MCP-RAG-Server](https://github.com/ReikiC/UAF-MCP-RAG-Server) |
| **UAF-MCP-RAG-DB** | RAG 向量数据库支持 | [https://github.com/ReikiC/UAF-MCP-RAG-DB](https://github.com/ReikiC/UAF-MCP-RAG-DB) |

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

#### PostgreSQL 配置

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `DB_USER` | `postgres` | 数据库用户名 |
| `DB_PASSWORD` | `postgres` | 数据库密码（⚠️ 生产环境请修改） |
| `DB_NAME` | `universal_agent` | 数据库名称 |
| `DB_PORT` | `5432` | 主机端口映射 |
| `POSTGRES_SHARED_BUFFERS` | `256MB` | 共享缓冲区（系统 RAM 的 25%） |
| `POSTGRES_MAX_CONNECTIONS` | `200` | 最大连接数 |
| `POSTGRES_WORK_MEM` | `4MB` | 每个连接的工作内存 |

#### pgAdmin 配置

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `PGADMIN_DEFAULT_EMAIL` | `admin@admin.com` | pgAdmin 登录邮箱 |
| `PGADMIN_DEFAULT_PASSWORD` | `admin` | pgAdmin 登录密码（⚠️ 生产环境请修改） |
| `PGADMIN_PORT` | `5050` | pgAdmin Web 界面端口 |

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

### 使用 pgAdmin (Web 管理界面)

项目已集成 pgAdmin 4，提供图形化的数据库管理界面。

#### 访问 pgAdmin

1. 打开浏览器访问: **http://localhost:5050**
2. 登录凭据:
   - Email: `admin@admin.com`
   - Password: `admin`

#### 添加数据库连接

登录后按以下步骤添加服务器：

1. 点击 **"Add New Server"** 或右键 "Servers" → "Register" → "Server"

2. **General 标签页**:
   - Name: `UAF PostgreSQL` (自定义名称)

3. **Connection 标签页**:

   | 字段 | 值 |
   |------|-----|
   | Host | `uaf-postgres` |
   | Port | `5432` |
   | Maintenance database | `universal_agent` |
   | Username | `postgres` |
   | Password | `postgres` |

4. 点击 **Save** 保存连接

#### 查看数据

连接成功后，导航路径：

```
Servers → UAF PostgreSQL → Databases → universal_agent → Schemas → public → Tables
  ├─ sessions  (会话表)
  └─ messages  (消息表)
```

右键点击表 → **View Data/Edit Data** → **All Rows** 即可查看数据。

> 💡 **提示**: pgAdmin 和 PostgreSQL 在同一个 Docker 网络中，使用容器名 `uaf-postgres` 作为 Host。

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
