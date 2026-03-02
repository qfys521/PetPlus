# PetPlus API 文档

本文档是根据 PetPlus 项目的 HTTP 请求自动生成的 OpenAPI 3.0 规范文档。

## 文档位置

- **OpenAPI 规范文件**: `openapi.yaml`
- **在线查看**: 可以使用以下工具查看和测试 API

## 如何使用

### 1. 在线查看（推荐）

#### 使用 Swagger Editor
1. 访问 [Swagger Editor](https://editor.swagger.io/)
2. 点击 `File` -> `Import file`
3. 选择 `openapi.yaml` 文件
4. 即可查看和测试 API

#### 使用 Swagger UI
将 `openapi.yaml` 文件部署到 Swagger UI 即可生成交互式 API 文档。

### 2. 本地查看

#### 使用 npx
```bash
npx @redocly/cli preview-docs openapi.yaml
```

#### 使用 Docker
```bash
docker run -p 8080:8080 -e SWAGGER_JSON=/openapi.yaml -v $(pwd):/usr/share/nginx/html swaggerapi/swagger-ui
```

然后访问 http://localhost:8080

### 3. 生成客户端代码

使用 OpenAPI Generator 可以生成多种语言的客户端代码：

```bash
# 生成 TypeScript 客户端
npx @openapitools/openapi-generator-cli generate \
  -i openapi.yaml \
  -g typescript-axios \
  -o ./generated/typescript-client

# 生成 Java 客户端
npx @openapitools/openapi-generator-cli generate \
  -i openapi.yaml \
  -g java \
  -o ./generated/java-client

# 生成 Python 客户端
npx @openapitools/openapi-generator-cli generate \
  -i openapi.yaml \
  -g python \
  -o ./generated/python-client
```

## API 概览

### 基础信息
- **服务器地址**: https://place.wxtcc.com.cn
- **认证方式**: API Key（通过 query 参数 `key` 传递）
- **响应格式**: JSON

### API 模块

#### 1. 用户管理
- `POST /officelease/pets/petsUserLogin` - 用户登录
- `POST /officelease/pets/setUserinfo` - 更新用户信息

#### 2. 宠物管理
- `GET /officelease/pets/getPets` - 获取宠物列表
- `POST /officelease/pets/updatePets` - 更新宠物信息

#### 3. 喂食管理
- `GET /officelease/pets/feedingSchedules` - 获取喂食计划
- `POST /officelease/pets/addFeedingDevices` - 添加喂食设备
- `GET /officelease/pets/getFeedingRecord` - 获取喂食记录
- `POST /officelease/pets/putFeeding` - 执行喂食操作

#### 4. 健康管理
- `GET /officelease/pets/getPetHealthHistory` - 获取宠物健康档案

#### 5. 环境监测
- `GET /officelease/pets/getMonitoring` - 获取环境监测数据

### 响应格式

所有 API 返回统一的响应格式：

```json
{
  "code": "1",
  "message": "操作成功",
  "data": { ... },
  "timestamp": "2026-03-02T10:00:00Z"
}
```

其中：
- `code`: 业务状态码，"1" 表示成功，其他值表示失败
- `message`: 响应消息
- `data`: 实际返回的数据
- `timestamp`: 响应时间戳

### 认证流程

1. 调用登录接口获取 `key`：
   ```bash
   POST /officelease/pets/petsUserLogin
   {
     "userName": "your_username",
     "psd": "your_password"
   }
   ```

2. 从响应中获取 `data.key`

3. 后续所有请求都需要携带此 `key` 参数：
   - GET 请求：作为 query 参数 `?key=xxx`
   - POST 请求：在请求体中包含 `key` 字段

## 开发指南

### 请求示例

#### 用户登录
```bash
curl -X POST "https://place.wxtcc.com.cn/officelease/pets/petsUserLogin" \
  -H "Content-Type: application/json" \
  -d '{
    "userName": "testuser",
    "psd": "password123"
  }'
```

#### 获取宠物列表
```bash
curl -X GET "https://place.wxtcc.com.cn/officelease/pets/getPets?key=your-key&userId=123"
```

#### 获取健康档案
```bash
curl -X GET "https://place.wxtcc.com.cn/officelease/pets/getPetHealthHistory?key=your-key&petId=1&startTime=2026-03-01T00:00:00Z&endTime=2026-03-02T23:59:59Z&page=1&size=10"
```

### 错误处理

当请求失败时，响应的 `code` 字段会返回非 "1" 的值：

```json
{
  "code": "401",
  "message": "认证失败，请检查key是否有效",
  "timestamp": "2026-03-02T10:00:00Z"
}
```

常见错误码：
- `400`: 请求参数错误
- `401`: 认证失败或密钥无效
- `500`: 服务器内部错误

## 技术说明

本 OpenAPI 文档是基于以下源代码文件生成的：

- `/main/src/main/ets/api/services.ets` - API 服务定义
- `/main/src/main/ets/api/types.ets` - 类型定义
- `/main/src/main/ets/api/httpClient.ets` - HTTP 客户端实现

文档生成日期：2026-03-02

## 许可证

本文档遵循 PetPlus 项目的许可证。
