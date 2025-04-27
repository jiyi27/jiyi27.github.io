---
title: Controller 和 Service 按照业务分还是实体分 - REST API 设计
date: 2025-04-26 20:17:20
categories:
 - 面试
tags:
 - 面试
 - 后端面试
---

## 1. 写在前面

**按业务划分的优点**

- **前端开发友好**：前端开发人员容易找到对应的接口，因为划分方式和前端页面功能一致
- **团队协作:** 前端说“这个页面坏了”时，后端能秒定位到对应 Controller
  - 前提是每个 Controller 的命名清晰, 和前端功能高度

**按业务划分的缺点**

- **代码重复 臃肿**：不同业务模块可能需要类似的功能，导致代码重复

- **单一职责原则被破坏**：一个 Controller 承担了多种不同领域的职责

**业界比较成熟的做法, 按领域对象划分Controller**：

```
├── controller
│   ├── OrderController.java (所有订单相关操作)
│   ├── ProductController.java (所有商品相关操作)
│   ├── MerchantController.java (所有商家相关操作)
│   └── StatisticsController.java (各种统计功能)
├── service
│   ├── OrderService.java
│   ├── ProductService.java
│   ├── MerchantService.java
│   └── StatisticsService.java
```

- **代码复用性提高**：同一领域的功能集中在一处，减少重复代码
- **维护性增强**：后端开发人员更容易根据领域找到相关代码
- **职责清晰**：每个Controller和Service只负责单一领域

## 2. RESTful API 设计

假如现在要开发一个在线学习平台, 有管理员, 普通用户, 管理员可以录入一些专有术语, 录入课程信息, 以及平台的访客等统计数据, 普通用户可以发帖子, 讨论, 查询术语, 观看课程等

### 2.1. 认证授权 API

```apl
# 登录
POST /api/v1/auth/login
# 登出
POST /api/v1/auth/logout
# 刷新令牌
POST /api/v1/auth/refresh-token
# 获取当前用户信息
GET /api/v1/auth/me
```

### 2.2. 用户管理 API

```apl
# 获取用户列表(管理员)
GET /api/v1/users
# 创建用户(管理员)
POST /api/v1/users
# 获取特定用户
GET /api/v1/users/{id}
# 更新用户信息
PUT /api/v1/users/{id}
# 删除用户(管理员)
DELETE /api/v1/users/{id}
# 用户激活/停用(管理员)
PATCH /api/v1/users/{id}/status
# 修改密码
PUT /api/v1/users/{id}/password
# 获取用户学习记录
GET /api/v1/users/{id}/learning-records
```

### 2.2. 术语管理 API

```apl
# 获取术语列表
GET /api/v1/terms
# 创建术语(管理员)
POST /api/v1/terms
# 获取特定术语
GET /api/v1/terms/{id}
# 更新术语(管理员)
PUT /api/v1/terms/{id}
# 删除术语(管理员)
DELETE /api/v1/terms/{id}
# 搜索术语
GET /api/v1/terms/search?q={query}
# 获取术语分类列表
GET /api/v1/term-categories
# 获取特定分类下的术语
GET /api/v1/term-categories/{id}/terms
```

### 2.3. 社区管理 API

```apl
# 获取帖子列表
GET /api/v1/posts
# 创建帖子
POST /api/v1/posts
# 获取特定帖子
GET /api/v1/posts/{id}
# 更新帖子
PUT /api/v1/posts/{id}
# 删除帖子
DELETE /api/v1/posts/{id}

# 获取帖子评论
GET /api/v1/posts/{postId}/comments
# 创建评论
POST /api/v1/posts/{postId}/comments
# 获取特定评论
GET /api/v1/comments/{id}
# 更新评论
PUT /api/v1/comments/{id}
# 删除评论
DELETE /api/v1/comments/{id}

# 点赞帖子
POST /api/v1/posts/{id}/likes
# 取消点赞
DELETE /api/v1/posts/{id}/likes

# 讨论区(论坛)
GET /api/v1/forums
# 获取指定论坛的帖子
GET /api/v1/forums/{id}/posts
```

### 2.4. 统计分析 API

```apl
# 获取平台访问统计(管理员)
GET /api/v1/statistics/visits
# 获取课程访问统计(管理员)
GET /api/v1/statistics/courses/{id}/visits
# 获取用户活跃度统计(管理员)
GET /api/v1/statistics/users/activity
# 获取课程完成率统计(管理员)
GET /api/v1/statistics/courses/completion
# 获取热门课程统计
GET /api/v1/statistics/courses/popular
# 获取热门帖子统计
GET /api/v1/statistics/posts/popular
```

### 2.5. 通知 API

```apl
# 获取用户通知
GET /api/v1/users/{userId}/notifications
# 标记通知为已读
PATCH /api/v1/notifications/{id}/read
# 删除通知
DELETE /api/v1/notifications/{id}
```

### 2.6. 文件上传 API

```apl
# 上传课程视频/图片等
POST /api/v1/uploads/courses
# 上传用户头像
POST /api/v1/uploads/avatars
# 上传帖子附件
POST /api/v1/uploads/posts
```

> **`v1` 在 API 路径中表示 "version 1"**
>
> - **兼容性维护** 当 API 需要进行重大更改（比如改变请求/响应格式、删除字段、更改资源路径）时, 直接修改会导致现有客户端应用崩溃, 版本控制允许你创建新版本的 API, 同时保持旧版本可用
> - **平滑过渡** 版本控制使客户端可以在自己方便的时候逐步迁移到新版本, 而不必立即适应变化

## 3. 后端鉴权怎么做? RBAC 角色控制

上传修改术语的接口, 只有管理员才可以做, 普通用户不可以, 这在前后端是如何配合实现的呢?

### 3.1. 后端 Role-Based Access Control 数据库表设计

Role-Based Access Control 是一种访问控制模型，通过将权限分配给角色（Role），再将角色分配给用户（User），来管理用户对系统资源的访问权限

```sql
// 数据库设计：用户-角色-权限三表设计
@Entity
public class User {
    @Id
    private Long id;
    private String username;
    // ...
    
    @ManyToMany
    private Set<Role> roles = new HashSet<>();
}

@Entity
public class Role {
    @Id
    private Long id;
    private String name; // ROLE_ADMIN, ROLE_MANAGER, ROLE_USER
    
    @ManyToMany
    private Set<Permission> permissions = new HashSet<>();
}

@Entity
public class Permission {
    @Id
    private Long id;
    private String name; // 如：COURSE_PRICE_EDIT, COURSE_CREATE
}
```

> 这里可能有人会问, Role 的 permissions 直接存一个 字符串 Set 不就好了吗, 为什么 要存加一个 Permission 实体呢? 
>
> - 如果直接存储字符串（如 "COURSE_PRICE_EDIT"）, 无法保证权限名称的一致性, 例如, 可能会出现拼写错误（如 "COURSE_PRICE_EDT"）
>
> - 除此之外, 如果我们觉得 `COURSE_PRICE_EDIT` 名字定义的不清晰, 那就可以重新修改 Permission 的这个字段, 然后所有的用户 Permission 都修改了, 而不是 去修改每一个 Role 的 Permission

### 3.2. Spring Security Filter Chain

```java
@Configuration
@EnableWebSecurity
@EnableGlobalMethodSecurity(prePostEnabled = true)
public class SecurityConfig extends WebSecurityConfigurerAdapter {
    
    @Override
    protected void configure(HttpSecurity http) throws Exception {
        http
            .csrf().disable()
            .authorizeRequests()
                .antMatchers("/api/v1/auth/**").permitAll()
                .antMatchers(HttpMethod.GET, "/api/v1/terms/**").permitAll()
                .antMatchers(HttpMethod.POST, "/api/v1/terms/**").hasRole("ADMIN")
                .antMatchers(HttpMethod.PUT, "/api/v1/terms/**").hasRole("ADMIN")
                .antMatchers(HttpMethod.DELETE, "/api/v1/terms/**").hasRole("ADMIN")
                // 其他路径配置
                .anyRequest().authenticated()
            .and()
            .sessionManagement().sessionCreationPolicy(SessionCreationPolicy.STATELESS)
            .and()
            .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);
    }
}
```

有人好奇, 这个 Spring Security 的用户信息是怎么获得的, 答案是在这个 Filter Chain 执行之前, 我们可以再写一步验证逻辑, 比如 JWT 验证逻辑, JWT 验证逻辑中我们可以把 解析出的用户 id, 角色 都放到新创建的用户实例中, 然后传递到 filter chain 的下一步逻辑, Filter Chain 嘛, 分为多步, 当然是可以插入不同的步骤了:

```java
@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {
    
    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain) 
            throws ServletException, IOException {
        
        String token = extractTokenFromRequest(request);
        
        if (token != null && jwtTokenProvider.validateToken(token)) {
            String userId = jwtTokenProvider.getUserIdFromToken(token);
            List<String> roles = jwtTokenProvider.getRolesFromToken(token);
            
            UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
                userId, null, roles.stream().map(SimpleGrantedAuthority::new).collect(Collectors.toList())
            );
            
            SecurityContextHolder.getContext().setAuthentication(authentication);
        }
        
        filterChain.doFilter(request, response);
    }
}
```

> JWT Token 是可以存用户信息的, 比如 角色定义: JWT由三部分组成, Header, Payload, Signature, JWT 的 Header 和 Payload 部分是经过 Base64 URL 编码的, 本质上是“明文”的, 不适合在Payload中存储敏感信息, 只有Signature部分是经过加密的, 用于验证数据的完整性

当然也可以通过在 Controller 方法进行权限验证, 二选一就行:

```java
// 使用Spring Security的注解控制
@RestController
@RequestMapping("/api/v1/terms")
public class TermController {
    
    @GetMapping
    // 所有用户可访问
    public ResponseEntity<List<Term>> getAllTerms() {
        // 实现获取所有术语的逻辑
        return ResponseEntity.ok(termService.findAll());
    }
    
    @PostMapping
    // 只有ADMIN角色可以访问
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<Term> createTerm(@RequestBody TermRequest termRequest) {
        // 实现创建术语的逻辑
        return ResponseEntity.status(HttpStatus.CREATED).body(termService.create(termRequest));
    }
}
```

## 4. 前端鉴权怎么做? 基于角色的路由控制

### 4.1. 存储用户角色和令牌

```js
// 登录处理
async function login(username, password) {
  try {
    const response = await axios.post('/api/v1/auth/login', { username, password });
    const { token } = response.data;
    
    // 存储token
    localStorage.setItem('token', token);
    
    // 解析JWT获取用户信息(可选)
    const decodedToken = decodeJwtToken(token);
    const userRole = decodedToken.roles;
    localStorage.setItem('userRole', userRole);
    
    return true;
  } catch (error) {
    console.error('Login failed:', error);
    return false;
  }
}
```

### 4.2. API请求拦截器

```js
// 在Axios中设置请求拦截器
axios.interceptors.request.use(
  config => {
    const token = localStorage.getItem('token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
  },
  error => {
    return Promise.reject(error);
  }
);

// 响应拦截器处理401和403错误
axios.interceptors.response.use(
  response => response,
  error => {
    if (error.response) {
      if (error.response.status === 401) {
        // 未授权，清除token并跳转到登录页
        localStorage.removeItem('token');
        router.push('/login');
      } else if (error.response.status === 403) {
        // 权限不足
        router.push('/forbidden');
      }
    }
    return Promise.reject(error);
  }
);
```

### 4.3. 基于角色的路由控制

```js
// Vue Router 中的路由配置示例
const routes = [
  {
    path: '/terms',
    component: TermsList,
    meta: { requiresAuth: false } // 所有人可访问
  },
  {
    path: '/terms/create',
    component: TermCreate,
    meta: { requiresAuth: true, requiredRoles: ['ADMIN'] } // 只有管理员可访问
  },
  {
    path: '/terms/edit/:id',
    component: TermEdit,
    meta: { requiresAuth: true, requiredRoles: ['ADMIN'] } // 只有管理员可访问
  }
];

// 路由守卫
router.beforeEach((to, from, next) => {
  const token = localStorage.getItem('token');
  const userRole = localStorage.getItem('userRole');
  
  if (to.meta.requiresAuth && !token) {
    // 需要认证但没有token
    next('/login');
  } else if (to.meta.requiredRoles && !to.meta.requiredRoles.includes(userRole)) {
    // 没有所需角色
    next('/forbidden');
  } else {
    next();
  }
});
```

### 4.4. UI级别的权限控制

```js
// React组件示例
function TermsManagement() {
  const userRole = localStorage.getItem('userRole');
  const isAdmin = userRole === 'ADMIN';
  
  return (
    <div className="terms-page">
      <h1>术语列表</h1>
      
      {/* 术语列表 - 所有人可见 */}
      <TermsList />
      
      {/* 管理按钮 - 只有管理员可见 */}
      {isAdmin && (
        <div className="admin-actions">
          <button onClick={() => navigate('/terms/create')}>添加术语</button>
        </div>
      )}
      
      {/* 术语条目中的编辑/删除按钮也应该有条件渲染 */}
      <TermsListItem 
        term={term}
        showActions={isAdmin} 
      />
    </div>
  );
}

// 术语列表项组件
function TermsListItem({ term, showActions }) {
  return (
    <div className="term-item">
      <h3>{term.name}</h3>
      <p>{term.definition}</p>
      
      {showActions && (
        <div className="actions">
          <button onClick={() => navigate(`/terms/edit/${term.id}`)}>编辑</button>
          <button onClick={() => deleteTerm(term.id)}>删除</button>
        </div>
      )}
    </div>
  );
}
```

## 5. 实践例子 API 设计

我正在实现一个看板相关的 API, 目前我们的 API 是按照业务划分的, 我们是一个玩具厂, 看板需要统计下面这些信息:

- 所有的加工件的统计信息, 也就是总数目, 次品率
- 所有员工的统计信息 比如 请假多少人 在上班的多少人
- 所有玩具的统计信息, 玩具是由加工件拼成的, 比如总玩具数目, 按时完成组装比率, 超时比率
- 所有玩具按年份统计的信息, 此时应该跟觉 query 比如 ?year = 2025 返回 12 个月分别的 总数目, 按时比率, 超时比率
- 所有订单的统计信息, 这个订单统计只是统计订单总数目, 完整的有多少, 没完成的有多少
- 所有订单的列表, 比如显示每个订单的 客户名, 玩具名, 玩具数目, 实际交付日期, 约定交付日期

### 5.1. 按业务划分

`GET /api/v1/dashboard/components/stats` - 加工件统计

`GET /api/v1/dashboard/employees/stats` - 员工统计

`GET /api/v1/dashboard/toys/stats` - 玩具统计

`GET /api/v1/dashboard/toys/stats/monthly?year=2025` - 玩具年度月度统计

`GET /api/v1/dashboard/orders/stats` - 订单统计

`GET /api/v1/dashboard/orders` - 订单列表

这样的做法有一些缺点:

- 可能导致API重复, 如订单数据在多个业务功能中重复定义

- 不符合标准REST设计原则
  - REST (Representational State Transfer) 设计原则强调以资源为中心的设计，每个URL应该代表一个资源，而不是操作或功能
  - REST设计使用HTTP方法(GET, POST, PUT, DELETE)表示操作, 而URL路径表示资源, 这使API更加标准化、可预测且易于理解

除此之外随着业务复杂度增加, API架构可能变得混乱, 假设玩具厂系统随着时间发展，新增了以下业务功能:

- 看板功能 (已有)
- 质量控制功能
- 供应链管理功能
- 销售分析功能

按业务功能划分时可能出现的API结构:

```apl
# 看板功能
GET /api/v1/dashboard/orders
GET /api/v1/dashboard/toys/stats

# 组件 玩具 质量控制功能
GET /api/v1/quality-control/components
GET /api/v1/quality-control/toys/defects

# 供应链管理功能
GET /api/v1/supply-chain/components/inventory
GET /api/v1/supply-chain/orders/pending

# 销售分析功能
GET /api/v1/sales-analytics/orders/performance
GET /api/v1/sales-analytics/toys/popular
```

------

**一致性难维护**: 各业务功能下对相同资源的表示可能不一致

看板功能中的订单:

```json
// GET /api/v1/dashboard/orders/123
{
  "order_id": 123,
  "customer_name": "ABC玩具批发",
  "delivery_date": "2025-05-10",
  "status": "completed",
  "total_toys": 500
}
```

供应链功能中的订单:

```json
// GET /api/v1/supply-chain/orders/123
{
  "id": 123,
  "client": "ABC玩具批发",
  "due_date": "2025-05-10", 
  "order_status": 2,
  "items_count": 500,
  "priority_level": "high"
}
```

销售分析功能中的订单:

```json
// GET /api/v1/sales-analytics/orders/123
{
  "orderNumber": 123,
  "buyer": "ABC玩具批发",
  "deadline": "2025-05-10",
  "isCompleted": true,
  "quantity": 500,
  "revenue": 25000
}
```

字段命名不一致：同一概念有多种表示（order_id, id, orderNumber）

数据类型不一致：状态使用了字符串、数字和布尔值三种不同表示

字段选择不一致：各API返回的字段集合不同

数据格式不一致：日期格式可能会有差异

业务逻辑不一致：例如，"完成"状态的定义在不同模块可能不同

前端开发困难：开发人员需要为每个API编写不同的解析和处理逻辑

维护成本高：字段更改需要在多处同步修改

测试复杂化：需要对同一资源的多种表示进行测试

用户体验差：可能导致UI展示的不一致

文档负担：需要记录每个业务功能下资源的特定表示

更好的解决方案 采用以资源为中心的API设计

```json
GET /api/v1/orders/123                  // 获取基本订单信息
GET /api/v1/orders/123?fields=all       // 获取详细订单信息
GET /api/v1/orders/123?view=dashboard   // 可选的视图参数
```

```json
// 所有订单API返回一致的基本结构
{
  "id": 123,
  "customer": {
    "id": 45,
    "name": "ABC玩具批发"
  },
  "dates": {
    "created": "2025-04-01T10:30:00Z",
    "due": "2025-05-10T00:00:00Z",
    "completed": "2025-05-08T15:20:00Z"
  },
  "status": {
    "code": 2,
    "name": "completed"
  },
  "items": {
    "count": 500,
    "types": 3
  },
  "priority": "high",
  "financial": {
    "total": 25000,
    "currency": "CNY"
  }
}
```

 使用查询参数控制返回字段

```json
GET /api/v1/orders/123?fields=id,customer,status
```

```json
{
  "id": 123,
  "customer": {
    "id": 45,
    "name": "ABC玩具批发"
  },
  "status": {
    "code": 2,
    "name": "completed"
  }
}
```

统一业务逻辑层实现

```json
// 统一的订单服务
@Service
public class OrderService {
    // 单一的状态计算逻辑
    public boolean isCompleted(Order order) {
        return order.getStatus().getCode() == 2;
    }
    
    // 统一的订单完成率计算
    public double calculateCompletionRate(List<Order> orders) {
        if (orders.isEmpty()) return 0;
        
        long completed = orders.stream()
            .filter(this::isCompleted)
            .count();
            
        return (double) completed / orders.size();
    }
}
```

为不同业务需求提供专门的统计API，但基于相同的资源表示

```json
GET /api/v1/orders/stats                    // 基本订单统计
GET /api/v1/orders/stats?view=dashboard     // 看板所需统计
GET /api/v1/orders/stats?view=supply-chain  // 供应链所需统计
GET /api/v1/orders/stats?view=sales         // 销售分析所需统计
```

同一个接口, 如何根据不同的查询参数返回不同的数据:

```java
// 1. Controller实现 - 处理资源和查询参数
@RestController
@RequestMapping("/api/v1/orders")
public class OrderController {
    
    private final OrderService orderService;
    
    public OrderController(OrderService orderService) {
        this.orderService = orderService;
    }
    
    // 获取单个订单信息，支持fields和view参数
    @GetMapping("/{id}")
    public ResponseEntity<OrderDTO> getOrder(
            @PathVariable Long id,
            @RequestParam(required = false) String fields,
            @RequestParam(required = false, defaultValue = "basic") String view) {
        
        // 获取原始订单
        Order order = orderService.findById(id);
        if (order == null) {
            return ResponseEntity.notFound().build();
        }
        
        // 根据view参数选择适当的DTO转换器
        OrderDTO dto = switch(view.toLowerCase()) {
            case "dashboard" -> OrderDTOConverter.toDashboardView(order);
            case "supply-chain" -> OrderDTOConverter.toSupplyChainView(order);
            case "sales" -> OrderDTOConverter.toSalesView(order);
            case "all" -> OrderDTOConverter.toFullView(order);
            default -> OrderDTOConverter.toBasicView(order);
        };
        
        // 如果指定了fields参数，过滤DTO中的字段
        if (fields != null && !fields.isEmpty() && !fields.equals("all")) {
            dto = filterFields(dto, fields);
        }
        
        return ResponseEntity.ok(dto);
    }
    
    // 获取订单统计信息，支持view参数
    @GetMapping("/stats")
    public ResponseEntity<OrderStatsDTO> getOrderStats(
            @RequestParam(required = false, defaultValue = "basic") String view,
            @RequestParam(required = false) String period) {
            
        // 根据period确定时间范围
        LocalDate startDate = null;
        LocalDate endDate = LocalDate.now();
        
        if (period != null) {
            startDate = switch(period.toLowerCase()) {
                case "day" -> endDate.minusDays(1);
                case "week" -> endDate.minusWeeks(1);
                case "month" -> endDate.minusMonths(1);
                case "year" -> endDate.minusYears(1);
                default -> null;
            };
        }
        
        // 获取订单列表
        List<Order> orders = orderService.findOrdersByDateRange(startDate, endDate);
        
        // 根据view参数选择适当的统计计算方法
        OrderStatsDTO stats = switch(view.toLowerCase()) {
            case "dashboard" -> orderService.calculateDashboardStats(orders);
            case "supply-chain" -> orderService.calculateSupplyChainStats(orders);
            case "sales" -> orderService.calculateSalesStats(orders);
            default -> orderService.calculateBasicStats(orders);
        };
        
        return ResponseEntity.ok(stats);
    }
    
    // 辅助方法：根据fields参数过滤DTO中的字段
    private OrderDTO filterFields(OrderDTO dto, String fieldsParam) {
        Set<String> fields = Arrays.stream(fieldsParam.split(","))
                .map(String::trim)
                .collect(Collectors.toSet());
                
        // 创建一个新DTO，仅包含请求的字段
        OrderDTO filteredDTO = new OrderDTO();
        
        // 使用反射或手动设置字段
        if (fields.contains("id")) {
            filteredDTO.setId(dto.getId());
        }
        if (fields.contains("customer")) {
            filteredDTO.setCustomer(dto.getCustomer());
        }
        if (fields.contains("status")) {
            filteredDTO.setStatus(dto.getStatus());
        }
        // ... 其他字段
        
        return filteredDTO;
    }
}

// 2. 服务层 - 处理具体的业务逻辑
@Service
public class OrderService {
    
    private final OrderRepository orderRepository;
    
    public OrderService(OrderRepository orderRepository) {
        this.orderRepository = orderRepository;
    }
    
    public Order findById(Long id) {
        return orderRepository.findById(id).orElse(null);
    }
    
    public List<Order> findOrdersByDateRange(LocalDate startDate, LocalDate endDate) {
        if (startDate == null) {
            return orderRepository.findAll(); // 或使用分页
        }
        return orderRepository.findByCreatedDateBetween(startDate, endDate);
    }
    
    // 基本订单统计
    public OrderStatsDTO calculateBasicStats(List<Order> orders) {
        OrderStatsDTO stats = new OrderStatsDTO();
        
        stats.setTotalOrders(orders.size());
        stats.setCompletedOrders((int) orders.stream()
                .filter(order -> "completed".equals(order.getStatus().getName()))
                .count());
        stats.setCompletionRate(calculateCompletionRate(orders));
        
        return stats;
    }
    
    // 看板所需统计
    public OrderStatsDTO calculateDashboardStats(List<Order> orders) {
        OrderStatsDTO stats = calculateBasicStats(orders); // 包含基本统计
        
        // 添加看板特定统计
        stats.setOnTimeDelivery(calculateOnTimeDeliveryRate(orders));
        stats.setAverageProcessingTime(calculateAverageProcessingTime(orders));
        
        return stats;
    }
    
    // 供应链所需统计
    public OrderStatsDTO calculateSupplyChainStats(List<Order> orders) {
        OrderStatsDTO stats = calculateBasicStats(orders); // 包含基本统计
        
        // 添加供应链特定统计
        stats.setBackorderRate(calculateBackorderRate(orders));
        stats.setMaterialShortages(calculateMaterialShortages(orders));
        
        return stats;
    }
    
    // 销售分析所需统计
    public OrderStatsDTO calculateSalesStats(List<Order> orders) {
        OrderStatsDTO stats = calculateBasicStats(orders); // 包含基本统计
        
        // 添加销售特定统计
        stats.setTotalRevenue(calculateTotalRevenue(orders));
        stats.setAverageOrderValue(calculateAverageOrderValue(orders));
        
        return stats;
    }
    
    // 辅助计算方法
    private double calculateCompletionRate(List<Order> orders) {
        if (orders.isEmpty()) return 0;
        
        long completed = orders.stream()
                .filter(order -> "completed".equals(order.getStatus().getName()))
                .count();
                
        return (double) completed / orders.size();
    }
    
    // ... 其他辅助计算方法
}

// 3. DTO层 - 不同视图的数据传输对象
public class OrderDTO {
    private Long id;
    private CustomerDTO customer;
    private OrderDatesDTO dates;
    private OrderStatusDTO status;
    private ItemsDTO items;
    private String priority;
    private FinancialDTO financial;
    
    // Getters and setters
    // ...
}

// 4. DTO转换器 - 处理不同视图的转换
public class OrderDTOConverter {
    
    // 基本视图
    public static OrderDTO toBasicView(Order order) {
        OrderDTO dto = new OrderDTO();
        dto.setId(order.getId());
        
        CustomerDTO customerDto = new CustomerDTO();
        customerDto.setId(order.getCustomer().getId());
        customerDto.setName(order.getCustomer().getName());
        dto.setCustomer(customerDto);
        
        OrderStatusDTO statusDto = new OrderStatusDTO();
        statusDto.setCode(order.getStatus().getCode());
        statusDto.setName(order.getStatus().getName());
        dto.setStatus(statusDto);
        
        // 设置基本订单信息...
        
        return dto;
    }
    
    // 完整视图
    public static OrderDTO toFullView(Order order) {
        // 包含所有可能的字段
        OrderDTO dto = toBasicView(order);
        
        // 添加额外的详细信息...
        OrderDatesDTO datesDto = new OrderDatesDTO();
        datesDto.setCreated(order.getCreatedDate());
        datesDto.setDue(order.getDueDate());
        datesDto.setCompleted(order.getCompletedDate());
        dto.setDates(datesDto);
        
        // 设置其他详细信息...
        
        return dto;
    }
    
    // 看板视图
    public static OrderDTO toDashboardView(Order order) {
        // 针对看板UI优化的字段集
        OrderDTO dto = new OrderDTO();
        // 设置看板需要的字段...
        return dto;
    }
    
    // 供应链视图
    public static OrderDTO toSupplyChainView(Order order) {
        // 针对供应链管理优化的字段集
        OrderDTO dto = new OrderDTO();
        // 设置供应链需要的字段...
        return dto;
    }
    
    // 销售视图
    public static OrderDTO toSalesView(Order order) {
        // 针对销售分析优化的字段集
        OrderDTO dto = new OrderDTO();
        // 设置销售分析需要的字段...
        return dto;
    }
}

// 5. 统计DTO - 包含订单统计信息
public class OrderStatsDTO {
    private int totalOrders;
    private int completedOrders;
    private double completionRate;
    private double onTimeDelivery;
    private double averageProcessingTime;
    private double backorderRate;
    private int materialShortages;
    private double totalRevenue;
    private double averageOrderValue;
    
    // Getters and setters
    // ...
}
```

----------

**难以发现API**: 开发者可能不清楚某个资源的信息在哪个业务功能下

假设一个前端开发者需要获取"次品率最高的5种加工件"：

- 他可能先尝试 `/api/v1/components/defect-rates`（按资源的直觉）
- 找不到后，需要猜测这个数据可能在哪个业务模块下
  - 是在 `/api/v1/dashboard/...` 下？
  - 还是 `/api/v1/quality-control/...` 下？
  - 或者 `/api/v1/production/...` 下？

没有一个明确的指导原则，开发者需要查阅文档或询问后端团队才能找到正确的API。如果文档不完善，这会极大地降低开发效率

----

**重复实现**: 后端可能需要为每个业务功能单独实现相似的资源处理逻辑

```java
// 看板模块中的实现
@RequestMapping("/api/v1/dashboard/orders/stats")
public OrderStats getDashboardOrderStats() {
    List<Order> orders = orderRepository.findAll();
    int total = orders.size();
    int completed = 0;
    
    for (Order order : orders) {
        if (order.getStatus().equals("completed")) {
            completed++;
        }
    }
    
    double completionRate = (double) completed / total;
    // ...返回结果
}

// 销售分析模块中的类似实现
@RequestMapping("/api/v1/sales-analytics/performance")
public SalesPerformance getSalesPerformance() {
    List<Order> orders = orderRepository.findAll();
    int totalOrders = orders.size();
    int finishedOrders = 0;
    
    for (Order order : orders) {
        if (order.getStatus() == OrderStatus.COMPLETED) {
            finishedOrders++;
        }
    }
    
    double orderCompletionRate = (double) finishedOrders / totalOrders;
    // ...返回结果
}
```

两处代码实现了几乎相同的逻辑

一个用字符串比较状态，一个用枚举比较（潜在bug）

命名不一致（completed vs finishedOrders）

如果订单完成率的计算逻辑需要更改（例如加入"部分完成"的状态），必须修改多处代码

### 5.2. 实体 业务混用划分

**基础实体API**

```apl
# 加工件相关
GET /api/v1/components
GET /api/v1/components/{id}
POST /api/v1/components
...

# 员工相关
GET /api/v1/employees
GET /api/v1/employees/{id}
...

# 玩具相关
GET /api/v1/toys
GET /api/v1/toys/{id}
...

# 订单相关
GET /api/v1/orders
GET /api/v1/orders/{id}
...
```

**看板特定API（聚合数据）**

```apl
# 看板总览
GET /api/v1/dashboard/overview

# 特定统计聚合
GET /api/v1/dashboard/stats?entities=components,employees,toys,orders
```

**各实体统计API**

```apl
# 在各实体下添加统计接口
GET /api/v1/components/stats
GET /api/v1/employees/stats
GET /api/v1/toys/stats
GET /api/v1/toys/stats/monthly?year=2025
GET /api/v1/orders/stats
```

