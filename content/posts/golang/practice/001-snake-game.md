---
title: 用Go实现一个简单的贪吃蛇
date: 2023-05-20 19:59:09
categories:
 - golang
 - practice
tags:
 - golang
 - game
---

**地图**

地图就是个二维数组`board`, 在Go里面叫Slice of slices, 该地图(二维数组)存储bool类型, 定义如下和结构如下:

```go
// height = 4, width = 3
func main() {
  // Definition
	board := make([][]bool, height)
	for i := range board {
		board[i] = make([]bool, width)
	}
  // Test
	board[2][1] = true
	for y := range board{
		for _, v := range board[y] {
			fmt.Printf("%v ", v)
		}
		println()
	}
}

false false false 
false false false 
false true false 
false false false 
```

----

**打印蛇🐍身体**

蛇的身体由多个节点组成, 节点是个struct类型, 如下:

```go
type node struct {
	x int
	y int
}
```

把地图设计成存储布尔类型的数组的目的就是方便打印蛇的身体, 也是实现的关键, 即每次循环`board`(代表地图的二维数组), 遇到false就打印空白, 遇到true就打印一个黑色方块▪️代表蛇的身体:

```go
func draw() {
	fmt.Print("\033[H\033[2J")
	// original: 'for y, _ := range board { ... }'
	for y := range board {
		for i, v := range board[y] {
			if !v && (food.x != i || food.y != y) {
				fmt.Print("□ ")
			} else if !v && food.x == i && food.y == y {
				fmt.Print("★ ")
			} else {
				fmt.Print("■ ")
			}
		}
		fmt.Println()
	}
}
```

这样我们只需要写个函数根据蛇的身体(多个节点)来修改(更新)`board`里面每个元素的值, 然后再写个函数(也就是上面的`draw()`)根据`board`来画地图就好了, 注意画地图的时候也画了蛇的身体:

```go
func update() {
  // 这里访问二维数组的时候第一个是高度, 第二个是宽度
  // 即board[0][2]代表第1个数组的第3个元素, 所以我们写成 board[v.y][v.x] = true
  // 而不是board[v.x][v.y] = true
	for _, v := range snake{
		board[v.y][v.x] = true
	}
	// draw map and snake and food
	draw()
}
```

---

**让蛇动起来**

让蛇动起来的方法有多种, 在这里比如每次reset地图`board`的数据为false, 然后再根据蛇的身体`snake`更新`board`, 但这样效率稍低, 因为每次我们都需要遍历board去reset, 仔细想一下蛇每次移动, 其实就是最前面的头往前移动一格, 尾巴往前移动一格, 中间的身体**看着**是不变的, 所以我们在实现的时候也是有三步:

- 1 根据当前方向`direction`修改`snake`第一个元素的坐标, 实现蛇头前进一格

```go
  // change the head position
	switch direction {
	case right:
		snake[0].x++
	case left:
		snake[0].x--
	case up:
		snake[0].y--
	case down:
		snake[0].y++
	}
```

- 2 遍历`snake`, 使第`i`个元素的坐标等于第`i-1`个元素的坐标(`i>=1`),中间的身体看着是不动的, 其实每个节点都前进了

```go
length := len(snake)
// "move" all node of snake except the head
if length > 1 {
	// make the value of each (i)th element equal to the (i-1)th value
	for i := len(snake) - 1; i >= 1; i-- {
		snake[i] = snake[i-1]
	}
}
```

- 3 设置位置在蛇的最后一个节点即尾巴`(snake[len - 1].x, snake[len - 1].y)`的`board`元素为false, 因为在第2步尾巴已经变成倒数第二个元素的坐标了, 所以我们要把旧的尾巴坐标位置设置为false

即这样只遍历了`snake`(一维数组)来实现更新地图.

----

**总结**

这次的小应用, 熟悉了slice的用法, 也熟悉了很多语法比如`:=`和`var`, 尤其是遍历slice以及loop的写法, 比如无限循环可写成:

```go
for {
  ...
}
```

其次是导入第三方模块, 如这里读取键盘我们使用的是第三方库, 安装方法很简单, 即在项目根目录执行:

```shell
$ go get github.com/eiannone/keyboard
```

源码: https://gist.github.com/shwezhu/3def0433eb5656deebf07dc32e6eecc1
