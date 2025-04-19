---
title: BSON JSON 序列化 反序列化
date: 2025-04-16 21:32:19
categories:
 - 数据库
tags:
 - 数据库
 - mongodb
---

## 1. Json.NET  (Newtonsoft.Json)

非常流行的开源 .NET 库，用于处理 JSON 数据，它在 .NET 社区中广为人知，因此很多人直接称它为 Json.NET，而不是完整的命名空间 `Newtonsoft.Json`，它提供了一组类和方法，用于：

- **序列化**：将 C# 对象转换为 JSON 字符串
- **反序列化**：将 JSON 字符串转换回 C# 对象
- **自定义序列化**：通过特性（如 `[JsonConverter]`）或配置，允许开发者控制 JSON 的格式和行为

```c#
var person = new { Name = "Alice", Age = 30 };
string json = JsonConvert.SerializeObject(person);
// 输出: {"Name":"Alice","Age":30}

string json = "{\"Name\":\"Alice\",\"Age\":30}";
var person = JsonConvert.DeserializeObject<dynamic>(json);
// person.Name == "Alice"
```

> **JsonConvert** 是 **Newtonsoft.Json** 命名空间中的一个静态类，属于 Json.NET 库

## 2. MongoDB .NET Driver

当你通过 MongoDB .NET Driver 插入一个 C# 对象（如 CustomerManagerModel 或 MessageModel）到 MongoDB 时：

- 驱动会根据类的属性（如 `[BsonId]`、`[BsonRepresentation]`）将 C# 对象映射为 BSON 文档
- 这个过程不需要显式转换为 JSON，而是直接生成 BSON 二进制数据

> MongoDB 使用 **BSON** 作为其底层存储格式，C# 对象存储到 MongoDB 时, 直接被 MongoDB .NET Driver 转换为 BSON，而不是 JSON,
>
> 如果通过 REST API 从前端接收 JSON 数据，Json.NET 会将 JSON 反序列化为 C# 对象，然后 MongoDB .NET Driver 再将 C# 对象转为 BSON 存储

> MongoDB .NET Driver 用于 BSON, Json.NET 用于 JSON
>
> - MongoDB 的 .NET 驱动（MongoDB.Driver）提供了一个强大的序列化框架，用于将 C# 对象与 MongoDB 的 BSON（Binary JSON）格式相互转换
>
> - Json.NET 将 C# 对象序列化为 JSON 字符串, 或者将 JSON 字符串转反序列化回 C# 对象,

## 3. BSON vs JSON

**BSON**（Binary JSON）与 JSON 类似，但以二进制形式存储, MongoDB 使用 BSON 存储文档，因为：

- **高效性**：二进制格式减少存储空间和解析时间, 快速序列化和反序列化
- **丰富的数据类型**：支持 MongoDB 特有的类型（如 ObjectId 用于唯一标识）

### 3.1. 序列化和反序列化

- **序列化** 是将内存中的数据（如对象、数组）转换为可存储或传输的格式, 如二进制或文本
- **反序列化** 是将存储的格式转换回内存中的数据结构

### 3.2. 为什么 BSON 序列化/反序列化更快？

**JSON 的问题**

- **JSON 是纯文本格式**，序列化时需要将数据转换为字符串（比如数字 25 变成 "25"，加上引号、括号等）
- 反序列化时，程序需要逐字符解析文本，检查语法（比如 `{`、`"`、`,`），然后将字符串转换回正确的数据类型（`"25"` 变回数字 `25`）
- 这个过程涉及大量字符串操作，比较慢，尤其在处理大数据量时

**BSON 的优势**

- BSON 是二进制格式，数据直接以字节形式存储，接近计算机内存中的表示方式
- 序列化时，BSON 直接将数据（如数字、日期）按固定字节格式写入，无需转换为文本
- 反序列化时，程序读取固定长度的字节，直接还原为内存中的数据类型，无需复杂的文本解析

### 3.3. BSON 序列化过程

```json
{
  "name": "Alice",
  "age": 25
}
```

**1. 确定文档结构**

- MongoDB 客户端分析对象，识别字段名（name, age）和值（"Alice", 25）以及类型（字符串、整数）

**2. 分配二进制空间**

- BSON 为整个文档分配一个固定长度的二进制缓冲区
- 文档开头记录总长度（字节数），方便快速读取

**3. 编码字段, 每个字段按以下结构编码**

- **类型标识**：1 字节，表示数据类型（比如 \x02 表示字符串，\x10 表示 32 位整数）
- **字段名**：以空字节（\x00）终止的字符串
- **值**：根据类型编码（字符串带长度前缀，整数直接写字节）

示例

  - name: "Alice"
  - 类型：\x02（字符串）
  - 字段名："name\x00"（5 字节）
  - 值："\x06\x00\x00\x00Alice\x00"

  - age: 25
    
  - 类型：\x10（32 位整数）
    
  - 字段名："age\x00"（4 字节）
    
  - 值："\x19\x00\x00\x00"（4 字节，25 的二进制表示）

**4. 写入文档**

所有字段按顺序写入缓冲区，文档以 \x00 结尾, 最终 BSON 数据（简化表示）

```shell
\x16\x00\x00\x00               // 文档总长度（22 字节）
\x02name\x00\x06\x00\x00\x00Alice\x00  // name="Alice"
\x10age\x00\x19\x00\x00\x00           // age=25
\x00                           // 文档结束
```

### 3.4. 反序列化步骤

**读取文档总长度**：

- 读取开头 4 字节（\x16\x00\x00\x00），知道文档有 22 字节

**逐字段解析**：

- 读取类型标识（\x02），知道是字符串
- 读取字段名（"name\x00"），知道字段是 name
- 读取值（"\x06\x00\x00\x00Alice\x00"），解析为字符串 "Alice"
- 继续读取下一个字段，类型是 \x10（整数），字段名是 age，值是 25

**读取文档总长度**：

- 读取开头 4 字节（\x16\x00\x00\x00），知道文档有 22 字节。

**逐字段解析**：

- 读取类型标识（\x02），知道是字符串。
- 读取字段名（"name\x00"），知道字段是 name。
- 读取值（"\x06\x00\x00\x00Alice\x00"），解析为字符串 "Alice"。
- 继续读取下一个字段，类型是 \x10（整数），字段名是 age，值是 25

**还原对象**:

```json
{ name: "Alice", age: 25 }
```

>  **MongoDB 如何利用 BSON 元数据查询单个字段**
>
>  在上面的例子中，BSON 数据是：
>
>  ```
>  \x16\x00\x00\x00               // 文档总长度（22 字节）
>  \x02name\x00\x06\x00\x00\x00Alice\x00  // name="Alice"
>  \x10age\x00\x19\x00\x00\x00           // age=25
>  \x00                           // 文档结束
>  ```
>
>  关键元数据：
>
>  - 文档总长度（开头 4 字节）：告诉 MongoDB 整个文档有多大
>  - 字段类型（如 \x02, \x10）：表示字段是字符串、整数等
>  - 字段名（如 "name\x00"）：标识字段
>  - 值长度（如 \x06\x00\x00\x00）：对于字符串等变长数据，标明值的字节数
>
>  这些元数据让 MongoDB 可以快速定位字段，而无需读取无关部分

## 4. 注解如何工作的

不禁好奇为什么当存储对象到 mongodb 序列化为 BSON 或者 序列化为 json 时, 就会自动执行这些注解 这是怎么实现的 是框架自动处理吗?

```c#
using MongoDB.Bson;
using Newtonsoft.Json;

public class MessageModel
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; }

    [JsonConverter(typeof(CustomDateTimeConverter))]
    public DateTime CreateTime { get; set; } = DateTime.Now;
}
```

### 4.1. MongoDB 注解（MongoDB.Bson.Serialization.Attributes）

- **反射（Reflection）**：MongoDB 驱动在序列化或反序列化对象时，会通过反射检查类的结构，识别是否有特定的属性（如 `[BsonId]`、`[BsonRepresentation]`）
- **序列化器（Serializer）**：MongoDB 驱动内置了一套序列化器（`IBsonSerializer`），它们会根据注解动态调整序列化行为
  - `[BsonId]`：标记某个字段为主键（MongoDB 中的 `_id` 字段），驱动会确保这个字段被正确映射到 `_id`
  - `[BsonRepresentation(BsonType.ObjectId)]`：指定字段在 MongoDB 中存储为 ObjectId 类型，而不是普通的字符串

**具体流程：**

1. 创建一个 MessageModel 实例
2. 当你调用 MongoDB 驱动的插入方法（如 `collection.InsertOneAsync(model)`）
3. 驱动通过反射读取 `MessageModel` 类的元数据，发现 `Id` 字段有 `[BsonId]` 和 `[BsonRepresentation(BsonType.ObjectId)]`
4. 驱动将 `Id` 字段映射为 MongoDB 文档的 `_id` 字段，并确保其值符合 ObjectId 格式
5. 其他字段（如 `CreateTime`）也会根据默认或自定义的序列化规则转换为 BSON 格式

### 4.2. JSON 注解（Newtonsoft.Json）

**反射（Reflection）**：Json.NET 在序列化或反序列化对象时，也会通过反射检查类的属性，查找是否有 `[JsonConverter]` 等注解

**自定义转换器（JsonConverter）**：`[JsonConverter(typeof(CustomDateTimeConverter))]` 告诉 Json.NET 在序列化 CreateTime 字段时，使用 `CustomDateTimeConverter` 类来控制输出格式（例如，格式化日期时间为特定的字符串格式）

**序列化管道**：当你调用 Json.NET 的序列化方法（如 `JsonConvert.SerializeObject(model)`），Json.NET 会根据注解调用对应的转换器来处理字段