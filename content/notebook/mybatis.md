---
date: "2021-03-22T23:58:56+08:00"
title: "Mybatis"
authors: ["zhannicholas"]
categories:
  - Notebook
tags:
  - MyBatis
draft: false
toc: true
---

之所以放在 Notebook 中，是因为本文的绝大部分内容来自某网课，做笔记备忘，便于以后碰到相关问题更快地定位和排查问题。

## MyBatis 三层架构

MyBatis 的整体架构分为三层，分别是：**基础支撑层**、**逻辑处理层** 和 **接口层**。

![](/images/notebook/MyBatis/MyBatis三层架构图.png)

### 基础支撑层

基础支撑层为整个 MyBatis 框架提供最基础的功能，分为九个基础模块，每个模块都具有各自不同的能力。

#### 类型转换模块

> 在使用 JDBC 操作数据库时，我们面临着三个不同层次的数据类型差异——数据库自己的数据类型、JDBC 定义的数据类型和 Java 数据类型。JDBC 在中间，作为规范标准，它可以屏蔽底层数据的差异，但 JDBC 类型与 Java 类型并不是一一对应的，所以需要进行适当的类型转换。

[JDBC Spec 4.2](https://download.oracle.com/otn-pub/jcp/jdbc-4_2-mrel2-eval-spec/jdbc4.2-fr-spec.pdf) 中定义了 JDBC 类型到 Java 类型的映射关系、Java 类型到 JDBC 类型的映射关系等等。

![](/images/notebook/MyBatis/MyBatis类型转换模块.png)

类型转换模块实现了 MyBatis 中定义的 JDBC 类型与 Java 类型之间的相互转换：

* 当 MyBatis 在将 SQL 模板与用户传入的参数相绑定（在我们使用 `PreparedStatement` 执行 SQL 之前，需要手动调用 `setInt()`、`setString()` 等方法绑定参数）时，类型转换模块会将 Java 类型数据转换为 JDBC 类型数据。
* 当取得查询结果后，类型转换模块会将 `ResultSet` 中的 JDBC 类型数据转换为 Java 类型数据。

此外，类型转换模块还实现了别名的功能。我们可以在 `mybatis-config.xml` 配置文件中使用 `<typeAlias>` 标签为 Java 类的完整名称定义相应的别名。然后在后续编写 SQL 语句、定义 `<resultMap>` 的时候，就可以直接使用这些别名替代相应的 Java 类名，这样就非常易于代码的编写和维护。`TypeAliasRegistry` 是维护别名配置的核心实现，它提供了别名注册、别名查询等基本功能。

##### TypeHandler

MyBatis 中的类型转换模块包含众多类型转换器，这些类型转换器都有一个父接口——`TypeHandler`。整个转换器的层次结构如下（为了简单，图中省略了不少类型转换器）：

![](/images/notebook/MyBatis/TypeHandler.png)

其中，`BaseTypeHandler` 不仅实现了一些 `TypeHandler` 的公共逻辑，还实现了抽象类 `TypeReference`。

除了这些默认的 `TypeHandler` 之外，我们还可以在 `mybatis-config.xml` 中使用标签配置自定义的 `TypeHandler` 实现，也可以在定义 `Mapper.xml` 的时候指定 `typeHandler` 属性。不管是哪种方式，MyBatis 都会在初始化的过程中，获取所有已知的 `TypeHandler`，创建对应的实例并注册到 `TypeHandlerRegistry` 中，由 `TypeHandlerRegistry` 统一管理所有的 `TypeHandler` 实例。

#### 日志模块

MyBatis 提供的日志模块可以很方便地集成各种第三方 Java 日志框架，比如 Log4j、Log4j2、slf4j、java.util.logging 等。由于这些日志框架来源于不同的开源组织，给用户暴露的接口也不尽相同。所以 MyBatis 使用了 **适配器模式**（[设计模式读书笔记之适配器模式](../../reading_notes/设计模式的艺术/设计模式的艺术读书笔记之七适配器模式)）对第三方日志框架接口进行了统一。

MyBatis 自己定义了一个 `Log` 接口，然后使用适配器模式针对不同的日志框架进行了适配，将第三方日志框架的日志接口转化为了它自己的 `Log` 接口，这样就成功集成了第三方日志框架的日志打印功能。

`Log` 接口及相关适配器实现均位于 `org.apache.ibatis.logging` 包中。整体结构如下：

![](/images/notebook/MyBatis/Logging.png)

其中，`LoggFactory` 负责创建 `Log` 对象，这个工厂类中有一段静态代码块，会依次加载各个第三方日志框架的适配器。


#### Binding 模块

在使用 MyBatis 时，我们无须编写 `Mapper` 接口的具体实现，Binding 模块会自动生成 `Mapper` 接口的动态代理对象，通过代理对象可以执行关联 `Mapper.xml` 文件（或 `Mapper` 接口中的注解）中的数据库操作。Binding 模块的核心类如下：

![](/images/notebook/MyBatis/binding-module.png)

`MapperRegistry`（在 MyBatis 初始化过程中构造） 主要负责统一维护 `Mapper` 接口以及这些 `Mapper` 对应的代理对象工厂 `MapperProxyFactory`。`MapperProxyFactory` 通过 JDK 动态代理的方式创建 `Mapper` 接口的代理对象 `MapperProxy`，`MapperProxy` 封装核心代理逻辑，将拦截到的目标方法委托给 `MapperMethod` 处理。

##### MapperProxy

`MapperProxy` 是生成 `Mapper` 接口代理对象的关键，它实现了 `InvocationHandler` 接口。`Mapper` 代理对象的执行入口正是 `MapperProxy` 的 `invoke()` 方法。该方法内部会针对所有的非 `Object` 方法调用 `cachedInvoker()` 方法获取对应的 `MapperMethodInvoker` 对象，并调用其 `invoke()` 方法执行代理逻辑以及目标方法。

在 `cachedInvoker()` 方法中，首先会查询 `methodCache` 缓存（类型为 `Map<Method, MapperMethodInvoker>`），如果查询的方法为 `default` 方法，则会根据当前使用的 JDK 版本，获取对应的 `MethodHandle`（相关文档：[MethodHandle](https://docs.oracle.com/javase/8/docs/api/java/lang/invoke/MethodHandle.html)） 并封装成 `DefaultMethodInvoker` 对象写入缓存备用；如果查询的方法是非 `default` 方法，则创建 `PlainMethodInvoker` 对象写入缓存备用。

![](/images/notebook/MyBatis/MapperMethodInvoker.png)

`DefaultMethodInvoker` 与 `PlainMethodInvoker` 的内部实现稍有不同，前者通过 `MethodHandle` 完成调用，而后者通过 `MapperMethod` 完成调用。

##### MapperMethod

`MapperMethod` 记录了 `Mapper` 接口中的对应方法，也是最终执行 SQL 语句的地方（`execute()`方法），`execute()` 方法会根据要执行的 SQL 语句的具体类型执行 `SqlSession` 的相应方法完成数据库操作。

在 `MapperMethod` 中，`command` 字段（`SqlCommand` 类型，它是 `MapperMethod` 的一个内部类）维护了关联 SQL 语句的相关信息。先简单看一下 `SqlCommand` 类：

```java
public static class SqlCommand {
    private final String name;          // 关联 SQL 语句的唯一标识
    private final SqlCommandType type;  // 关联 SQL 语句的操作类型

    // ...
}
```

MyBatis 中的 SQL 语句有五种不同的操作类型：

```java
public enum SqlCommandType {
  UNKNOWN, INSERT, UPDATE, DELETE, SELECT, FLUSH
}
```

`MapperMethod` 中的 `method` 字段（`MethodSignature` 类型）则是维护了 `Mapper` 接口中方法的相关信息。它依赖 `ParamNameResolver` 这个解析方法参数列表的工具类。这里有必要单独说一下这个工具类。

`ParamNameResolver` 中有一个 `name` 字段记录了各个参数参数在参数列表中的位置以及参数名称，其中 key 是参数在参数列表中的位置索引， value 为参数的名称。

```java
  private final SortedMap<Integer, String> names;
```

我们可以通过 `@Param` 注解指定一个参数名称，如果没有指定，则默认使用参数列表中的变量名称作为其名称，这与 `ParamNameResolver` 的 `useActualParamName` 有关，它是一个全局配置。如果将其配置为 `false`，则使用参数的下标索引作为其名称。此外，`names` 集合会跳过类型为 `RowBounds` 和 `ResultHandler` 类型的参数，如果使用下标作为索引作为参数名称的话，这时就会在 `names` 集合中出现 KV 不一致的情况。例如：

```txt
aMethod(@Param("M") int a, @Param("N") int b) -> {{0, "M"}, {1, "N"}}
aMethod(int a, int b) -> {{0, "0"}, {1, "1"}}
aMethod(int a, RowBounds rb, int b) -> {{0, "0"}, {2, "1"}}
```

#### 资源加载模块

资源加载模块主要是对类加载器进行封装，确定类加载器的使用顺序，并提供了加载类文件以及其他资源文件的功能。 

#### 数据源模块

数据源是持久层框架中最核心的组件之一，MyBatis 不仅提供了一套默认的数据源实现，还能够很方便地集成第三方数据源。在 Java 中，数据源这个抽象由 `javax.sql.DataSource` 接口表示，MyBatis 自带的数据源实现就实现了该接口。MyBatis 默认实现了两种类型的数据源——`UnpooledDataSource` 和 `PooledDataSource`。

![](/images/notebook/MyBatis/datasource-implementations.png)

此外，对于这两种不同的数据源实现，MyBatis 还使用工厂方法模式（[设计模式读书笔记之工厂方法模式](../../reading_notes/设计模式的艺术/设计模式的艺术读书笔记之三工厂方法模式)）提供了相应的工厂类：

![](/images/notebook/MyBatis/DataSourceFactory.png)

使用工厂方法模式的好处在于，如果需要扩展新的数据源，只需要添加相应的 `DataSourceFactory` 接口实现类即可。这里的 `DataSource` 即工厂方法模式中的 `Product`。`DataSourceFactory` 定义了两个方法：`setProperties()` 用于配置数据源属性，`getDataSource()` 用于返回数据源对象。从上图可以看出，`PooledDataSourceFactory` 并没有直接实现 `DatasourceFactory` 接口，而是直接继承了 `UnpooledDataSourceFactory` 类。


#### 缓存管理模块

缓存是优化数据库性能的常用手段之一，正确使用缓存可以将一部分数据库请求拦截在缓存层，减少数据库的压力，提升系统性能。

![缓存原理](/images/notebook/MyBatis/cache-model.png)

MyBatis 就提供了许多不同策略的缓存，这些缓存分为两个级别：一级缓存和二级缓存，它们都实现了 `Cache` 接口。

![](/images/notebook/MyBatis/Cache.png)

`Cache` 接口定义了 MyBatis 缓存最基本、最核心的行为，其中的核心方法主要是 `putObject()`、`getObject()` 和 `removeObject()`，分别用来添加、查询和删除缓存数据。MyBatis 在实现缓存模块时采用了装饰器模式（[设计模式读书笔记之装饰器模式](../../reading_notes/设计模式的艺术/设计模式的艺术读书笔记之十装饰模式)），其中 `PerpetualCache` 扮演的正是装饰器模式中的 `ConcretComponent` 的角色，它实现了 `Cache` 接口缓存的基本能力。除 `PerpetualCache` 以外的其它 `Cache` 接口实现都是装饰器，扮演的是装饰器模式中的 `ConcreteDecorator` 的角色，不同装饰器提供了不同的功能扩展。

例如，`BlockingCache` 在原有缓存实现之上添加了阻塞线程的特性，`FifoCache` 添加了先进先出的特性，`LruCache` 添加了最近最少适用的淘汰机制等等。

#### 解析器模块

MyBatis 中需要解析的配置文件分为两部分：一个是 `mybatis-config.xml` 配置文件，另一个是 `Mapper.xml` 配置文件。这两个文件都是由 MyBatis 的解析器模块进行解析的，其中主要是依赖 XPath 实现 XML 配置文件以及各类表达式的高效解析。

#### 事务管理模块

MyBatis 对数据库中的事务进行了一层简单的抽象，提供了简单易用的事务接口和实现。在 MyBatis 中，数据库事务被抽象为 `Transaction` 接口，它定义了提交事务、回滚事务以及获取底层数据库连接的方法。`TransactionFactory` 则是用于创建 `Transaction` 对象的工厂接口。

![](/images/notebook/MyBatis/Transaction.png)

#### 反射工具模块

MyBatis 在 Java 反射的基础上进行了封装，为上层使用方提供了更加灵活、方便的 API 接口。反射工具箱的具体代码位于 `org.apache.ibatis.reflection` 包中。`Reflector` 是整个模块的基础，在使用反射模块操作一个 `Class` 之前，MyBatis 会将 `Class` 封装成一个 `Reflector`，为了提高反射执行的效率，`Reflector` 中缓存了 `Class` 的元数据信息。

`Reflector` 将类的属性与方法等信息记录在自己的核心字段中，它的核心字段如下所示：

![](/images/notebook/MyBatis/Reflector.png)

`Reflector` 的构造函数以 `Class` 为参数，在构造方法内部会解析传入的 `Class` 对象，填充以上字段。

同样，为了提高 `Reflector` 的初始化速度，MyBatis 提供了 `ReflectorFactory` 工厂接口。该接口的默认实现 `DefaultReflectorFactory` 在内存中通过 `ConcurrentHashMap<Class<?>, Reflector>`（即 `reflectorMap`）对 `Reflector` 对象进行了缓存，该接口的核心方法 `findForClass(Class<?> type)` 就会根据传入 `Class` 查找 `reflectorMap` 缓存，若查找成功，则直接返回，否则创建相应的 `Reflector` 对象并放入缓存，以便下次使用。

`ObjectFactory` 是 MyBatis 中的对象反射工厂接口，它提供了两个不同的 `create` 方法，我们可以用它来创建指定类型的对象。`DefaultObjectFactory` 是此接口的默认实现，底层会利用反射根据入参列表选择合适的构造函数实例化对象。我们可以在 `mybatis-config.xml` 中配置自定义的 `ObjectFactory` 接口的扩展实现类，达到自定义功能扩展的目的。

反射模块内还提供了几个用于解析属性的工具类：

* `PropertyTokenizer`：负责解析由 `.` 和 `[]` 构成的表达式，支持对嵌套多层表达式的处理
* `PropertyCopier` 用于属性拷贝
* `PropertyNamer` 可以将方法名转换为属性名，亦能检测一个方法是否为 setter 或  getter 方法

此外，反射模块还有 `MetaClass`，它封装了 Class 的元数据信息，以及 `ObjectWrapper`，它封装了对象的元数据信息。

### 核心处理层

MyBatis 的核心实现，涉及 MyBatis 的初始化以及执行一条 SQL 语句的全流程。

#### 配置解析

MyBatis 中有三处可以添加配置信息的地方：`mybatis-config.xml` 配置文件、`Mapper.xml` 配置文件，以及 `Mapper` 接口中的注解信息。MyBatis 会在初始化的时候加载这些配置信息，并在解析完成之后，将解析得到的配置到对象保存到 `Configuration` 对象中。

配置解析过程中用到了设计模式中的建造者模式（[设计模式读书笔记之建造者模式](../../reading_notes/设计模式的艺术/设计模式的艺术读书笔记之六建造者模式)）。

##### mybatis-config.xml 解析

MyBatis 初始化的第一个步骤就是加载和解析 `mybatis-config.xml` 这个全局配置文件。入口位于 `XMLConfigBuilder` 这个 Builder 对象，它由 `SqlSessionFactoryBuilder.build()` 方法创建。

`XMLConfigBuilder` 会将 `mybatis-config.xml` 解析为对应的 `Configuration` 全局配置对象，然后 `SqlSessionFactoryBuilder` 会根据得到的 `Configuration` 对象创建一个 `DefaultSqlSessionFactory` 供上层使用。

`XMLConfigBuiler` 继承自 `BaseBuilder` 抽象类，该类的继承关系如下：

![](/images/notebook/MyBatis/BaseBuilder.png)

`BaseBuilder` 提供了三方面的能力：

* 关联 `Configuration` 对象
* 解析别名
* 解析 `TypeHandler`

`mybatis-config.xml` 文件的解析是由 `XMLConfigBuilder.parse()` 方法触发的，其中的 `parseConfiguration()` 方法定义了解析 `mybatis-config.xml` 的完整流程。其核心步骤如下：

![](/images/notebook/MyBatis/parseConfiguration.png)

##### Mapper.xml 解析

`mybatis-config.xml` 中可以定义多个 `<mapper>` 标签，指定 `Mapper` 配置文件的位置。MyBatis 会为每个 `Mapepr.xml` 映射文件都创建一个 `XMLMapperBuilder` 实例，从而完成相关解析工作。

#### SQL 解析与 scripting 模块

动态 SQL 是 MyBatis 最大的亮点，这个模块负责动态生成 SQL。具体来说，它会根据运行时用户传入的实参解析动态 SQL 中的标签，并形成 SQL 模板，然后处理 SQL 模板中的占位符，用实参填充占位符，得到真正可执行的 SQL 语句。

scripting 模块是 MyBatis 中动态生成 SQL 的核心模块，它会根据用户传入的实参解析动态 SQL 中的标签，形成 SQL 模板，然后用运行时的实参填充模板中的占位符，得到真正可以在数据库中执行的 SQL 语句。

##### DynamicContext

MyBatis 解析一条动态 SQL 语句的整个流程可能会非常长，其中涉及多层方法的调用、方法的递归、复杂的循环等，其中产生的中间结果需要有一个地方进行存储，那就是 `DynamicContext` 上下文对象。

`DynamicContext` 有两个核心属性：一个是 `sqlBuilder` 字段（`StringJoiner` 类型），用来记录解析之后的 SQL 语句；另一个是 `bindings` 字段（`ContextMap` 类型），用来记录上下文中的一些 KV 信息。`ContextMap` 是 `DynamicContext` 定义的一个内部类，用来记录运行时用户传入的、用来替换“#{}”占位符的实参。

##### SqlNode

MyBatis 在处理动态 SQL 语句的时候，会将动态 SQL 标签解析为 `SqlNode` 对象，多个 `SqlNode` 对象通过组合模式（[设计模式读书笔记之组合模式](../../reading_notes/设计模式的艺术/设计模式的艺术读书笔记之九组合模式)）组成树形结构供上层使用。`SqlNode` 接口充当的就是组合模式中的 `Component` 的角色，它的实现类非常多，很多都对应着一个动态 SQL 标签（组合模式中的 `Leaf` 角色），少数实现类扮演着组合模式中的 `Composite` 角色（比如 `MixedSqlNode`）。

![](/images/notebook/MyBatis/SqlNode.png)

* `StaticTextSqlNode`用于表示非动态的 SQL 片段，其中维护了一个 `text` 字段（`String` 类型），用于记录非动态 SQL 片段的文本内容。
* `MixedSqlNode` 在整个 `SqlNode` 树中充当了树枝节点，也就是扮演了组合模式中 `Composite` 的角色，其中维护的 `List<SqlNode>` 集合了记录 `MixedSqlNode` 下所有的子 `SqlNode` 对象。
* `TextSqlNode` 抽象了包含 “${}”占位符的动态 SQL 片段，它通过一个 `text` 字段（`String` 类型）来记录包含“${}”占位符的 SQL 文本内容。
* `IfSqlNode` 对应了动态 SQL 语句中的 `<if>` 标签，MyBatis 的 <if> 标签的 `test` 属性可以指定一个表达式，当表达式成立时，`<if>` 标签内的 SQL 片段才会出现在完整的 SQL 语句中。
* `TrimSqlNode` 对应 MyBatis 动态 SQL 语句中的 `<trim>` 标签。在使用 `<trim>` 标签的时候，我们可以指定 `prefix` 和 `suffix` 属性添加前缀和后缀，也可以指定 `prefixesToOverrides` 和 `suffixesToOverrides` 属性来删除多个前缀和后缀（使用“|”分割不同字符串）。
* `ForeachSqlNode` 对应 MyBatis 动态 SQL 语句中的 `<foreach>` 标签。我们可以在动态 SQL 语句中使用 `<foreach>` 标签对一个集合进行迭代。在迭代过程中，可以通过 `index` 属性值指定的变量作为元素的下标索引（迭代 `Map` 集合的话，就是 `Key` 值），使用 `item` 属性值指定的变量作为集合元素（迭代 `Map` 集合的话，就是 `Value` 值）。另外，我们还可以通过 `open` 和 `close` 属性在迭代开始前和结束后添加相应的字符串，也可以使用 `separator` 属性自定义分隔符。
* `ChooseSqlNode` 对应 MyBatis 动态 SQL 语句中的 `<choose>` 标签。其内部的`<when>` 标签会被解析成 `IfSqlNode` 对象，`<otherwise>` 标签会被解析成 `MixedSqlNode` 对象。
* `VarDeclSqlNode` 抽象了 `<bind>` 标签，其核心功能是将一个 OGNL 表达式的值绑定到一个指定的变量名上，并记录到 `DynamicContext` 中。

##### SqlSourceBuilder

动态 SQL 语句在被解析成 `SqlNode` 对象后，会经由 `SqlSourceBuilder` 进一步处理。`SqlSourceBuilder` 的核心操作主要有两个：

* 解析“#{}”占位符中携带的各种属性。
* 将 SQL 语句中的“#{}”占位符替换成“?”占位符，替换之后的 SQL 语句就可以提交给数据库进行编译了。

`SqlSourceBuilder` 完成了“#{}”占位符的解析和替换之后，会将最终的 SQL 语句以及得到的 `ParameterMapping` 集合封装成一个 `StaticSqlSource` 对象并返回。

##### SqlSource

动态 SQL 经过 `SqlNode` 和 `SqlSourceBuilder` 之后，最终会由 `SqlSource` 进行最后的处理。`SqlSource` 接口中只定义了一个 `getBoundSql()` 方法，它控制着动态 SQL 语句解析的整个流程。它会根据从 `Mapper.xml` 映射文件（或注解）解析到的 SQL 语句以及执行 SQL 时传入的实参，返回一条可执行的 SQL。接口继承关系如下：

![](/images/notebook/MyBatis/SqlSource.png)

###### DynamicSqlSource

`DynamicSqlSource` 主要负责解析动态 SQL 语句以及“#{}”占位符。

动态 SQL 的判断标准：如果某个 SQL 片段包含了未解析的“${}”占位符或动态 SQL 标签，则为动态 SQL 语句。但是，只包含“#{}”占位符的 SQL 并不是动态 SQL。

###### RawSqlSource

与 `DynamicSqlSource` 不同，`RawSqlSourc` 处理的是非动态 SQL 语句，它解析 SQL 语句的时机是在初始化流程中。

###### StaticSqlSource

无论是 `DynamicSqlSource` 还是 `RawSqlSource`，底层都依赖 `SqlSourceBuilder` 解析之后得到的 `StaticSqlSource` 对象。`StaticSqlSource` 中维护了解析之后的 SQL 语句以及“#{}”占位符的属性信息。

#### SQL 执行

在 MyBatis 中，执行一条 SQL 的核心组件有 `Executor`、`StatementHandler`、`ParameterHandler` 和 `ResultSetHandler`。其中，`Executor` 会调用事务管理模块实现事务的相关通知，同时会通过缓存模块的一级缓存和二级缓存。SQL 语句的真正执行由 `StatementHandler` 实现，它会依赖 `ParameterHandler` 进行 SQL 模板的数据绑定，然后传到数据库执行，从数据库拿到 `ResultSet`。最后，`ResultSetHandler` 会将 `ResultSet` 映射为 Java 对象返回给调用方。下图展示了一条 SQL 执行的大致过程：

![SQL 语句执行过程](/images/notebook/MyBatis/sql-execution-process.png)

##### Executor

MyBatis 中有多个 `Executor` 接口的实现类，如下图所示：

![](/images/notebook/MyBatis/Executor.png)

###### BaseExecutor

`BaseExecutor` 使用模板方法模式实现了 `Executor` 接口中的方法，其中，不变的部分是事务管理和缓存管理两部分的内容，由 `BaseExecutor` 实现；变化的部分则是具体的数据库操作，由 `BaseExecutor` 子类实现，涉及 `doUpdate()`、`doQuery()`、`doQueryCursor()` 和 `doFlushStatement()` 这四个方法。

###### SimpleExecutor

`SimpleExecutor` 是 `Executor` 接口最简单的实现。

###### ReuseExecutor

重用 `Statement` 对象是一种常见的优化手段，不仅可以减少 SQL 预编译开销，还能降低 `Statement` 对象的创建和销毁频率，这在一定程度上可以提升系统性能。`ReuseExecutor` 就实现了重用 `Statement` 的优化。

`ReuseExecutor` 中的 `do*()` 方法实现与 `SimpleExecutor` 实现完全一样，两者唯一的区别在于其中依赖的 `prepareStatement()` 方法：`SimpleExecutor` 每次都会创建全新的 `Statement` 对象，`ReuseExecutor` 则是先尝试查询 `statementMap` 缓存，如果缓存命中，则会重用其中的 `Statement` 对象。

###### BatchExecutor

批处理是 JDBC 编程中的一种常见优化手段。不过，有一点需要特别注意：每次向数据库发送的 SQL 语句的条数是有上限的，如果批量执行的时候超过这个上限值，数据库就会抛出异常，拒绝执行这一批 SQL 语句，所以我们需要控制批量发送 SQL 语句的条数和频率。`BatchExecutor` 是用于实现批处理的 `Executor` 实现类。

###### CachingExecutor

`CachingExecutor` 是一个 `Executor` 装饰器实现，会在其他 `Executor` 的基础之上添加二级缓存的相关功能。

#### 插件

我们可以通过自定义的插件来扩展 MyBatis，或者改变 MyBatis 的默认行为。插件模块中最核心的接口就是 `Interceptor` 接口，所有 MyBatis 插件都必须要实现的这个接口。

### 接口层

接口层中的接口都是 MyBatis 最常使用的一些接口，比如 `SqlSession` 和 `SqlSessionFactory` 等，其中最核心的接口是 `SqlSession`，我们可以通过它获取 `Mapper` 代理、执行 SQL 语句、控制事务开关等。

#### SqlSession

`SqlSession` 是 MyBatis 对外提供的一个 API 接口，整个 MyBatis 接口层也是围绕 `SqlSession` 接口展开的，SqlSession 接口中定义了下面几类方法。

* `select*()` 方法：用来执行查询操作的方法，`SqlSession` 会将结果集映射成不同类型的结果对象，例如，`selectOne()` 方法返回单个 Java 对象，`selectList()`、`selectMap()` 方法返回集合对象。

* `insert()`、`update()`、`delete()` 方法：用来执行 DML 语句。

* `commit()`、`rollback()` 方法：用来控制事务。

* `getMapper()`、`getConnection()`、`getConfiguration()` 方法：分别用来获取接口对应的 `Mapper` 对象、底层的数据库连接和全局的 `Configuration` 配置对象。

MyBatis 提供了两个 `SqlSession` 接口的实现类，还提供了 `SqlSessionFactory` 来创建 `SqlSession` 对象。相关类的关系如下：

![](/images/notebook/MyBatis/SqlSession-interface.png)

其中，`DefaultSqlSession` 是 `SqlSession` 的默认实现，它维护了一个 `Executor` 对象，用来完成数据库操作以及事务管理。

`DefaultSqlSessionFactory` 是创建 `DefaultSqlSession` 的具体实现。

`SqlSessionManager` 同时实现了 `SqlSession` 和 `SqlSessionFactor`y 两个接口，也就是说，它同时具备操作数据库的能力和创建 `SqlSession` 的能力。

