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

在经典的设计模式种，对于每一个 `RealSubject` 类，都需要创建一个 `Proxy` 代理类，当 `RealSubject` 这种需要被代理的类变得很多时，就需要定义大量的 `Proxy` 类，局面很容易一发不可收拾。JDK 动态代理可以有效地解决代理类数量过多这个问题。

## JDK 动态代理

`java.lang.reflect.Proxy` 提供了在程序运行期间 **动态** 创建接口实现类（即代理类）的方法，因为代理类是在程序运行过程中动态创建的，所以又被称为动态代理类（dynamic proxy class），被实现的接口被称为代理接口（proxy interface），代理类的实例被称为代理实例（proxy instance）。

### `InvocationHandler` 接口

每个代理实例都有一个相关联的实现了 `InvocationHandler` 接口的对象。`InvocationHandler` 接口的定义如下：
```Java
public interface InvocationHandler {
    public Object invoke(Object proxy, Method method, Object[] args)
        throws Throwable;
}
```
代理实例上的任何方法调用会被分派到到对应 `InvocationHandler` 的 `invoke()` 方法上。`invoke()` 方法有三个参数：
* `proxy`：代理实例
* `method`：将要在 `proxy` 上调用的方法所对应的 `Method` 对象
* `args`：传递给 `method` 的参数列表。若 `method` 没有参数，则应传递 `null`。
### 创建代理

`Proxy` 类的静态方法 `newProxyInstance(ClassLoader loader, Class<?>[] interfaces, InvocationHandler h)` 就是用来创建代理实例的。它有三个参数：

* `loader`：类加载器，用于加载代理类
* `interfaces`：一个数组，包含代理类实现的所有接口
* `h`：与代理类相关联的 `InvocationHandler`

我们可以通过下面的例子进一步理解。

先定义一个接口：
```Java
// 接口
public interface Subject {
    Object execute();
}
```

创建一个接口实现类：
```Java
public class RealSubject implements Subject {
    @Override
    public Object execute() {
        System.out.println("Real subject is executing.");
        return null;
    }
}
```

创建代理类：
```Java
public class SubjectProxy implements InvocationHandler {
    private final Subject target;

    public SubjectProxy(Subject target) {this.target = target;}

    @Override
    public Object invoke(Object proxy, Method method, Object[] args) throws Throwable {
        Object result = method.invoke(target, args);
        return result;
    }
}
```

创建一个代理实例，然后调用代理实例的方法简单测试一下：
```Java
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

可以发现，虽然我们创建的是 `Subject` 对象，但实际被调用的方法却是 `RealSubject` 的方法。

### 再深入一点

有没有什么办法可以看到程序运行时动态生成的代理类呢？答案是肯定的，我们可以在运行测试程序的时候加一个参数 `-Djdk.proxy.ProxyGenerator.saveGeneratedFiles=true`，将生成的代理类保存到当前的工作目录。在 JDK9 之前，这个参数是 `-Dsun.misc.ProxyGenerator.saveGeneratedFiles=true`。在笔者的电脑上，生成的代理类是 `com.sun.proxy.$Proxy0`，反编译得到的类是这样的：
```Java
//
// Source code recreated from a .class file by IntelliJ IDEA
// (powered by FernFlower decompiler)
//

package com.sun.proxy;

import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import java.lang.reflect.UndeclaredThrowableException;
import ml.zhannicholas.reflection.dynamicproxy.Subject;

public final class $Proxy0 extends Proxy implements Subject {
    private static Method m1;
    private static Method m2;
    private static Method m3;
    private static Method m0;

    public $Proxy0(InvocationHandler var1) throws  {
        super(var1);
    }

    public final boolean equals(Object var1) throws  {
        try {
            return (Boolean)super.h.invoke(this, m1, new Object[]{var1});
        } catch (RuntimeException | Error var3) {
            throw var3;
        } catch (Throwable var4) {
            throw new UndeclaredThrowableException(var4);
        }
    }

    public final String toString() throws  {
        try {
            return (String)super.h.invoke(this, m2, (Object[])null);
        } catch (RuntimeException | Error var2) {
            throw var2;
        } catch (Throwable var3) {
            throw new UndeclaredThrowableException(var3);
        }
    }

    public final Object execute() throws  {
        try {
            return (Object)super.h.invoke(this, m3, (Object[])null);
        } catch (RuntimeException | Error var2) {
            throw var2;
        } catch (Throwable var3) {
            throw new UndeclaredThrowableException(var3);
        }
    }

    public final int hashCode() throws  {
        try {
            return (Integer)super.h.invoke(this, m0, (Object[])null);
        } catch (RuntimeException | Error var2) {
            throw var2;
        } catch (Throwable var3) {
            throw new UndeclaredThrowableException(var3);
        }
    }

    static {
        try {
            m1 = Class.forName("java.lang.Object").getMethod("equals", Class.forName("java.lang.Object"));
            m2 = Class.forName("java.lang.Object").getMethod("toString");
            m3 = Class.forName("ml.zhannicholas.reflection.dynamicproxy.Subject").getMethod("execute");
            m0 = Class.forName("java.lang.Object").getMethod("hashCode");
        } catch (NoSuchMethodException var2) {
            throw new NoSuchMethodError(var2.getMessage());
        } catch (ClassNotFoundException var3) {
            throw new NoClassDefFoundError(var3.getMessage());
        }
    }
}
```
可以发现，代理类 `$Proxy0` 不仅实现了 `Subject` 接口，还继承自 `Proxy` 类。由于 Java 不支持多继承，所以只能通过接口来实现多态。这也是 JDK 动态代理的不足，即要求被代理的类至少需要实现一个接口。若被代理的类没有实现任何接口，[cglib](https://github.com/cglib/cglib)是一个不错的选择。

## cglib

JDK的动态代理基于 **反射** 机制，生成一个 **实现** 代理接口的代理类，然后重写接口，实现方法增强，只能代理实现了接口的类。因为是基于反射，动态代理在生成类的时候非常快，但后续操作会很慢。

cglib采用了 **字节码** 技术，通过 **继承** 目标类（生成子类）并重写父类的方法来达到增强的目的。cglib 可以在重写的方法中进行拦截，实现代理对象的相关功能。由于这种代理方式是基于继承的，所以 cglib 不能代理被 `final` 修饰的类。因为是基于字节码技术，cglib在生成类的时候很慢，但后续操作很快。

### 简单示例

先定义一个原始类：
```Java
public class Person {
    public String hello(String name) {
        System.out.println("Hello, " + name);
        return "Hello, " + name;
    }
}
```

然后使用 cglib 进行代理：
```Java
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
这段代码里面用到了 `Enhancer` 类和 `MethodInterceptor` 接口。这两者的作用和JDK动态代理里面的 `Proxy` 和 `InvocationHander` 有些类似。`setSuperClass(Class superclass)` 告诉 `Enhancer` 去生成一个 `superclass` 的子类，而 `setCallback(Callback callback)` 告诉 `Enhancer` 该使用哪个 `callback` 来处理被代理类上的方法调用。`MethodIntercepter` 实现了 `Callback` 接口，允许我们对拦截的方法进行完全控制。

## 参考资料

1. [Proxy pattern](https://en.wikipedia.org/wiki/Proxy_pattern).
2. [Dynamic Proxy Classes](https://docs.oracle.com/javase/8/docs/technotes/guides/reflection/proxy.html).
3. [cglib: The missing manual](http://mydailyjava.blogspot.com/2013/11/cglib-missing-manual.html).