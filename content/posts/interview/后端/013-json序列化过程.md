---
title: JSON 序列化的过程
date: 2025-04-22 18:46:20
categories:
 - 面试
tags:
 - 面试
 - 计算机基础
 - 后端面试
---

看了点序列化相关的东西, 发现也并不简单, 想了解为什么 JSON 序列化效率低, 为什么其他的比如 Ptotobuf 效率高, 还是要了解一下 JSON 序列化怎么做的, 具体实现

### 1. **JSON序列化的核心概念**
JSON序列化本质上是一个**数据转换**过程，目标是将内存中的数据结构（例如Python的字典、Java的对象、Go的结构体等）转换为符合JSON规范的字符串, **JSON规范定义了数据结构**，包括对象（`{}`）、数组（`[]`）、字符串（`""`）、数字、布尔值（`true`/`false`）、`null`等, 序列化的底层实现通常涉及:

- **数据结构解析**：递归遍历输入数据结构的层次结构
- **类型映射**：将编程语言的原生类型映射到JSON支持的类型
- **编码**：将数据按照JSON语法规则生成字符串，通常使用UTF-8编码
- **内存管理**：高效分配和操作字符串缓冲区
- **错误处理**：处理不支持的类型或循环引用等问题

### 2. **底层实现步骤**
以一个典型的后端语言（如Python、Java或Go）为例，JSON序列化库（例如Python的`json`模块、Java的Jackson、Go的`encoding/json`）的底层实现大致遵循以下步骤：

#### **(1) 输入数据解析**
- **输入**：序列化函数接收一个数据结构，例如Python中的`{"name": "Alice", "age": 30, "scores": [85, 90]}`。
- **递归遍历**：序列化器会检查数据的类型（对象、数组、基本类型等），并递归处理嵌套结构。
  - 对于对象（如Python的`dict`），遍历键值对。
  - 对于数组（如Python的`list`），遍历每个元素。
  - 对于基本类型（如字符串、数字），直接映射到JSON格式。

#### **(2) 类型映射与校验**
- **类型检查**：序列化器验证输入数据是否可以映射到JSON支持的类型。例如：
  - Python的`str` → JSON字符串（需转义特殊字符，如`"`、`\n`）。
  - Python的`int`/`float` → JSON数字（注意浮点数的精度问题）。
  - Python的`list`/`tuple` → JSON数组。
  - Python的`dict`（键必须是字符串）→ JSON对象。
  - Python的`None` → JSON的`null`。
- **不支持的类型**：如果遇到JSON不支持的类型（例如Python的`set`、复杂对象），序列化器会：
  - 抛出异常（例如Python的`TypeError`）。
  - 或者通过自定义序列化逻辑（例如Python的`default`参数）将其转换为支持的类型。
- **循环引用检测**：对于对象图中的循环引用（如对象A引用B，B又引用A），序列化器需要检测并抛出错误，或通过特殊配置忽略。

#### **(3) 字符串生成**
- **缓冲区分配**：序列化器通常使用一个动态字符串缓冲区（例如C语言中的字符数组、Go的`bytes.Buffer`）来构建JSON字符串。
- **递归拼接**：
  - **对象**：生成`{`，遍历键值对，生成`"key": value`（键需要加引号，值递归序列化），用逗号分隔，最后追加`}`。
  - **数组**：生成`[`，递归序列化每个元素，用逗号分隔，最后追加`]`。
  - **字符串**：将原始字符串用双引号包裹，并对特殊字符（如`\n`、`\t`、`"`）进行转义（例如，`"hello\nworld"`变为`"hello\\nworld"`）。
  - **数字**：直接将数字转换为字符串表示（注意浮点数精度问题，例如`1.23e-4`）。
  - **布尔值**：映射为`true`或`false`。
  - **null**：直接输出`null`。
- **转义规则**：字符串转义遵循JSON标准（RFC 8259），例如：
  - 引号`"` → `\"`
  - 反斜杠`\` → `\\`
  - 换行符`\n` → `\\n`
  - 非ASCII字符（例如中文）通常编码为UTF-8，或者根据配置转义为`\uXXXX`（Unicode码点）。

#### **(4) 编码与输出**
- **UTF-8编码**：JSON标准要求字符串使用UTF-8编码。序列化器会确保所有字符（包括非ASCII字符，如中文）正确编码为UTF-8字节序列。
- **输出**：最终生成的字符串可以：
  - 存储到内存（返回字符串）。
  - 写入文件。
  - 发送到网络（如HTTP响应）。

#### **(5) 优化与内存管理**
- **性能优化**：
  - **预分配缓冲区**：高性能序列化器（如Go的`encoding/json`）会预估输出字符串的大小，减少动态扩容。
  - **避免递归栈溢出**：对于深层嵌套数据结构，使用迭代或尾递归优化。
  - **零拷贝**：某些场景下，序列化器直接操作字节流，减少字符串拷贝。
- **内存管理**：
  - 序列化器通常使用临时缓冲区，完成后释放内存。
  - 对于大对象，可能会使用流式序列化（streaming），边解析边生成，避免一次性加载整个对象到内存。

### 3. **具体语言的实现细节**
不同语言的JSON序列化库在底层实现上有些差异，以下是几个常见后端语言的简要分析：

#### **Python（`json`模块）**
- **实现**：Python的`json`模块基于C（`cjson`）或纯Python实现。核心是`JSONEncoder`类，递归遍历数据结构。
- **细节**：
  - 使用`PyObject`接口检查Python对象的类型。
  - 字符串转义通过C级别的字符处理实现，高效支持UTF-8。
  - 支持自定义序列化（通过`default`函数）。
- **性能**：C实现的`json`模块很快，但对于超大对象可能因递归而消耗较多栈空间。

#### **Java（Jackson）**
- **实现**：Jackson使用流式处理（`JsonGenerator`），支持高性能序列化。
- **细节**：
  - 通过反射解析Java对象的字段或getter方法。
  - 支持注解（如`@JsonProperty`）自定义序列化规则。
  - 使用`StringBuilder`或字节流构建输出。
- **性能**：Jackson通过缓存和流式处理，适合处理大型JSON。

#### **Go（`encoding/json`）**
- **实现**：Go的`encoding/json`基于反射（`reflect`包）解析结构体，结合`bytes.Buffer`生成字符串。
- **细节**：
  - 使用`MarshalJSON`接口支持自定义序列化。
  - 字符串转义直接操作字节，性能高效。
  - 对结构体字段使用标签（如`json:"name"`）控制序列化。
- **性能**：Go的JSON序列化速度快，但反射可能带来轻微开销（可用`ffjson`等工具优化）。

### 4. **常见问题与处理**
- **循环引用**：如前所述，序列化器通常抛出错误，或者通过配置忽略循环部分。
- **浮点数精度**：浮点数可能导致意外的表示（如`1.1`变为`1.1000000000000001`）。高质量序列化器会遵循IEEE 754标准。
- **非字符串键**：JSON要求对象键是字符串。如果输入数据包含非字符串键（如Python的`{1: "value"}`），序列化器会报错或自动转换（如将`1`转为`"1"`）。
- **性能瓶颈**：对于大对象，序列化可能成为瓶颈。优化方案包括：
  - 使用流式序列化。
  - 预计算输出大小。
  - 避免不必要的类型检查。

### 5. **底层伪代码示例**
以下是一个简化的JSON序列化伪代码，展示核心逻辑：

```python
def serialize(obj, buffer):
    if obj is None:
        buffer.append("null")
    elif isinstance(obj, bool):
        buffer.append("true" if obj else "false")
    elif isinstance(obj, (int, float)):
        buffer.append(str(obj))
    elif isinstance(obj, str):
        buffer.append('"')
        for char in obj:
            if char in ESCAPE_CHARS:  # e.g., '"', '\n'
                buffer.append(ESCAPE_CHARS[char])  # 转义
            else:
                buffer.append(char)
        buffer.append('"')
    elif isinstance(obj, list):
        buffer.append("[")
        for i, item in enumerate(obj):
            serialize(item, buffer)
            if i < len(obj) - 1:
                buffer.append(",")
        buffer.append("]")
    elif isinstance(obj, dict):
        buffer.append("{")
        for i, (key, value) in enumerate(obj.items()):
            if not isinstance(key, str):
                raise TypeError("Keys must be strings")
            serialize(key, buffer)
            buffer.append(":")
            serialize(value, buffer)
            if i < len(obj) - 1:
                buffer.append(",")
        buffer.append("}")
    else:
        raise TypeError(f"Unsupported type: {type(obj)}")

buffer = []
serialize({"name": "Alice", "age": 30, "scores": [85, 90]}, buffer)
return "".join(buffer)
```

### 6. **总结**
JSON序列化的底层过程涉及递归遍历数据结构、类型映射、字符串生成和编码。核心挑战在于高效处理复杂数据结构、正确转义字符、优化性能和内存使用。不同语言的实现（如Python的`json`、Java的Jackson、Go的`encoding/json`）在细节上有所不同，但都遵循JSON标准（RFC 8259）。作为后端开发工程师，理解这些底层机制有助于调试问题、优化性能，以及在必要时实现自定义序列化逻辑。

如果你有具体语言或场景（例如处理超大JSON、自定义序列化）的进一步问题，可以告诉我，我会更深入探讨！

