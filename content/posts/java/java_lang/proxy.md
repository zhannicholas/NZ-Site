---
date: "2020-12-13T18:25:38+08:00"
title: "Java 代理"
authors: ["zhannicholas"]
categories:
  - Java
tags:
  - Java
draft: fasle
toc: true
---

[Wikipedia](https://en.wikipedia.org/wiki/Proxy_pattern#Java) 中是这样描述 `Proxy` 的：
> A proxy, in its most general form, is a class functioning as an interface to something else. The proxy could interface to anything: a network connection, a large object in memory, a file, or some other resource that is expensive or impossible to duplicate. In short, a proxy is a wrapper or agent object that is being called by the client to access the real serving object behind the scenes. Use of the proxy can simply be forwarding to the real object, or can provide additional logic. In the proxy, extra functionality can be provided, for example caching when operations on the real object are resource intensive, or checking preconditions before operations on the real object are invoked. For the client, usage of a proxy object is similar to using the real object, because both implement the same interface.

## 代理模式

[设计模式读书笔记之代理模式](../../../../reading_notes/设计模式的艺术/设计模式的艺术读书笔记之十三代理模式/)

在经典的设计模式种，对于每一个 `RealSubject` 类，都需要创建一个 `Proxy` 代理类，当 `RealSubject` 这种需要被代理的类变得很多时,就需要定义大量的 `Proxy` 类，局面很容易变得不可控。而 JDK 动态代理可以有效地解决这个问题。

## JDK 动态代理

**`java.lang.reflect.Proxy`** 提供了在程序运行期间 **动态** 创建接口的实现类(即代理类 `proxy class` )的方法，因为代理类是在程序运行过程中动态创建的，所以又被称为动态代理类(`dynamic proxy class`)，被实现的接口被称为代理接口(`proxy interface`)，代理类的实例被称为代理实例(`proxy instance`)。

### **`InvocationHandler`** 接口
每个代理实例都有一个相关联的 `invocation handler` 对象，它实现了 **`InvocationHandler`** 接口。**`InvocationHandler`** 接口的定义如下：
```Java
public interface InvocationHandler {
    public Object invoke(Object proxy, Method method, Object[] args)
        throws Throwable;
}
```
代理实例上的方法调用会被转移到对应 `invocation handler` 的 `invoke()` 方法上。
由于一个接口可能声明了多个方法，所以需要 `method` 参数给出将要在 `proxy` 上调用的方法，传递的参数列表为 `args`。

### 创建代理

**`Proxy`** 类的静态方法 `newProxyInstance(ClassLoader loader, Class<?>[] interfaces, InvocationHandler h)` 可以被用来来创建一个代理实例。在使用时，我们需要提供加载代理类的 **`ClassLoader`**、代理类实现的所有接口组成的数组和一个`invocation handler`。

下面是一个例子：
```Java
// 接口
public interface Subject {
    Object execute();
}

// 接口实现类
public class RealSubject implements Subject {
    @Override
    public Object execute() {
        System.out.println("Real subject is executing.");
        return null;
    }
}

public class SubjectProxy implements InvocationHandler {
    private final Subject target;

    public SubjectProxy(Subject target) {this.target = target;}

    @Override
    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        // 执行业务逻辑之前的预处理逻辑……
        // preprocess();
        Object result = method.invoke(target, args);
        // 执行业务逻辑之后的后置处理逻辑……
        // postprocess();
        return result;
    }
}

// 测试程序
public class SubjectProxyTest {
    public static void main(String[] args) {
        Subject subject = (Subject) Proxy.newProxyInstance(
                SubjectProxy.class.getClassLoader(),
                new Class[]{Subject.class},
                new SubjectProxy(new RealSubject()));
        subject.execute();
    }
}
```
程序的运行结果为：
```txt
Real subject is executing.
```

### JDK 动态代理的局限性
被代理的类至少需要实现一个接口，若被代理的类没有实现任何接口，[cglib](https://github.com/cglib/cglib)是一个不错的选择。

## cglib
JDK的动态代理基于 **反射** 机制，生成一个 **实现** 代理接口的代理类，然后重写接口，实现方法增强，只能代理实现了接口的类。因为是基于反射，动态代理在生成类的时候非常快，但后续操作会很慢。

cglib采用了 **字节码** 技术，通过 **继承** 目标类（生成子类）并重写父类的方法来达到增强的目的。cglib 可以在重写的方法中进行拦截，实现代理对象的相关功能。由于这种代理方式是基于继承的，所以 cglib 不能代理被 `final` 修饰的类。因为是基于字节码技术，cglib在生成类的时候很慢，但后续操作很快。

### 简单示例
```Java
public class Person {
    public String hello(String name) {
        System.out.println("Hello, " + name);
        return "Hello, " + name;
    }
}

public class PersonProxyTest {
    public static void main(String[] args) {
        Enhancer enhancer = new Enhancer();
        enhancer.setSuperclass(Person.class);
        enhancer.setCallback(new MethodInterceptor() {
            @Override
            public Object intercept(Object obj, Method method, Object[] args, MethodProxy proxy) throws Throwable {
                System.out.println("cglib methodintercept start...");
                Object result = proxy.invokeSuper(obj, args);
                System.out.println("cglib methodintercept end...");
                return result;
            }
        });
        Person personProxy = (Person) enhancer.create();
        personProxy.hello("Nicholas");
    }
}
```
运行这段代码，可以得到以下结果：
```txt
cglib method intercept start...
Hello, Nicholas
cglib method intercept end...
```
这段代码里面用到了 **`Enhancer`** 类和 **`MethodInterceptor`** 接口。这两者的作用和JDK动态代理里面的 **`Proxy`** 和 **`InvocationHander`** 有些类似。`setSuperClass(Class superclass)` 告诉 **`Enhancer`** 去生成一个 `superclass` 的子类，而 `setCallback(Callback callback)` 告诉 **`Enhancer`** 该使用哪个 `callback` 来处理被代理类上的方法调用。**`MethodIntercepter`** 实现了 **`Callback`** 接口，允许我们对拦截的方法进行完全控制。

## 参考资料
1. [Proxy pattern](https://en.wikipedia.org/wiki/Proxy_pattern).
2. [Dynamic Proxy Classes](https://docs.oracle.com/javase/8/docs/technotes/guides/reflection/proxy.html).
3. [cglib: The missing manual](http://mydailyjava.blogspot.com/2013/11/cglib-missing-manual.html).