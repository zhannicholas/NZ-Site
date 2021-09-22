---
date: "2021-09-18T22:34:56+08:00"
title: "gPRC 与 Protocol Buffers"
authors: ["zhannicholas"]
categories:
  - RPC
  - Communication
tags:
  - RPC
  - Communication
draft: false
toc: true
mathjax: true
---

最近工作中需要用到 gPRC，赶紧学了一下，顺便做了些笔记。

gPRC 与 Protocol Buffers 经常一起使用，二者的关系非常密切。因为 gPRC 不仅将 Protocol Buffers 作为自己的 IDL（Interface Definition Language），还将其用作底层的消息交换格式。

## gRPC

> A hight performance, open source universal RPC framework.

[gPRC](https://grpc.io) 是一个由 Google 出品的 RPC（Remote Procedure Call） 框架。在笔者写这篇文章的时候，gPRC 还是[云原生计算基金会（CNCF）](https://cncf.io/) 的一个孵化项目。

gRPC 的核心思想和其它的 RPC 框架一样，都是定义一个服务，然后声明可以被远程调用的方法以及方法的参数和返回类型。服务端实现定义的接口并处理客户端的调用，而客户端则有一个桩对象（stub），它提供了与服务端相同的方法。

### gRPC 调用过程

gRPC 的使用者通常会在服务端实现 `.proto` 文件中描述的服务 API，然后在客户端进行 API 的调用。每一个 API 都涉及服务端和客户端两方面，服务端负责实现，而客户端进行调用，它们是一一对应的。

服务端不仅会实现 `.proto` 所描述的服务中声明的方法，还会运行一个处理客户端调用的服务器。gRPC 会解码传入请求，执行服务方法，并编码服务响应。而在客户端这一侧，会有一个实现了相同服务方法本地对象（一般叫 `stub`，有些语言也称 `client`）。客户端会直接调用这个本地对象上的方法，使用恰当的 Protocol Buffers 消息类型包裹方法参数。gRPC 会将请求发送给服务端，并获取服务端的响应数据。

下面这张图来自 gRPC 官网，它不仅展示出了 gRPC 中客户端与服务端交互的过程，还暗示了 gRPC 是跨语言的：

![gRPC](/images/gRPC/gRPC-call-process.svg)

当下分布式系统和微服务架构非常流行，RPC 的这一大特点使得我们创建分布式应用和服务更加简单。

### 定义服务

默认情况下，gRPC 使用 Protocol Buffers 描述服务接口和消息负载（message payload）的结构。我们也可以按照实际需要，选择其它的语言来描述接口和消息的结构。

```proto
service HelloService {
  rpc SayHello (HelloRequest) returns (HelloResponse);
}

message HelloRequest {
  string greeting = 1;
}

message HelloResponse {
  string reply = 1;
}
```
以上代码使用 Protocol Buffers 描述了 `HelloRequest` 和 `HelloResponse` 这两个消息的结构，以及服务接口 `HelloService`。在服务接口 `HelloService` 中，有一个简单的方法叫 `SayHello`，它从客户端接收 `HelloRequest` 并以 `HelloResponse` 响应。`SayHello` 作为一个入门的例子，给我们展示的是 gRPC 中最简单的通信模式——Unary RPC。

实际上，gRPC 中有四种通信模式：
* **Unary RPC**：客户端向服务端发送单个请求，并从服务端获取单个响应。用 Protocol Buffers 描述服务接口的方法，就是：`rpc SayHello (HelloRequest) returns (HelloResponse)`。
* **Server Streaming RPC**：客户端向服务端发送一个请求，并从服务端获得一个响应流。客户端会从这个响应流中读取一个消息序列，gRPC 会保证每个 RPC 调用中消息的顺序。用 Protocol Buffers 描述服务接口的方法，就是：`rpc SayHello (HelloRequest) returns (stream HelloResponse)`
* **Client Streaming RPC**：客户端向流中写入一个消息序列，然后把它发给服务端，等待服务端返回单个响应。gRPC 依然会保证客户端流中消息的顺序。用 Protocol Buffers 描述服务接口的方法，就是：`rpc SayHello (stream HelloRequest) returns (HelloResponse)`
* **Bidirectional Streaming RPC**：客户端以消息流的方式给服务端发送数据，而服务端也以消息流的方式响应数据。gRPC 会保证每个流当中消息的顺序。用 Protocol Buffers 描述服务接口的方法，就是：`rpc SayHello (stream HelloRequest) returns (stream HelloResponse)`

不难发现，流式通信与普通通信在描述时只有一个差别：是否有 `stream` 关键字。


## Protocol Buffers

> Protocol buffers are a language-neutral, platform-neutral extensible mechanism for serializing structured data.

[Protocol Buffers](https://developers.google.com/protocol-buffers) 是一种对结构化数据进行序列化的机制，它不仅跨语言、跨平台，还可扩展。

### 消息类型的定义

直接看官网的例子：

```proto
syntax = "proto3";

message SearchRequest {
  string query = 1;
  int32 page_number = 2;
  int32 result_per_page = 3;
}
```

以上定义了一个非常简单的消息类型（message type）。如果要使用 `proto3`，文件的第一非空白且非注释的行必须这么写，否则编译器会认为我们使用的是 `proto2`。在 `SearchRequest` 内部，声明了三个字段（键值对），每个字段都有自己的名字和类型。此外，每个字段还有一个与之相关联的数字（unique number），一个消息中的每个字段的数字各不相同。其实，这些数字是用来识别二进制格式的消息中的字段的，所以它们应该是唯一的，并且在消息类型投入使用之后不应该再被修改。

标识字段的数字也是有范围限制的，允许的范围是 $[1, 2^{29} - 1]$。其中，[19000, 19999] 是 Protocol Buffers 自己使用的，我们不可使用它们。范围在 [1, 15] 内的数字采用一个字节编码（编码内容包括数字本身和字段类型），应当被用在使用最频繁的字段上；而范围在 [16, 2047] 内的数字在编码时采用两个字节，适合被用在使用没那么频繁的字段上。

### 字段类型

消息的字段可以是标量类型（scalar type），也可以是复合类型（比如枚举类型或其它消息类型）。

#### 标量类型

以下表格列出了 Protocol Buffers 中的标量类型与其在 Java/Python 中对应的数据类型：

| .proto Type | Java Type | Python Type |
|-------------|-----------|-------------|
|    double   |   float   |    float    |
|    float    |   float   |    float    |
|    int32    |   int     |    int      |
|    int64    |   long    |    int/long |
|    uint32   |   int     |    int/long |
|    uint64   |   long    |    int/long |
|    sint32   |   int     |    int      |
|    sint64   |   long    |    int/long |
|    fixed32  |   int     |    int/long |
|    fixed64  |   long    |    int/long |
|    sfixed32 |   int     |    int      |
|    sfixed64 |   long    |    int/long |
|    bool     |   boolean |    bool     |
|    string   |   String  | str/unicode |
|    bytes    | ByteString|    str      |

不同类型的具体细节可以参考 [原表格](https://developers.google.com/protocol-buffers/docs/proto3#scalar)。

#### 枚举类型

如果我们希望消息字段的值位于某个特定的集合中，则可以将该字段定义成枚举类型（enumeration）。例如：

```proto
message SearchRequest {
  string query = 1;
  int32 page_number = 2;
  int32 result_per_page = 3;
  enum Corpus {
    UNIVERSAL = 0;
    WEB = 1;
    IMAGES = 2;
    LOCAL = 3;
    NEWS = 4;
    PRODUCTS = 5;
    VIDEO = 6;
  }
  Corpus corpus = 4;
}
```

在定义枚举类型时，我们必须让数字 0 与枚举类型的第一个元素相关联。因为 0 是数值类型的默认值，0 与第一个元素相关联的目的是为了维持对 `proto2` 的兼容性。

#### 默认值

不同的数据类型有着不同的默认值。当 Protocol Buffers 解析消息时，如果发现编码后的消息中并不存在某个字段，则会将对应字段的值设置为字段类型的默认值。不同类型的默认值如下：

|    字段类型    |     默认值    |
|---------------|---------------|
|    string     |  empty string |
|    bytes      |  empty bytes  |
|    bool       |  false        |
| numeric types |  zero         |
|    enum       | first defined enum value, which must be 0 |
|    message    |  not set      |
| repeated field|  empty        |

### 在 Java 中使用 Protocol Buffers

Protocol Buffers 的编译器 `protoc` 能够根据目标语言为我们生成 `.proto` 文件对应的代码。对于 Java 来说，`protoc` 会为每一种消息类型都生成一个 `.java` 文件，每个 `.java` 文件中都有一个对应的 `Builder` 负责创建消息类的实例。

直接来看官网的一个例子：
```proto
syntax = "proto3";

package tutorial;

option java_multiple_files = true;
option java_package = "com.example.tutorial.protos";
option java_outer_classname = "AddressBookProtos";

message Person {
  optional string name = 1;
  optional int32 id = 2;
  optional string email = 3;

  enum PhoneType {
    MOBILE = 0;
    HOME = 1;
    WORK = 2;
  }

  message PhoneNumber {
    optional string number = 1;
    optional PhoneType type = 2;
  }

  repeated PhoneNumber phones = 4;
}

message AddressBook {
  repeated Person people = 1;
}
```

这段代码首先告诉编译器使用 `proto3`，然后声明了当前 `.proto` 文件所属的包（package），用于解决不同项目之间可能出现的命名冲突，它的作用和 Java 中的包很相似。不过你会发现，后面还有一个 `java_package`，它给出了 Java 的包名，用于存放生成的 Java 类文件。如果没有这一行，编译器会使用 `package` 的值作为 Java 的包名。

`java_outer_classname` 则定义了表示整个 `.proto` 文件的 Java 类名，而 `java_multiple_files` 则告诉编译器要将每个生成的 Java 类都放到一个单独的 `.java` 文件中。

#### Builder

编译器 `protoc` 生成的所有 Java 消息类都是 **不可变** 的。这意味着，消息对象在被构造出来之后，就不能被修改，就像 Java 中的 `String` 一样。要构建一个消息对象，我们必须先构造出对应的 `Builder` 对象，使用 `Builder` 为字段赋值，最后调用 `Builder` 的 `build()` 方法完成对象的创建。



## 参考资料

1. [gPRC Documentation](https://grpc.io/docs/).
2. [Protocol Buffers Guide](https://developers.google.com/protocol-buffers/docs/overview).