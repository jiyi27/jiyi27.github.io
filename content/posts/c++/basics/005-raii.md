---
title: C++ RAII (Resource Acquisition Is Initialization)
date: 2023-05-16 20:32:04
categories:
 - c++
 - basics
tags:
 - c++
---

RAII (Resource Acquisition Is Initialization) is a programming technique whereby resource use is tied to the lifetime of objects with automatic duration (e.g. non-dynamically allocated objects). **In C++, RAII is implemented via classes with constructors and destructors.** A resource (such as memory, a file or database handle, etc…) is typically acquired in the object’s constructor (though it can be acquired after the object is created if that makes sense). That resource can then be used while the object is alive. The resource is released in the destructor, when the object is destroyed. The primary advantage of RAII is that it helps prevent resource leaks (e.g. memory not being deallocated) as all resource-holding objects are cleaned up automatically.

```c++
class IntArray {
private:
	int* m_array{};
	int m_length{};

public:
	IntArray(int length) {
		assert(length > 0);

		m_array = new int[static_cast<std::size_t>(length)]{};
		m_length = length;
	}

	~IntArray() {
		// Dynamically delete the array we allocated earlier
		delete[] m_array;
	}
  ...
};
```

The `IntArray` class above is an example of a class that implements RAII -- allocation in the constructor, deallocation in the destructor. `std::string` and `std::vector` are examples of classes in the standard library that follow RAII -- **dynamic memory is acquired on initialization, and cleaned up automatically on destruction**.

References:

- [13.8 — Overlapping and delegating constructors – Learn C++](https://www.learncpp.com/cpp-tutorial/overlapping-and-delegating-constructors/)

- [13.9 — Destructors – Learn C++](https://www.learncpp.com/cpp-tutorial/destructors/)