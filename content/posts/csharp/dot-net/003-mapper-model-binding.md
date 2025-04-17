---
title: IMapper & Model Binding
date: 2025-04-17 21:15:52
categories:
 - c#
tags:
 - c#
 - .net
---

## 1. `IMapper`

```c#
[Route("inventory")]
[ApiController]
public class InventoryController : ControllerBase
{
    private readonly InventoryService _inventoryService;
    private readonly IMapper _mapper;

    public InventoryController(
        InventoryService inventoryService, IMapper mapper)
    {
        _mapper = mapper;
        _inventoryService = inventoryService;
    }

    [HttpGet("stocklist")]
    public async Task<ActionResult<ResultDto>> ListAllStock()
    {
        var stockList = await _inventoryService.FindAllStock();
        return new ResultDto(200, "查询成功", _mapper.Map<List<InventoryModelDto>>(stockList));
    }
}

public class InventoryModelDto
{
    public string Id { get; set; }
    public int StockLevel { get; set; }
    public string ItemName { get; set; }
    public string LastUpdated { get; set; }
}

public class InventoryModel
{
    [BsonId]
    [BsonRepresentation(BsonType.ObjectId)]
    public string Id { get; set; }
    public int StockLevel { get; set; }
    public string ItemName { get; set; }
    [JsonConverter(typeof(CustomDateTimeConverter))]
    public DateTime LastUpdated { get; set; }
}
```

`AutoMapper` 是一个 .NET 库, 用于简化对象之间的映射, 它可以自动将一个对象的属性值复制到另一个对象的对应属性上, 减少手动编写繁琐的映射代码, 通常用于将数据库实体（如 `InventoryModel`）映射到 DTO（Data Transfer Object, 如 `InventoryModelDto`）, 以便在 API 返回数据时使用更轻量或特定格式的对象:

 **为什么需要映射？**

- `InventoryModel` 通常是数据库实体, 可能包含敏感字段或不适合直接暴露给客户端的数据, `InventoryModelDto` 是一个专为 API 响应设计的对象, 可能只包含客户端需要的字段

- DTO 可以调整数据的结构或格式, 使其更适合前端使用

**代码中的具体流程**

- ` _inventoryService.FindAllStock()` 返回一个 `List<InventoryModel>` 
- `_mapper.Map<List<InventoryModelDto>>(processlist)` 将这个列表中的每个 `InventoryModel` 对象转换为 `InventoryModelDto` 对象
- 最终结果被包装在 `ResultDto` 中，作为 API 的响应返回，状态码为 200，消息为“查询成功”

**类型不同会发生什么？** `DateTime LastUpdated` 到 `string LastUpdated` 的映射会发生什么?

- `AutoMapper` 支持 `DateTime` 到 `string` 的转换, 默认调用 `DateTime.ToString()`
- `[JsonConverter(typeof(CustomDateTimeConverter))]` 只在 JSON 序列化/反序列化时生效（例如，API 响应）
- `AutoMapper` 的映射是对象层面的操作，**不会调用 `CustomDateTimeConverter`**，除非在 `AutoMapper` 配置中显式指定

## 2. POST API 如何限制前端表单传递的数据字段

```c#
[Route("api/users")]
[ApiController]
public class UserController : ControllerBase
{
    private readonly UserService _userService;
    private readonly IMapper _mapper;

    public UserController(UserService userService, IMapper mapper)
    {
        _userService = userService;
        _mapper = mapper;
    }

    [HttpPost("create")]
    public async Task<ActionResult<UserDto>> CreateUser([FromBody] UserCreateDto userCreateDto)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        var user = _mapper.Map<User>(userCreateDto);
        var createdUser = await _userService.CreateUserAsync(user);
        return Ok(_mapper.Map<UserDto>(createdUser));
    }
}
```

假设 `UserCreateDto` 定义如下：

```c#
public class UserCreateDto
{
    [Required(ErrorMessage = "用户名是必填项")]
    [StringLength(50, ErrorMessage = "用户名长度不能超过50个字符")]
    public string Username { get; set; }

    [Required(ErrorMessage = "邮箱是必填项")]
    [EmailAddress(ErrorMessage = "邮箱格式不正确")]
    public string Email { get; set; }

    [Range(18, 100, ErrorMessage = "年龄必须在18到100岁之间")]
    public int Age { get; set; }
}
```

前端通过 POST 请求发送以下 JSON 数据到 `/api/users/create`：

```json
{
    "Username": "john_doe",
    "Email": "john@example.com",
    "Age": 25,
    "ExtraField": "some_value"
}
```

### 2.1. 如何限制前端表单字段？

**DTO 定义限制字段：**

- `UserCreateDto` 类定义了 API 接受的字段：`Username`、`Email` 和 `Age`
- 前端发送的 JSON 数据中，只有这些字段会被绑定到 UserCreateDto 对象的相应属性
- 额外的字段（如 `ExtraField`）不会被绑定，因为 `UserCreateDto` 中没有对应的属性, 这种限制是通过 DTO 的结构实现的

**处理前端数据的机制**：

- 当前端发送 POST 请求时，ASP.NET Core 使用 **模型绑定（Model Binding）** 机制将请求体中的 JSON 数据**反序列化**为 `UserCreateDto` 对象
- 由于 `UserCreateDto` 只有 `Username`、`Email` 和 `Age` 三个属性，`ExtraField` 会被忽略，不影响 API 的处理

**验证数据的有效性**：

- `UserCreateDto` 使用了数据注解（如 `[Required]`、`[StringLength]`、`[EmailAddress]`、`[Range]`）来定义验证规则
- 例如，如果前端发送的 JSON 缺少 `Username` 或 `Email`，或者 `Email` 格式不正确，ASP.NET Core 会将这些错误记录在 `ModelState` 中
- 代码中检查 `if (!ModelState.IsValid)`，如果验证失败，会返回 400 Bad Request 响应，包含具体的错误信息

> `ModelState` 很重要, 我们可以在 controller 中判断是否数据反序列化成功等:
>
> ```c#
> [HttpPost("user")]
> public async Task<IActionResult> CreateUser([FromBody] UserCreateDto userCreateDto) {
>  if (!ModelState.IsValid) {
>      ...
>  }
> }
> ```

### 2.2. ASP.NET 的机制

- **模型绑定**：将请求数据映射到 DTO，仅绑定 DTO 定义的属性
- **模型验证**：通过数据注解（如 `[Required]`、`[EmailAddress]`）和 `[ApiController]` 特性验证数据有效性
- **绑定属性**：如 `[FromBody]`，控制数据来源

这种机制类似于 Spring 框架的 `@RequestBody` 和 `@Valid`，但 ASP.NET Core 的 `[ApiController]` 提供了更自动化的验证流程

### 2.3. 默认检查哪些数据来源进行反序列化？

当不显式指定绑定源（如 `[FromBody]`、`[FromQuery]` 等）时，ASP.NET Core 的模型绑定系统会根据参数类型和上下文按以下优先级检查数据来源：

**复杂类型（如 DTO、类）**：

- **默认来源**：在 `[ApiController]` 控制器中，默认从**请求体**（`[FromBody]`）绑定，通常期望 `Content-Type` 为 `application/json` 或 `application/xml`
- 如果请求体不可用（例如，`Content-Type` 为 `application/x-www-form-urlencoded` 或 `multipart/form-data`），也可能尝试从**表单数据**（`[FromForm]`）绑定
- 如果没有 `[ApiController]`，ASP.NET Core 可能不会自动从请求体绑定复杂类型，导致参数为 null，除非显式指定` [FromBody]` 或 `[FromForm]`

**简单类型（如 string、int、bool）**：

- 默认来源
  1. **路由参数**（`[FromRoute]`）：如果参数名称匹配路由模板中的占位符（例如，`[Route("api/users/{id}")]`)
  2. **查询字符串**（`[FromQuery]`）：从 URL 的查询参数绑定（例如，`?name=john`）
  3. **表单数据**（`[FromForm]`）：如果请求是 `application/x-www-form-urlencoded` 或 `multipart/form-data`
- 简单类型不会默认从请求体绑定，除非显式使用 `[FromBody]`

> 当控制器方法期望一个复杂类型（如 `UserCreateDto`）并使用 `[FromBody]`（或 `[ApiController]` 默认推断为 `[FromBody]`），ASP.NET Core 期望请求体的 `Content-Type` 是 `application/json` 或 `application/xml`，因为这些格式可以直接反序列化为 C# 对象
>
> 如果请求的 `Content-Type` 是 `application/x-www-form-urlencoded` 或 `multipart/form-data`，ASP.NET Core 的 JSON 反序列化器无法解析这些格式，导致绑定失败（参数可能为 null 或抛出异常）

> `application/x-www-form-urlencoded` 表示请求的内容在 **HTTP 请求的 Body** 中，但它不是 JSON 格式，而是一串以键值对形式编码的字符串（格式如 `key1=value1&key2=value2`）
>
> 与 `application/json` 不同：
>
> - `application/x-www-form-urlencoded`：数据是扁平的键值对字符串，适合简单表单数据
> - `application/json`：数据是结构化的 JSON 对象，支持复杂嵌套结构

### 2.4. 查询字符串 如何绑定到后端方法?

后端代码:

```c#
[HttpPost("user")]
public async Task<ActionResult<ResultDto>> CreateNewUser(UserModelDto user, string currentuser)
```

前端代码:

```typescript
export const registerUser = (currentuser: string, data?: object) => {
  const _currentuser = encodeURIComponent(currentuser);
  return http.request<any>(
      "post", 
       myApi(`/user?currentuseruser=${_currentuser}`), {data});
};
```

上面我们说到, 在 `[ApiController]` 控制器中, 对于复杂类型如 `Dto`, 若不指定参数的数据来源, 则默认从**请求体**（`[FromBody]`）绑定, 因此 `UserModelDto user` 肯定是从 请求体中反序列化得到, 那 `string currentuser` 参数怎么办?

答案也很简单: `string currentuser` 是简单类型，且没有显式指定 `[FromBody]`, 所以默认从查询字符串绑定, 也就是前端的 `/user?currentuseruser=${_currentuser}`

### 2.5. 如果想上传文件，需要怎么办？

在 ASP.NET Core 中，文件上传通常通过 `multipart/form-data` 格式实现，结合 `[FromForm]` 和 `IFormFile` 类型来处理文件和表单数据

**定义 DTO 和控制器方法**：

- 使用 `[FromForm]` 绑定表单数据
- 使用 `IFormFile` 或 `IFormFileCollection` 接收上传的文件
- 确保方法支持 `multipart/form-data` 请求

**前端发送文件**：

- 使用 HTML 表单（`enctype="multipart/form-data"`）或 AJAX 请求（如 `FormData`）发送文件和相关数据

```c#
public class UserCreateDto
{
    [Required(ErrorMessage = "用户名是必填项")]
    public string Username { get; set; }

    [Required(ErrorMessage = "邮箱是必填项")]
    [EmailAddress(ErrorMessage = "邮箱格式不正确")]
    public string Email { get; set; }

    public int Age { get; set; }
}

[Route("api/users")]
[ApiController]
public class UserController : ControllerBase
{
    private readonly IWebHostEnvironment _environment;

    public UserController(IWebHostEnvironment environment)
    {
        _environment = environment;
    }

    [HttpPost("upload")]
    public async Task<IActionResult> UploadUser([FromForm] UserCreateDto userCreateDto, [FromForm] IFormFile file)
    {
        if (!ModelState.IsValid)
        {
            return BadRequest(ModelState);
        }

        if (file == null || file.Length == 0)
        {
            return BadRequest("No file uploaded.");
        }

        // 验证文件类型（例如，只允许图片）
        var allowedExtensions = new[] { ".jpg", ".jpeg", ".png" };
        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (!allowedExtensions.Contains(extension))
        {
            return BadRequest("Invalid file type. Only JPG and PNG are allowed.");
        }

        // 保存文件到服务器（例如，wwwroot/uploads 目录）
        var uploadsFolder = Path.Combine(_environment.WebRootPath, "uploads");
        ...

        // 假设保存用户信息到数据库
        // var user = new User { Username = userCreateDto.Username, Email = userCreateDto.Email, Age = userCreateDto.Age };
        // await _userService.SaveUserAsync(user);

        return Ok(new { Message = "User and file uploaded successfully", FilePath = filePath });
    }
}
```

