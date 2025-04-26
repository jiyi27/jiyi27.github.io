---
title: 技术选型 MySQL 还是 MongoDB?
date: 2025-03-30 11:09:56
categories:
 - 面试
tags:
 - 面试
 - 数据库面试
 - mongodb
 - mysql
---

选 NoSQL 的几个理由, 一定不是多表关联 join 慢, 所以选嵌套, 而是:

- 想快速启动小专案测试 idea
- 资料格式不确定(unstable schema)，而未来很有可能调整
- 资料之间没有复杂的关联(无结构, 无组织)、或未来读取资料时不需要使用JOIN 的功能

> In my 14 years of experience, most. It's not that there's anything wrong with using Mongo if it fits your use case, I've used it a handful of times, but I find that data, by nature, is almost always relational, or becomes relational very quickly as you start adding features. Then you either have to spend time and effort changing, or use Mongo like it's a relation database, which you should never do as it defeats the point. You'd be surprised how many times I've seen Mongo instances like this. Programs push data around, and it's usually related data.
>
> Tbh Mongo isn't used that much in production from what I've seen really. The world runs on SQL and that's not going to change. I think Mongo lends itself better to small "todo" apps and such, so it tends to get used in a lot of tutorials online. When you're starting out and you're watching these, it can give you a false sense that everyone is using it for everything.
>
> I'd say if you think you have a complete picture of all your data requirements and know that they're not going to change, and it's not relational, Mongo is a great choice.
>
> If you don't have the full picture yet, or something might change, going relational is more future proof. Relational databases can handle not having relations between tables just fine, and you can add them later if needed. Mongo doesn't really handle relational data well at all. [Reddit](https://www.reddit.com/r/learnprogramming/comments/gzvyoa/comment/ftiwqzm/?utm_source=share&utm_medium=web3x&utm_name=web3xcss&utm_term=1&utm_content=share_button)

> **边缘场景**
>
> MongoDB is not magically faster. If you store the same data, organised in basically the same fashion, and access it exactly the same way, then you really shouldn't expect your results to be wildly different. After all, MySQL and MongoDB are both GPL, so if Mongo had some magically better IO code in it, then the MySQL team could just incorporate it into their codebase.
>
> People are seeing real world MongoDB performance largely because MongoDB allows you to query in a different manner that is more sensible to your workload.
>
> For example, consider a design that persisted a lot of information about a complicated entity in a normalised fashion. This could easily use dozens of tables in MySQL (or any relational db) to store the data in normal form, with many indexes needed to ensure relational integrity between tables.
>
> Now consider the same design with a document store. If all of those related tables are subordinate to the main table (and they often are), then you might be able to model the data such that the entire entity is stored in a single document. In MongoDB you can store this as a single document, in a single collection. This is where MongoDB starts enabling superior performance.
>
> In MongoDB, to retrieve the whole entity, you have to perform:
>
> - One index lookup on the collection (assuming the entity is fetched by id)
> - Retrieve the contents of one database page (the actual binary json document)
>
> So a b-tree lookup, and a binary page read. Log(n) + 1 IOs. If the indexes can reside entirely in memory, then 1 IO.
>
> In MySQL with 20 tables, you have to perform:
>
> - One index lookup on the root table (again, assuming the entity is fetched by id)
> - With a clustered index, we can assume that the values for the root row are in the index
> - 20+ range lookups (hopefully on an index) for the entity's pk value
> - These probably aren't clustered indexes, so the same 20+ data lookups once we figure out what the appropriate child rows are.
>
> So the total for mysql, even assuming that all indexes are in memory (which is harder since there are 20 times more of them) is about 20 range lookups.
>
> These range lookups are likely comprised of random IO — different tables will definitely reside in different spots on disk, and it's possible that different rows in the same range in the same table for an entity might not be contiguous (depending on how the entity has been updated, etc).
>
> So for this example, the final tally is about *20 times* more IO with MySQL per logical access, compared to MongoDB.
>
> This is how MongoDB can boost performance *in some use cases*.
>
> [Stackoverflow](https://stackoverflow.com/a/9703513/16317008)

## 1. 多表关联查询 MongoDB 处于劣势

**MongoDB 不支持原生的 JOIN 操作**, MongoDB 并不像 MySQL 那样在**引擎层面原生支持 JOIN**，它是通过聚合管道的 `$lookup` 操作符来模拟关联查询的

### 1.1. MySQL 如何做关联查询

假设我们有四个数据集合/表：

1. `users`：存储用户信息
2. `orders`：存储订单信息，关联到用户
3. `order_items`：存储订单中的商品项，关联到订单和商品
4. `products`：存储商品信息

```sql
CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100),
    email VARCHAR(100)
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT, -- Foreign Key to users
    order_date DATE,
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    name VARCHAR(100),
    price DECIMAL(10, 2)
);

CREATE TABLE order_items (
    item_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT, -- Foreign Key to orders
    product_id INT, -- Foreign Key to products
    quantity INT,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- 假设在所有 Foreign Key 字段上都建立了索引
CREATE INDEX idx_orders_user ON orders (user_id);
CREATE INDEX idx_items_order ON order_items (order_id);
CREATE INDEX idx_items_product ON order_items (product_id);
```

**目标:** 查询用户 "Alice" 购买过的所有商品的名称和价格，以及对应的订单 ID

```sql
SELECT
    o.order_id,
    p.name AS product_name,
    p.price AS product_price
FROM
    users u
JOIN -- 第 1 次连接: users -> orders
    orders o ON u.user_id = o.user_id
JOIN -- 第 2 次连接: orders -> order_items
    order_items oi ON o.order_id = oi.order_id
JOIN -- 第 3 次连接: order_items -> products
    products p ON oi.product_id = p.product_id
WHERE
    u.name = 'Alice';
```

**MySQL 处理过程（概念性）：**

**查询优化器分析阶段**

- 当你执行一个包含多表 JOIN 的 SQL 语句时，MySQL 不会简单地按照你编写的顺序执行
- 优化器会分析表的统计信息，包括：
  - 表的大小（行数）
  - 每个列的数据分布情况
  - 可用的索引
  - 条件谓词的选择性（如 `WHERE u.name = 'Alice'` 会过滤掉多少行）

**执行计划生成**

- 优化器会评估多种可能的连接顺序
- 例如，虽然您编写的是 `users → orders → order_items → products`，但优化器可能决定使用 `users(过滤Alice) → orders → products → order_items` 或其他顺序
- 优化器会选择估计成本最低的执行计划

**连接算法选择**

- 根据表的大小和索引情况，MySQL 会选择不同的连接算法

### 1.2. MongoDB 的实现

```javascript
// users collection
{ _id: ObjectId("user1"), name: "Alice", email: "alice@example.com" }

// orders collection
{ _id: ObjectId("order1"), user_id: ObjectId("user1"), order_date: ISODate(...) }
{ _id: ObjectId("order2"), user_id: ObjectId("user1"), order_date: ISODate(...) }

// products collection
{ _id: ObjectId("prodA"), name: "Laptop", price: 1200 }
{ _id: ObjectId("prodB"), name: "Mouse", price: 25 }

// order_items collection
{ _id: ObjectId("item1"), order_id: ObjectId("order1"), product_id: ObjectId("prodA"), quantity: 1 }
{ _id: ObjectId("item2"), order_id: ObjectId("order1"), product_id: ObjectId("prodB"), quantity: 1 }
{ _id: ObjectId("item3"), order_id: ObjectId("order2"), product_id: ObjectId("prodA"), quantity: 2 }

// 假设在 `orders.user_id`, `order_items.order_id`, `order_items.product_id` 上有索引
db.orders.createIndex({ user_id: 1 });
db.order_items.createIndex({ order_id: 1 });
db.order_items.createIndex({ product_id: 1 });
```

查询语句 (使用聚合管道和 `$lookup`):

```js
db.users.aggregate([
  // 阶段 1: 找到用户 Alice
  { $match: { name: "Alice" } },

  // 阶段 2: 关联 orders 集合 (类似 JOIN users ON users._id = orders.user_id)
  {
    $lookup: {
      from: "orders",           // 目标集合
      localField: "_id",        // 当前集合 (users) 的字段
      foreignField: "user_id",  // 目标集合 (orders) 的字段
      as: "user_orders"       // 输出数组的字段名
    }
  },
  // 结果: Alice 文档 + user_orders: [ {order1 doc}, {order2 doc} ]

  // 阶段 3: 展开 user_orders 数组 (每个订单成为一个独立文档)
  { $unwind: "$user_orders" },
  // 结果: { Alice doc, user_orders: {order1 doc} }, { Alice doc, user_orders: {order2 doc} }

  // 阶段 4: 关联 order_items 集合 (类似 JOIN orders ON orders._id = order_items.order_id)
  {
    $lookup: {
      from: "order_items",
      localField: "user_orders._id", // 上一阶段展开后的订单 ID
      foreignField: "order_id",
      as: "items"
    }
  },
  // 结果: { Alice doc, user_orders: {order1}, items: [ {item1}, {item2} ] }, { Alice doc, user_orders: {order2}, items: [ {item3} ] }

  // 阶段 5: 展开 items 数组
  { $unwind: "$items" },
  // 结果: {..., items: {item1}}, {..., items: {item2}}, {..., items: {item3}}

  // 阶段 6: 关联 products 集合 (类似 JOIN order_items ON order_items.product_id = products._id)
  {
    $lookup: {
      from: "products",
      localField: "items.product_id", // 上一阶段展开后的商品 ID
      foreignField: "_id",
      as: "product_details"
    }
  },
  // 结果: {..., items: {item1}, product_details: [{prodA}]}, {..., items: {item2}, product_details: [{prodB}]}, {..., items: {item3}, product_details: [{prodA}]}

  // 阶段 7: 展开 product_details 数组
  { $unwind: "$product_details" },
  // 结果: {..., product_details: {prodA}}, {..., product_details: {prodB}}, {..., product_details: {prodA}}

  // 阶段 8: 投影 (选择最终需要的字段)
  {
    $project: {
      _id: 0, // 不显示 user 的 _id
      order_id: "$user_orders._id",
      product_name: "$product_details.name",
      product_price: "$product_details.price"
    }
  }
  // 最终结果: { order_id: "order1", product_name: "Laptop", price: 1200 }, { order_id: "order1", product_name: "Mouse", price: 25 }, { order_id: "order2", product_name: "Laptop", price: 1200 }
])
```

**MongoDB 处理过程及潜在性能问题分析：**

1. **阶段式执行：** 聚合管道是按顺序执行每个阶段的, 每个阶段的输出是下一个阶段的输入
2. `$lookup` 的代价：
   - **阶段 2 (`$lookup` orders):** 找到 Alice 后，拿着 Alice 的 `_id` 去 `orders` 集合查询, 如果 `orders.user_id` 有索引，这一步通常很快
   - **阶段 4 (`$lookup` order_items):** 经过 `$unwind` 后，假设 Alice 有 M 个订单, MongoDB 需要对这 M 个文档**分别**执行 `lookup` 操作, 即，拿着每个订单的 `_id` 去 `order_items` 集合中查询, 相当于 M 次对 `order_items` 的查询
   - **阶段 6 (`$lookup` products):** 假设 Alice 的 M 个订单总共有 N 个商品项（经过 `$unwind` 后产生 N 个文档）MongoDB 需要对这 N 个文档**分别**执行 `lookup` 操作，拿着每个商品项的 `product_id` 去 `products` 集合查询。这相当于 N 次对 `products` 的查询
3. **`$unwind` 的代价：** `$unwind` 操作会增加管道中流动的文档数量, 如果一个用户有很多订单，每个订单有很多商品，那么中间阶段的文档数量会急剧膨胀，加大了后续阶段的处理负担
4. **重复查询：** 注意在阶段 6，如果 Alice 多次购买了同一个商品 `prodA`（来自不同订单或同一订单的不同 `item` 记录），`$lookup` 可能会多次去 `products` 集合查找 `prodA` 的信息（虽然缓存可能有所帮助，但查询动作本身是针对每个输入文档触发的）
5. **优化限制：** 虽然 MongoDB 的聚合框架和 `$lookup` 也在不断优化，但这种**按文档流逐步处理和多次独立查询外部集合**的模式，相比于关系型数据库**全局优化、基于集合的连接算法**，在多层关联、数据量大的情况下，更容易遇到性能瓶颈, 优化器很难像 SQL 那样进行彻底的连接顺序重排或选择根本不同的连接算法（如 Hash Join）

**对比之下性能明显低于 MySQL 的 JOIN 操作**

## 2. join 算法

### 2.1. 什么是表连接？
**users 表**：

| id   | name    |
| ---- | ------- |
| 1    | Alice   |
| 2    | Bob     |
| 3    | Charlie |

**orders 表**：
| id   | user_id | amount |
| ---- | ------- | ------ |
| 1    | 1       | 100    |
| 2    | 2       | 200    |
| 3    | 1       | 150    |

查询每个用户的所有订单：

```sql
SELECT u.name, o.amount FROM users u JOIN orders o ON u.id = o.user_id;
```

### 2.2. 索引嵌套循环连接（Index Nested-Loop Join, INLJ）

#### 2.2.1. 基本思想
索引嵌套循环连接利用**索引**来加速连接过程, 当连接列（比如 `orders.user_id`）上有索引时，这种方式非常高效

> 一般建立外键约束的时候, 就应该手动在该列上建立索引, 因为外键基本上都是 一对多 关系中用来连接查询的, 比如 用户 - 订单, 一个用户对应多个订单, 那订单表中就应该放一个用户 id, 建立外键约束和索引, 因为未来一定会用到查找某个用户的订单

#### 2.2.2. 工作原理
- MySQL 选择一个表作为**外层表**（通常是行数较少的表），比如 `users`
- 对于 `users` 表的每一行，MySQL 用 `id` 的值在 `orders` 表的 `user_id` 索引上查找匹配的行
- 因为有索引，查找速度很快（接近 O(1)）

> **为什么索引的查询速度接近 O(1) ?**
>
> B+ Tree 的高度很小（即使数据量很大 几百万,可能高度就3~4）, 所以查找的实际时间几乎是个很小的常数, 注意  B+ Tree 和 二叉搜索树不是一个东西, 后面会详细讨论这部分

#### 2.2.3. 举例
假设 `orders.user_id` 列上有索引：
1. 从 `users` 表取第一行：`id = 1, name = Alice`
2. 用 `id = 1` 在 `orders` 表的 `user_id` 索引中查找，找到两行：
   - `user_id = 1, amount = 100`
   - `user_id = 1, amount = 150`
3. 移动到 `users` 表的第二行：`id = 2, name = Bob`
4. 用 `id = 2` 在索引中查找，找到一行：
   - `user_id = 2, amount = 200`
5. 继续，直到处理完所有行

> 就像是 for 循环:
>
> ```python
> # 模拟索引：把 orders 按 user_id 分组（类似哈希索引）
> order_index = {}
> for order in orders:
>     uid = order["user_id"]
>     if uid not in order_index:
>         order_index[uid] = []
>     order_index[uid].append(order)
> 
> # 模拟 JOIN 查询：users 是驱动表
> for user in users:
>     uid = user["id"]
>     # 利用“索引”直接查找匹配的订单
>     if uid in order_index:
>         for order in order_index[uid]:
>             print(f"{user['name']} bought {order['item']}")
> ```

#### 2.2.4. 特点
- 当有良好索引支持时最快，因为索引让查找变得高效
- **如果 `orders.user_id` 上没有索引，MySQL 不会选择这种方式**, 可能会选择其他连接方式
  - 哈希连接（Hash Join）：构建哈希表来加速匹配，适合大表无索引的场景
  - 块嵌套循环连接（Block Nested-Loop Join, BNLJ）：扫描两表，分块处理以减少 I/O
  - 简单嵌套循环连接（Simple Nested-Loop Join, SNLJ）：最慢，通常不会选


### 2.3 哈希连接（Hash Join）

#### 2.3.1. 基本思想
哈希连接使用**哈希表**来加速连接过程，特别适合**大表且没有合适索引**的情况

#### 2.3.2. 工作原理
1. MySQL 选择一个表（通常较小的表）作为**构建表**，比如 `users`
2. 为 `users` 表的连接列 `id` 创建一个哈希表：
   - 键是 `id`，值是对应的行
3. 对另一个表（**探针表**，比如 `orders`）的每一行，计算 `user_id` 的哈希值，在哈希表中查找匹配的行

#### 2.3.3. 举例
假设 `orders.user_id` 没有索引：
1. **构建阶段**：
   - 从 `users` 表创建哈希表：
     - `1 -> {id = 1, name = Alice}`
     - `2 -> {id = 2, name = Bob}`
     - `3 -> {id = 3, name = Charlie}`
2. **探针阶段**：
   - 取 `orders` 第一行：`user_id = 1, amount = 100`，哈希表中找到 `name = Alice`
   - 取 `orders` 第二行：`user_id = 2, amount = 200`，哈希表中找到 `name = Bob`
   - 取 `orders` 第三行：`user_id = 1, amount = 150`，哈希表中找到 `name = Alice`

#### 2.3.4. 特点
- **优点**：对于大表且无适合索引时最佳选择，哈希表查找速度是 O(1)
- **缺点**：需要内存存储哈希表，如果表太大可能内存不足

### 2.4. 其他连接方式

#### 2.4.1. 块嵌套循环连接（Block Nested-Loop Join, BNLJ）
- **基本思想**：这是嵌套循环的优化版，一次读取多行（一个块）来减少 I/O
- **特点**：是简单嵌套循环连接的改进版本，但通常不如哈希连接或索引嵌套循环连接快
- **举例**：MySQL 从 `users` 读取一组行（比如 2 行），然后扫描 `orders` 找匹配，效率比逐行扫描高

> BNLJ的基本思想是将外表（Outer Table）的数据分块读取到内存中，然后对每个块内的元组与内表（Inner Table）的所有元组进行比较，从而减少对内表的重复扫描
>
> 比如每次 从 users 表中 拿出 多行数据 而不是 1个, 每次分别把多行数据跟内表进行比较,  虽然 比较次数没变, 但内表加载次数变少了, 减少了 磁盘 IO, 因为内表只需要为每个外表块加载一次，而不是为每行外表记录加载一次, 所以更高效一些

#### 2.4.2. 简单嵌套循环连接（Simple Nested-Loop Join, SNLJ）
- 基本思想：最原始的方式，对 `users` 的每一行，扫描 `orders` 的所有行
- 特点：最慢，时间复杂度 **O(N * M)**，通常被优化为其他形式
- 举例：对 `users` 的 `id = 1`，扫描 `orders` 所有行找 `user_id = 1`，重复此过程，效率极低

### 2.5. MySQL 如何选择连接方式？

MySQL 的查询优化器会根据以下因素选择：
- **索引情况**：有索引时优先用索引嵌套循环连接。
- **表大小**：大表无索引时可能用哈希连接。
- **内存和 I/O**：内存不足时可能用块嵌套循环连接。

## 3. MySQL 中, 索引的查找速度是否“接近 O(1)”

### 3.1. 最常见的索引：B+ Tree 索引

- MySQL InnoDB 引擎默认的索引类型是 B+ Tree
- B+ Tree 是一种自平衡树结构, 它的查找时间复杂度是 **O(log n)**, 其中 n 是数据的条数
- 为什么是 `O(log n)`？因为 B-Tree 的查找过程依赖于树的高度，而树的高度通常是 `O(log n)`
  - 即使存储数百万条记录，B+ Tree 的高度也不会超过几层
  - 每次查找只需要沿着树的高度走几步，所以实际耗时非常短
- **为什么常说“接近 O(1)”？**
  - 在实际应用中, 由于 B+ Tree 的高度很小（即使数据量很大），查找的实际时间几乎是个很小的常数
  - 因此，虽然理论上是 O(log n)，但表现上“感觉”像是接近 O(1)

> 在理想情况下（即完全平衡的二叉搜索树）一棵满二叉树的节点总数是：
>
> $$
> n = 2^0 + 2^1 + 2^2 + \cdots + 2^h = \sum_{i=0}^{h} 2^i
> $$
>
> 这是一个等比数列，求和公式为：
>
> $$
> n = 2^{h+1} - 1
> $$
>
> 两边取对数，解出高度 `h`：
>
> $$
> n + 1 = 2^{h+1}
> $$
>
> $$
> \log_2(n + 1) = h + 1
> $$
>
> $$
> h = \log_2(n + 1) - 1
> $$
>
> 因此，在最理想的情况下，树的高度近似为：
>
> $$
> h \approx \log_2 n
> $$
>
> 这说明，在平衡的二叉搜索树中，查找、插入、删除等操作的时间复杂度为：
>
> $$
> O(\log n)
> $$

### 3.2. **哈希索引：真正的 O(1)**

- MySQL 也支持 哈希索引，它的查找时间复杂度在理想情况下是 O(1)
- 但是，哈希索引的使用场景非常有限
  - 它主要用于 **MEMORY 存储引擎**, 而 InnoDB 默认不支持哈希索引（除非通过特殊配置）
  - 哈希索引不支持范围查询（比如 >、<），所以适用性不如 B+ Tree
- 因此，在大多数情况下，说“有索引”时，指的并不是哈希索引，而是 B+ Tree 索引
