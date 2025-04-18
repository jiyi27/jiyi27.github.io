---
title: 优先队列 vs Redis Sorted Sets
date: 2025-03-20 18:08:52
categories:
 - 面试
tags:
 - 面试
 - 算法面试
---

## 1. Priority Queues

堆分为最大最小堆, 插入和删除复杂度都是 `O(log n)`, 通常通过数组实现, 平时的用法比如 heap sort, priority queues, 今天我们说的优先队列就是最小堆实现的, 一般优先队列就像`array`, `list`, `hashmap` 每个语言内都内置了, 平时用于开发系统级别, 比较 low-level 的系统会用到, 而 redis sorted sets 一般都是用在后端开发业务逻辑中, 而且本质上, 它也是优先队列, 这里对比一下, 毕竟都是和排序有关系

### 2.1. 默认排序规则（自然顺序）

默认情况下，PriorityQueue 是一个**最小堆**，即：

- 自然顺序要求元素实现 `Comparable` 接口，并在其 `compareTo` 方法中定义比较逻辑
- 队列的队首（`peek/poll` 获取的元素）始终是最小的元素（根据 `compareTo` 的结果）
- 例如，对于整数，PriorityQueue 会将最小的整数放在队首；对于字符串，会按字典序（ lexicographical order）排序

```java
import java.util.PriorityQueue;

public class Main {
    public static void main(String[] args) {
        PriorityQueue<Integer> pq = new PriorityQueue<>();
        pq.offer(5);
        pq.offer(2);
        pq.offer(8);
        System.out.println(pq.poll()); // 输出: 2（最小值）
        System.out.println(pq.poll()); // 输出: 5
        System.out.println(pq.poll()); // 输出: 8
    }
}
```

- 这里，`Integer` 实现了 `Comparable`，`compareTo` 按数值大小比较，因此 `PriorityQueue` 按升序排列，队首是最小值

### 2.2. 自定义排序规则（使用 Comparator）

- 你可以通过在构造 `PriorityQueue` 时传入一个 `Comparator` 对象来自定义排序规则

- `Comparator` 的 compare 方法定义了元素的优先级顺序
- 如果提供了 `Comparator`，`PriorityQueue` 会根据它来决定元素的顺序，**而不是依赖 `Comparable`**
- 仍然默认是最小堆，队首是根据 `Comparator` 定义的“最小”元素

```java
import java.util.PriorityQueue;
import java.util.Comparator;

public class Main {
    public static void main(String[] args) {
        // 自定义 Comparator，按降序排序（大的值优先）
        PriorityQueue<Integer> pq = new PriorityQueue<>(Comparator.reverseOrder());
        pq.offer(5);
        pq.offer(2);
        pq.offer(8);
        System.out.println(pq.poll()); // 输出: 8（最大值）
        System.out.println(pq.poll()); // 输出: 5
        System.out.println(pq.poll()); // 输出: 2
    }
}
```

### 2.3. 排队服务 任务调度系统

- 用户上传视频后，系统会排队转码（比如压缩、加字幕等）
- 有的用户是普通用户，优先级低
- 有的用户是 VIP，优先级高

建一个「优先队列」来排这些转码任务：

```java
import java.util.PriorityQueue;

// 转码任务类
class TranscodeTask implements Comparable<TranscodeTask> {
    private String videoId;
    private int priority; // 优先级：数字越小优先级越高
    private boolean isVip;
    
    public TranscodeTask(String videoId, boolean isVip) {
        this.videoId = videoId;
        this.isVip = isVip;
        // VIP用户优先级为1，普通用户优先级为2
        this.priority = isVip ? 1 : 2;
    }
    
    // 实现Comparable接口，用于优先队列排序
    @Override
    public int compareTo(TranscodeTask other) {
        // 按优先级排序，数字小的在前
        return Integer.compare(this.priority, other.priority);
    }
    
    @Override
    public String toString() {
        return "视频: " + videoId + " [" + (isVip ? "VIP用户" : "普通用户") + 
               ", 优先级: " + priority + "]";
    }
}

// 视频转码服务
class TranscodingService {
    private PriorityQueue<TranscodeTask> queue;
    private int maxConcurrentTasks;
    
    public TranscodingService(int maxConcurrentTasks) {
        this.queue = new PriorityQueue<>();
        this.maxConcurrentTasks = maxConcurrentTasks;
    }
    
    // 添加任务到队列
    public void addTask(String videoId, boolean isVip) {
        TranscodeTask task = new TranscodeTask(videoId, isVip);
        queue.offer(task); // 添加到优先队列
        System.out.println("任务已添加: " + task);
    }
    
    // 处理队列中的任务
    public void processTasks() {
        System.out.println("\n开始处理队列中的任务，最多同时处理" + maxConcurrentTasks + "个任务");
        
        // 模拟处理maxConcurrentTasks个任务
        for (int i = 0; i < maxConcurrentTasks && !queue.isEmpty(); i++) {
            TranscodeTask task = queue.poll(); // 取出优先级最高的任务
            System.out.println("正在处理: " + task);
        }
        
        System.out.println("队列中剩余任务数: " + queue.size());
    }
}

// 测试优先队列
public class VideoTranscodingDemo {
    public static void main(String[] args) {
        TranscodingService service = new TranscodingService(2); // 最多同时处理2个任务
        
        // 添加任务，普通用户和VIP用户混合
        service.addTask("video1", false); // 普通用户
        service.addTask("video2", true);  // VIP用户
        service.addTask("video3", false); // 普通用户
        service.addTask("video4", true);  // VIP用户
        service.addTask("video5", false); // 普通用户
        
        // 处理任务
        service.processTasks();
        
        // 再次处理剩余任务
        service.processTasks();
    }
}
```

## 2. Redis Sorted Set

A **Redis Sorted Set** is a data type where each element is associated with a score, and elements are automatically sorted by that score. It behaves *like* a priority queue — but it’s **persistent, distributed**, and accessible over the network.

### 2.1. Redis Sorted Set 的特点

1. 每个元素都有一个关联的分数，用于排序
2. 元素按分数从小到大排序（可以使用 ZREVRANGE 等命令反向获取）
3. 相同分数的元素按字典序排序
4. 支持范围查询、**取 top-N 等操作**
5. 元素不可重复，但分数可以重复

## 3. 二者对比

### 3.1. 实现原理

| 特性                  | Redis Sorted Set         | 优先队列                              |
| --------------------- | ------------------------ | ------------------------------------- |
| **数据结构**          | 基于跳表实现             | 通常基于二叉堆、斐波那契堆等实现      |
| **元素唯一性**        | 元素必须唯一             | 允许重复元素                          |
| **排序依据**          | 按分数(score)排序        | 按优先级排序                          |
| **访问方式**          | 可随机访问任意范围的元素 | 通常只能访问队头元素(最高/最低优先级) |
| **操作复杂度**        | 大多数操作 O(log(N))     | 插入/删除通常为 O(log(N))             |
| **分布式支持**        | 原生支持分布式环境       | 通常为单机内存数据结构                |
| **持久化**            | 支持                     | 通常不支持                            |
| **内存占用**          | 相对较高                 | 相对较低                              |
| **同分数/优先级处理** | 同分数按字典序排序       | 实现决定(通常不保证顺序)              |
| **范围查询**          | 支持高效的范围查询       | 通常不支持                            |

### 3.2. 使用场景

| 场景             | Redis Sorted Set                                             | 优先队列                                                     |
| ---------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| **排行榜系统**   | ✅ 适合：<br>- 范围查询支持获取前N名<br>- 分数更新自动重排序<br>- 持久化保证数据不丢失 | ❌ 不适合：<br>- 无法高效获取范围数据<br>- 通常无持久化能力   |
| **任务调度**     | ✅ 适合：<br>- 分布式环境下多服务共享队列<br>- score可用时间戳表示执行时间<br>- 支持任务更新和取消 | ✅ 适合：<br>- 单机环境下内存效率高<br>- 操作延迟低<br>- 适合实时系统 |
| **延迟队列**     | ✅ 非常适合：<br>- score设为执行时间<br>- ZRANGEBYSCORE可查询该执行的任务<br>- 分布式环境可靠 | ⚠️ 有限支持：<br>- 需要额外的定时器机制<br>- 分布式环境需要额外协调 |
| **社交网络关系** | ✅ 适合：<br>- 可存储用户关系并按亲密度排序<br>- 支持查询Top N好友<br>- 支持范围查询 | ❌ 不适合：<br>- 无法进行复杂的关系查询                       |
| **实时分析系统** | ✅ 适合：<br>- 可用于时间序列数据存储<br>- 支持时间范围查询<br>- 分布式环境下的数据共享 | ⚠️ 部分适合：<br>- 处理速度快但功能有限<br>- 不支持复杂查询   |
| **图算法**       | ❌ 不适合：<br>- 网络延迟影响性能<br>- API不适合图算法需求    | ✅ 非常适合：<br>- Dijkstra等算法的核心组件<br>- 快速获取最小/最大元素 |
| **地理位置应用** | ✅ 适合：<br>- 结合GEO命令可存储位置并按距离排序<br>- 支持范围查询附近的POI | ❌ 不适合：<br>- 无地理位置特性支持                           |
| **限流系统**     | ✅ 适合：<br>- score设为时间戳<br>- ZREMRANGEBYSCORE删除过期令牌<br>- 原子操作保证一致性 | ⚠️ 有限支持：<br>- 需要额外逻辑处理过期                       |
| **大数据处理**   | ✅ 支持：<br>- 可处理大量数据(内存限制)<br>- 支持集群扩展     | ⚠️ 受限：<br>- 受单机内存限制<br>- 扩展性差                   |
| **分布式应用**   | ✅ 原生支持：<br>- 多客户端可并发访问<br>- 支持主从复制和集群 | ❌ 需要额外实现：<br>- 需要自行处理分布式一致性<br>- 需要额外的服务协调 |

