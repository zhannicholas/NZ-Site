---
title: "Java Web复习笔记"
date: 2018-08-19T23:02:41+08:00
draft: false
categories:
  - Java Web
tags:
  - Java
authors: ["zhannicholas"]
toc: true
---

# Java WEB复习笔记

>这是为了准备秋招面试而对Java Web开发进行的复习。

首先，对于一个Java Web应用，它由一组Servlet、HTML页、实用类、以及其它可以被绑定的资源构成。它运行于实现了Servlet规范的Servlet容器中。

## Servlet

Java Servlet和平台无关，它运行于Servlet容器中。Servlet容器负责Servlet和客户端的通信以及调用Servlet的方法，Servlet和客户端的通信采用的是 **请求/响应** 模式。

### Servlet的功能

1. 创建并返回基于客户端请求的动态HTML页面。
2. 创建可嵌入到现有HTML页面中的HTML片段。
3. 与其它服务器资源进行通信。

### Sevlet容器

Servlet容器可以创建Servlet，并调用Servlet相关生命周期方法。还是运行JSP等的软件环境。

### Servlet生命周期方法

1. 构造器：只调用一次。只有第一次请求Servlet的时候，才调用构造器，创建Servlet实例。即Servlet使 **单实例** 的。
2. `init()`方法：只调用一次。在Servlet实例创建完毕后立即被调用，用于初始化当前Servlet。
3. `service()`方法：每次请求都会调用，用于相应请求。
4. `destroy()`方法：只调用一次。在当前Servlet所在的Web应用被卸载前调用，用于释放当前Servlet所占有的资源。

### ServletConfig接口

这个接口封装了 **当前** Servlet的配置信息，并可以获取ServletContext对象。

- `String getServletName();`: 获取Servlet的配置名。
- `ServletContext getServletContext();`: 获取对应的ServletConfig对象。
- `String getInitParameter(String var1);`: 获取指定参数名的初始化参数。
- `Enumeration<String> getInitParameterNames();`: 获取参数名组成的Enumerarion。

### ServletContext接口

Servlet引擎为每一个Web应用都创建一个对应的ServletContext对象。这个对象由Web应用中 **所有** 的Servlet所共享。它实际代表了当前的Web应用。

ServletContext有很多的功能，比如：

1. 获取当前Web应用的初始化参数
    - `String getInitParameter(String var1);`: 获取指定参数名的初始化参数。
    - `Enumeration<String> getInitParameterNames();`: 获取参数名组成的Enumerarion。

2. 获取虚拟路径所映射的本地路径
    -`String getRealPath(String var1);`
3. 访问资源文件
4. 记录日志
5. 设置和获取应用属性

### ServletRequest接口

ServletRequest接口封装了请求信息，可以从中获取任何请求信息。

#### GET&POST请求

1. GET方式
    - 将请求信息附加在请求地址后面
    - 传送的数据量有限
    - 传输信息在浏览器地址栏 **可见**
    - 常见于输入URL或点击网页上的超链接
2. POST方式
    - 将数据作为HTTP消息的实体内容传送
    - 传送的数据量比GET方式大得多。
    - 传输信息在浏览器地址栏 **不可见**
    - 主要用于提交表单数据

#### 获取请求参数

1. `String getParameter(String var1);`: 根据请求参数的名字返回参数值。
2. `Enumeration<String> getParameterNames();`：返回参数名对应的Enumaration对象。
3. `String[] getParameterValues(String var1);`：根据请求参数的名字返回请求参数对应的数组，如获取多选框信息。
4. `Map<String, String[]> getParameterMap();`：返回请求参数的键值对。

### ServletResponse接口

ServletResponse接口封装了响应信息，给客户端的响应取决于本接口实现的方法。常用的方法有：

- `PrintWriter getWriter() throws IOException;`: 返回一个PrintWriter对象。然后我们可以调用该对象的`print("something")`方法打印信息到浏览器上。
- `void setContentType(String var1);`: 设置响应的内容类型。

### GenericServlet

GenericServlet同时实现了Servlet接口、ServletConfig接口和 Serializable接口，和各种协议无关。HttpServlet就继承于它。

### HttpServlet

HttpServlet继承自GeniricServlet实现类，用于 HTTP协议。它在`service()`方法中将使用`HttpServletRequest.getMothod()`方法来获取请求方式，然后根据不同的请求方式创建不同的具体的处理方式。

## JSP

>JSP页面由HTML语句和嵌套在其中的Java代码组成。本质还是Servet。JSP页面中的java代码需要嵌套在`<%`和`%>`中。

### JSP运行原理

当Web容器接收到以`.jsp`为扩展名的URL请求时，将该请求转交给JSP引擎处理。每个JSP页面在第一次被访问的时候，JSP引擎都会把它翻译为一个Servlet源程序并编译。然后Web容器就可以像调用普通Servlet程序一样来处理这个由JSP页面翻译而来的Servlet程序。

### JSP页面的隐含对象

这些隐含对象不用声明，可以直接使用。一共有9个。

```Java
public void _jspService(final javax.servlet.http.HttpServletRequest request, final javax.servlet.http.HttpServletResponse response)
      throws java.io.IOException, javax.servlet.ServletException {

    final javax.servlet.jsp.PageContext pageContext;
    javax.servlet.http.HttpSession session = null;
    final javax.servlet.ServletContext application;
    final javax.servlet.ServletConfig config;
    javax.servlet.jsp.JspWriter out = null;
    final java.lang.Object page = this;
    javax.servlet.jsp.JspWriter _jspx_out = null;
    javax.servlet.jsp.PageContext _jspx_page_context = null;

    // 内嵌Java代码翻译后的位置，这里有第9个隐含对象: exception

  }
```

9个隐含对象分别是：

1. `request`: HttpServletRequest的一个对象。
2. `response`: HttpSevletResponse的一个对象。
3. `pageContext`: PageContext的一个对象，可以从中获取到其它8个隐含对象以及页面的其它信息。
4. `session`: HttpSession的一个对象，代表浏览器和服务器的一次会话。
5. `application`: ServletContext的一个对象，代表当前的Web应用。
6. `config`: ServletConfig的一个对象。
7. `out`: JspWriter的一个对象。调用`out.println()`可直接把字符串打印到浏览器。
8. `page`： 指向当前JSP对应的Servlet对象的引用，使Object类型，只能使用Object类的方法。
9. `exception`：异常对象。在JSP页面中声明了`isErrorPage=true`后才会启用。

### JSP基本语法

#### JSP模板元素

JSP中的HTML代码就是JSP模板元素。这是整个网页的骨架。

#### JSP表达式

可以使用JSP表达式直接将一个Java变量或者表达式的计算结果输出到浏览器。待输出的变量或者表达式要在`<%=`和`%>`之间。

- 计算结果是一个字符串。
- 变量或表达式后面不能有分号，因为每个表达式都被翻译为一条`out.print()`语句。

#### JSP脚本片段

脚本片段就是嵌套在`<%`和`%>`之间的Java代码。这些脚本片段将被原封不动的被搬进JSP页面翻译成Servlet的`_JspService()`方法中。

- 多个脚本片段中的代码是可以相互访问的。
- 单个脚本片段中的Java语句可以不少完整的，但多个脚本片段组合后的结果必须是完整的。

#### JSP声明

JSP声明将Java代码封装在`<%!`和`%>`之间。这里面的代码会被插入到Servlet的`_jspService()`方法外面。
常用来定义相关的静态代码块、成员变量和方法。

### JSP中对域对象的属性操作

这里的域对象指的是`request`, `session`, `application`, `pageContext`这四个对象。它们都拥有下面的几个和属性相关的方法：

- `Object getAttribute(String var1);`: 获取指定属性值。
- `Enumeration<String> getAttributeNames();`: 获取所有属性名组成的Enumeration对象。
- `void setAttribute(String var1, Object var2);`: 设置属性。
- `void removeAttribute(String var1)`: 移除指定属性。

它们的作用范围各不相同，下面从小到大排列：

- `pageContext`: 仅限于当前页面，范围最小。
- `request`: 仅限于同一个请求。
- `session`: 仅限于一次会话（默认从浏览器打开到关闭）。
- `application`: 仅限于当前Web应用，范围最大。

### JSP指令

JSP指令用来告诉JSP引擎如何处理页面中的其余部分。基本的语法格式为：`<%@ 指令 属性名="属性值" %>`。主要有一下三种指令：

1. page指令：用来定义页面的各种属性。
2. include指令：用来通知JSP引擎在翻译JSP页面的时候将其他文件中的内容包含进当前JSP页面翻译成的Servlet中。使用的是 **相对路径** 。
3. taglib指令：用来引入所使用的标签库

### JSP标签

1. `<jsp:include>`标签：用来把应一个资源的输出内容插入到当前JSP页面的输出内容中。使用 **相对路径**。
2. `<jsp:forward>`标签：用于把请求转发个另一个资源。使用 **相对路径**。
3. `<jsp:param>`标签：用来向程序传递参数信息。使用 **相对路径**。

### 请求的转发与重定向

#### 请求转发

可以使用`RequestDispatcher`接口中的`forward()`方法进行请求转发。这个接口中定义了两个方法：

1. `include(ServletRequest request, ServletResponse response)`方法：转发到请求到当前Web应用中的其他资源。
2. `forward(ServletRequest request, ServletResponse response)`方法：在响应中包含资源。

可以使用`RequestDispatcher getRequestDispatcher(String forwardPath);`来获取`RequestDispatcer`。

#### 请求的重定向

可以使用`sendRedirect()`方法来进行请求的重定向。不仅可以重定向到当前应用程序中的其它资源，还可以到同一站点上的其它应用程序中的资源，甚至
可以使用绝对路径到其它站点的资源。

#### 请求转发和重定向的比较

本质区别：请求转发只向服务器发出 **一次** 请求，而重定向发出了 **两次** 请求。

方法         | 请求转发                 | 请求重定向
:-------    | :-------------------:   |:--------------------:|
|地址栏变化  | 首次发出的请求地址         |重定向后最后响应的那个地址|
|最终Servlet中的request对象|和中转的那个request是同一个对象|和中转的那个request不是同一个对象|
|作用范围    | 限于当前Web应用           |服务器上任何资源|
| "\\"       |代表当前Web应用的根目录     |代表整个Web站点的根目录|

### Cookie与Session

HTTP是一种无状态的协议。`Cookie`和`Session`是Servlet中的两种会话跟踪机制。

#### Cookie

`Cookie`采用的是在 **客户端** 保持HTTP状态信息的方案。它是在当浏览器访问WEB服务器上的某个资源的时候，有WEB服务器在HTTP响应消息头中附带传送的一个小的文本文件。_一旦浏览器保存了这个Cookie，以后每次访问服务器的时候都会在HTTP消息头中将这个Cookie回传给服务器。_

- 可以通过`response`对象的`addCookie(Cookie cookie)`方法向浏览器写入Cookie。
- 可以通过`request`对象的`getCookie()`方法从客户端获取Cookie。

默认情况下的Cookie当关闭浏览器的时候会消失。可以通过`setMaxAge()`方法设置Cookie的存活时间。

#### Session

`Session`采用的是在 **服务端** 保持HTTP状态信息的方案，以Cookie（默认实现方式，系统会创造一个名为JSESSIONID的输出cookie，称为session cookie）或者URL重写（禁用Cookie后的解决方案）为基础，使用`SessionId`唯一标识一个Session。

1. Session的创建
    - 当服务端的某个程序调用类似于`HttpServletRequest.getSession()`的方法的时候，Session对象 **才会被创建** 。
2. Session的删除
    - 程序调用`HttpSession.invalidate()`方法
    - 超过有效期
    - 服务端进程终止
3. URL重写
    - 使用`HttpServletResponse`接口定义的的`encodeURL()`或`encodeRedirectURL()`方法。

## JDBC

JDBC为Java程序员提供了一个独立于特定数据库管理系统、通用SQL数据库存取和操作的公共接口，可以使用它来连接提供了JDBC驱动的数据库。

### Driver接口

`Java.sql.Driver`接口是所有JDBC驱动程序都需要实现的接口，由不同的厂商提供不同的实现。

### 加载与注册JDBC驱动

- 可以通过调用`Class`类的静态方法`forName()`来加载JDBC驱动。
- `DriverManager`类负责管理驱动程序，它会调用Driver接口的实现。

### 建立数据库连接

数据库连接用来向数据库服务器发送命令。

- 可以调用`DriverManager`类的`getConnection()`方法建立到数据库的连接。还可以使用`Driver`接口的`connect()`方法建立到数据库的连接。其中`DriverManager`使用起来更加方便，还可以管理多个不同的驱动程序。
- JDBC URL用来标识一个被注册的驱动程序。驱动程序管理器会通过这个URL选择正确的驱动程序，从而建立到数据库的连接。JDBC URL的标准由三部分组成，各个部分之间用冒号`:`分隔。

  - 协议：JDBC中总是`jdbc`
  - 子协议：用来标识一个数据库驱动程序
  - 子名称：为定位数据库提供足够的信息

  比如：使用mysql数据库的url连接可以是这样的：`jdbc:mysql：//localhost:3306/database`。
`java.sql`中有三个接口分别定义了对数据库的不同访问方式：

1. Statement接口
    - `Statement`接口用来执行静态SQL语句。
    - 可以通过调用`Connection`对象的`createStatement()`方法创建`Statement`对象。剩下的两个接口都是这个接口的子类型。
2. PreparedStatement
    - `PreparedStatement`接口用来执行预编译的SQL语句。
    - 可以通过调用`Connection`对象的`prepareStatement()`方法来获取`PreparedStatement`对象。
    - `PreparedStatement`对象多代表的SQL语句中的参数用问号`?`来表示，并通过对应的`setXXX(index, value)`来设置这些参数。其中`index`从`1`开始。
    - 使用本接口可以防止SQL注入。
3. CallableStatement
    - `CallableStatement`接口用来执行SQL存储程序。

### 数据库的查询和更新

1. 数据库更新
    - 常用`int executeUpdate​(String sql)`方法可以进行数据库的插入、修改和删除操作。
2. 数据库查询
    - 常用`ResultSet executeQuery​(String sql)`方法来进行数据库的查询操作。

### ResultSet

`ResultSet`接口以逻辑表格的形式封装了执行数据库操作得到的结果集。`ResultSet`对象维护了一个指向当前数据行的 **游标** 。初始的时候，游标在表格的第一行 **之前** 。可以通过`next()`方法移动到下一行，然后调用`getXXX(index)`或`getXXX(columnName)`来获取对应列的值。

### 常用数据类型转换表

Java类型            | SQL类型                   |
:------------------ |:-------------------------|
|int                |INTEGER                   |
|long               |BIGINT                    |
|short              |SMALLINT                  |
|String             |CHAR, VARCHAR, LONGVARCHAR|
|boolean            |BIT                       |
|byte               |TINYINT                   |
|byte array         |BINARY, VARBINART         |
|java.sql.Date      |DATE                      |
|java.sql.Time      |TIME                      |
|java.sql.Timestamp |TIMESTAMP                 |

### 使用JDBC驱动程序处理元数据

元数据是关于数据的数据。

#### DatabaseMetaData类

`DatabaseMetaData`类提供了获取和数据库系统有关的各种信息的方法，也就是 **元数据** 。而又可以从`Connection`对象获得`DatabaseMetaData`的对象。

#### ResultSetMetaData类

`ResultSetMetaData`类提供了获取`ResultSet`对象中列的类型和属性信息的方法。

- 可以通过调用`ResultSet`对象的`getMetaData()`方法来获取它的对象。
- 可以使用`getColumnCount()`方法来获取SQL语句中查询了多少列。
- 可以使用`getColumnLabel(int colunm)`方法来获取指定列的别名。其中索引从1开始。

### 数据库连接池

数据库连接池的基本思想是为数据库建立一个缓冲池，并预先往缓冲池里放入一定数量的连接。当需要和数据库建立连接时，直接从连接池里取出连接，用完之后再归还给连接池。

数据库连接池负责分配、管理和释放数据库连接，它允许应用程序重复使用一个现有的数据库连接，而不是重新建立一个。

## MVC设计模式

MVC把应用分为模型、视图和控制器三个模块，它们各自处理不同而任务。

### 模型

模型应用程序的主体部分，表示业务数据和业务逻辑。一个模型可以为多个视图提供数据。

### 视图

视图接收用户输入、向用户展示相关数据。但不进行任何实际的业务处理。

### 控制器

控制器接收用户请求并决定调用哪个模型去处理请求，然后决定调用哪个视图显示模型处理返回的数据。

## Filter(过滤器)

> Filter是Java Web的一个重要组件，它的基本功能是对Servlet容器调用Servlet的进程进行拦截（拦截请求和响应），从而在Servlet进行响应处理的 **前后** 实现一些特殊的功能。

Servlet的API中定义了三个供开发人员编写Filter程序的接口：`Filter`, `FilterChain`, `FilterConfig`。Filter程序是一个实现了Filter接口的Java类，它和Servlet非常类似，并且由Servlet容器进行调用和执行。没有相应的Filter实现类可供继承，要开发Filter，需要自己实现接口。

和使用Servlet类似，Filter程序需要在`web.xml`文件中注册和设置它所能拦截的资源（Jsp, Servlet, image, html），这也可以通过 **注解** 来完成。

对于多个Filter拦截同一个url的情况：

- 使用注解：多个Filter的执行顺序的由Filter实现类名的字符顺序来决定，这会给维护增加难度。比如：现在有`Test1Filter`和`Test2Filter`,它们都对`test.jsp`进行拦截。初始化的顺序是：`Test1Filter`先初始化，而后是`Test2Filter`。拦截执行的顺序是：`Test2Filter`在前，而`Test1Filter`在后。

- 使用`web.xml`：执行按照`filer-mapping`声明顺序执行，这就更加清晰可见。最好使用后一种方法。

### Filter接口

1. `default void init(FilterConfig filterConfig) throws ServletException`
    - Filer对象的初始化方法，在Filter对象被创建时（Filter对象在Servlet容器加载当前Web应用时被创建）执行，只执行 **一次**
    - FilterConfig类似于ServletConfig
2. `void doFilter(ServletRequest var1, ServletResponse var2, FilterChain var3)`
    - 逻辑代码，每次拦截都会被调用
    - FilterChain: 多个Filter构成的一个链。在特定的操作完成后，可以在当前Filter对象的`doFilter()`方法内部需要调用FilterChain 对象的`chain.doFilter(request,response)`方法才能把请求交付给Filter链中的下一个Filter或者目标Servlet程序去处理，也可以直接向客户端返回响应信息，或者利用RequestDispatcher的`forward()`和`include()`方法，以及HttpServletResponse的`sendRedirect()`方法将请求转向到其他资源。
3. `default void destroy()`
    - 用来释放当前Filter所占用的资源，在Filter被销毁之前调用，只调用一次。

### Filter的配置

#### Filter的注册

在`web.xml`中注册Filter，使用`<filter>`元素，也可以用注解注册。使用`web.xml`时：

- `<filter-name>`为Filter指定一个名字，不能为空。
- `<filter-class>`为Filter的完整限定类名。
- `<init-param>`用来设置初始化参数（使用`<param-name>`指定参数名，`<param-value>`指定参数值）。

这一步骤使用注解会方便得多。

#### Filter的映射

使用`<filter-mapping>`元素，可以为一个Filter设置所负责拦截的资源，其中有两种方式可以指定：Servlet名称和资源访问的请求路径(url)。

- `<filter-name>`子元素用于设置filter的注册名，该名必须是已经注册了的名字。
- `<url-pattern>`用来设置拦截的请求路径
- `<servlet-name>`用来指定拦截的Servlet名称
- `<dispatcher>`指定所拦截的资源被Servlet容器调用的方式。可以是：`REQUEST`, `INCLUDE`, `FORWARD`和`ERROR`。默认是`REQUEST`。
  - REQUEST: 当用户 **直接** 访问页面的时候，这个Filter会被调用。如果目标资源是通过`RequestDispatcher`的`include()`或`forward()`方法访问的话，就不会被调用。
  - INCLUDE: 只有当目标资源时通过`RequestDispatcher`的`include()`方法访问时，Filter才会被调用。
  - FORWARD: 只有当目标资源时通过`RequestDispatcher`的`forward()`方法访问时，Filter才会被调用。
  - ERROR: 只有当目标资源时通过声明式异常处理机制调用的时候，Filter才会被调用。

## Listener(监听器)

> Listener是专门用来对其它对象身上发生的事件或者状态改变进行监听和采取相应处理的对象。

Servlet监听器是Servlet规范中定义的一种特殊的类，用于监听Web应用程序中的`ServletContext`, `HttpSession`和`ServletRequest`等域对象的创建、销毁以及属性发生改变的事件。

### Listener的分类

#### 监听域对象自身的创建和销毁的Listener

1. ServletContextListener接口
    - 这个接口用于监听ServletContext对象的创建和销毁事件。当ServletContext对象被创建的时候，触发`contextInitialized()`方法；当ServletContext对象被销毁的时候，触发`contextDestroyed()`方法。常用来对当前Web应用进行初始化操作。
2. HttpSessionListener接口
    - 这个接口用于监听HttpSession对象的创建和销毁事件。当Session对象被创建的时候，触发`sessionCreated()`方法；当Session对象被销毁的时候，触发`sessionDestroyed()`方法。
3. ServletRequestListener接口
    - 这个接口用于监听ServletRequest对象的创建和销毁事件。当ServletRequest对象被创建的时候，触发`requestInitialized()`方法；当ServletRequest对象被销毁的时候，触发`requestDestroyed()`方法。

#### 监听域对象中属性的增加、删除或修改的Listener

有三个Listener接口，分别是`ServletContextAttributeListener`, `HttpSessionAttributeListener`和`ServletRequestAttributeLitener`。它们中分别定义了监听对应域对象的属性的增加、修改和删除的方法。方法名完全相同，只是接受的参数不同。分别是：`attributeAdded()`, `attributeReplaced()`和`attributeRemoved()`。

#### 监听绑定到HttpSession域中某个对象状态的Listener

有两个特殊的Listener接口用来帮助JavaBean对象了解自己在Session域中的状态。分别是：

1. HttpSessionBindingListener接口
    - 感知自己被绑定到Session中。Web服务器此时会调用`valueBound()`方法。
    - 感知自己被从Session中解除绑定。Web服务器此时会调用`valueUnbound()`方法。
2. HttpSessionActivationListener接口
    - 绑定到HttpSession对象的对象将要随HttpSession对象被钝化之前，Web浏览器此时会调用`sessionWillPassivate()`方法。
    - 绑定到HttpSession对象的对象将要随HttpSession对象被活化之后，Web浏览器此时会调用`sessionDidActive()`方法。

<!-- ## 文件上传和下载

### 基于表单的文件上传

使用表单元素`<input type="file">`可以完成基于表单的文件上传操作，需要指定表单的`enctype`属性值为`multipart/form-data`，表示表单以二进制传输数据。默认为`application/x-www-form-urlencoded`，这种编码方案使用有限的字符集，不适合大容量的二进制数据或者包含了非ASCII字符的文本。 -->
