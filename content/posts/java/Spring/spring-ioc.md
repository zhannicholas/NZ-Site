---
date: "2021-08-21T13:49:54+08:00"
title: "Spring Ioc"
authors: ["zhannicholas"]
categories:
  - Spring
tags:
  - Spring
  - Java
draft: false
toc: true
---

Ioc（Inverse of Control），又叫 DI（Dependence Injection）。它是这样一个过程：对象声明自己的依赖，然后容器在创建 Bean 的时候注入这些依赖。如果不使用 IoC，我们在创建对象之前就需要先把对象的依赖创建出来，这个正向的过程会导致对象与对象之间的强耦合。如果反过来，对象不自己创建依赖，而是由 Spring 的 Ioc 容器自动装配，这就是控制反转。逆向的过程使得程序的结构变得更加灵活，没有强耦合，还有利于对象的复用。

![Mindmap](/images/java/spring/spring-ioc-mindmap.png)

## Ioc 容器

在 Spring 中，`org.springframework.context.ApplicationContext` 接口就是 IoC 容器的抽象表示，它负责 Bean 的实例化、配置以及组装。那么，IoC 容器是如何知道要管理哪些 Bean 呢？答案是配置元数据（Configuration Metadata）。配置元数据可以是 XML、注解，还可以是 Java 代码。

![The Spring Ioc container](/images/java/spring/container-magic.png)

### 配置元数据

Spring 的 Ioc 容器会读取配置元数据，然后根据配置元数据去实例化、配置和组装应用程序中的 Bean。在 Spring 的早期版本中，配置信息使用的是 XML。Spring 2.5 开始支持基于注解的配置，我们常用的 `@Required` 和 `@Autowired` 就是基于注解的配置。 Spring 3.0 开始支持基于 Java 代码的配置。现在，我们甚至可以同时使用 XML 和 注解去配置 Bean。

实际上，在 IoC 容器内部，这些配置元数据会被解析成 `BeanDefinition` 对象，`BeanDefinition` 封装的就是 Bean 的定义和描述信息，比如类名、构造器参数、属性值、作用域、生命周期等，容器会根据 `BeanDefinition` 中封装的信息来创建 Bean。

### 使用 BeanFactoryPostProcessor 对配置元数据进行个性化配置

在 Spring 中，`BeanFactory` 提供了一种管理任何类型对象的高级机制，我们经常遇到的 `ApplicationContext` 则是它的一个子接口。若要用一句话来描述二者的差异，那就是：`BeanFactory` 提供配置框架和基本功能，`ApplicationContext` 则是添加了更多的企业级功能。

`BeanFactoryPostProcessor` 允许我们对配置元数据（`BeanDefinition`）进行个性化配置。它与后面介绍的 `BeanPostProcessor` 功能类似，只不过后者的作用是对 Bean 本身进行个性化配置。接口定义如下：
```Java
public interface BeanFactoryPostProcessor {
	/**
	 * Modify the application context's internal bean factory after its standard
	 * initialization. All bean definitions will have been loaded, but no beans
	 * will have been instantiated yet. This allows for overriding or adding
	 * properties even to eager-initializing beans.
	 */
	void postProcessBeanFactory(ConfigurableListableBeanFactory beanFactory) throws BeansException;
}
```

在 `postProcessBeanFactory()` 方法被调用前，所有的 Bean 定义信息都已经加载完毕。所以 `BeanFactoryPostProcessor` 可以在 Bean 实例化之前获取 Bean 的配置元数据，并对其进行修改。
## 依赖注入

依赖注入主要有两种：

* **基于构造器的依赖注入（Constructor-based DI）**：容器调用有参构造函数（或静态工厂方法），传入参数列表，每一个参数代表一个依赖。
* **基于 Setter 的依赖注入（Setter-based DI）**：容器在调用无参构造函数或无参静态工厂方法之后，再调用 Bean 的 setter 方法注入依赖。

IoC 容器甚至支持两种注入方式的混用的情况，你可以先通过构造函数给 Bean 注入一部分依赖，再通过 setter 方法给 Bean 注入另一部分依赖。一般情况下，推荐使用构造器注入强制性依赖，使用 setter 方法注入可选的依赖。

Bean 的依赖项解析过程如下：

* 容器被创建出来，通过描述 Bean 的配置元数据进行初始化，检验每个 Bean 的配置信息。配置元数据可以是 XML，也可以是注解和 Java 代码
* 对于每一个 Bean，它依赖会被表示成属性、构造器参数或静态工厂方法的参数。这些依赖将会在 Bean 被真正创建的时提供给它
* 每个属性或构造器参数都是一个具体的值，或者指向容器内另一个 Bean 的引用
* 对于那些是具体值的属性或构造器参数，相应的值会被转化成属性或构造器参数的实际类型

### 自动装配

Spring 提供了四种自动装配模式：

| Mode        | Description                                                  |
| ----------- | ------------------------------------------------------------ |
| no          | 不使用自动装配，通过 `ref` 定义 Bean 的依赖。这是默认值      |
| byName      | 通过属性名装配。Spring 会查找与属性同名的 Bean 进行装配      |
| byType      | 当满足给定类型的 Bean 只有一个时，进行自动装配，有多个时抛出异常。若没有满足类型的 Bean，不进行装配。 |
| constructor | 与 byType 类似，只是 Bean 用作构造器参数                     |

## Bean

在 Spring 中，Bean 就是那些由 IoC 容器初始化、配置和组装的对象，IoC 容器就是 Bean 的管理者。我们在前面提到，开发者通过配置元数据告诉 IoC 容器 Bean 的相关配置信息，容器将配置元数据解析成 `BeanDefinition` 对象，再通过它创建 Bean。

### Bean 的命名

通常情况下，一个 Bean 只有一个标识符（identifier）。但是，如果 Bean 需要多个标识符，也是可以的，这些多的标识符就是 Bean 的别名（alias）。但是，**在同一个 IoC 容器中，是不允许有多个相同的标识符的**。

那么，如何指定 Bean 的标识符呢？在基于 XML 的配置里，Bean 的标识符由 `id` 和 `name` 属性指定。其中 `id` 只允许我们声明一个标识符，而 `name` 允许我们声明多个，多个标识符之间使用逗号（`,`）或分号（`;`）或空格分隔就行了。例如：`<bean id="xx" name="xx1,xx2"/>`有时候，在 `name` 中声明所有的别名可能并不合适，这时可以使用 `<alias/>` 标签来单独明别名。例如：`<alias name="fromName" alias="toName"/>`。如果我们没有在 `<bean/>` 中定义 `id` 或 `name` 的值也是可以的，这是容器或自动帮我们生成一个 Bean 的标识符。

当我们使用像 `@Bean` 这种基于 Java 的配置创建 Bean 时，Bean 的标识符默认为方法的名字，例如下面代码中创建的 Bean 的标识符就是  `transferService`：

```Java
@Configuration
public class AppConfig {
  @Bean
  public TransferServiceImpl transferService() {
  return new TransferServiceImpl();
  }
}
```
### depends-on

有时候，我们可能是希望某个 Bean 在另一个或多个 Bean 之前初始化，这时我们可以使用 `depends-on`。例如：`<bean id="beanOne" depends-on="beanTwo,beanThree"/>` 告知容器在初始化 `beanOne` 之前先初始化 `beanTwo` 和 `beanThree`。

### 延迟初始化 Bean

`ApplicationContext` 默认会在启动的时候初始化所有的单例 Bean。虽然这种饿汉式的初始化方式能够尽早将问题暴露出来，但是有时候我们希望 Bean 在第一次被使用时才创建，即延迟初始化。为了实现这个目标，我们可以使用 `lazy-init` 属性。例如，`<bean id="beanOne" lazy-init="true"/>` 告诉容器不要在启动时创建 `beanOne`，而是在 `beanOne` 第一次被请求时才创建它。

### Bean 的作用域

我们前面有说，IoC 容器会使用 `BeanDefinition` 中封装的描述信息来创建 Bean。Bean 的[作用域（Scope）](https://docs.spring.io/spring-framework/docs/current/reference/html/core.html#beans-factory-scopes)描述的是：在不同场景下， `BeanDefinition` 和通过它创建出来的 Bean 的数量关系。在Spring 中，Bean 的作用域是相对于 IoC 容器来说的。Spring 默认支持了六种作用域：

| Scope       | Description                                                  |
| ----------- | ------------------------------------------------------------ |
| singleton   | 通过单个 `BeanDefinition` 创建的 Bean 在容器内只有一个实例。这也是默认的作用域 |
| prototype   | 通过单个 `BeanDefinition` 可以创建出任意数量的 Bean 实例     |
| request     | 在每个 HTTP 请求的生命周期内，通过单个 `BeanDefinition` 创建的实例只有一个 |
| session     | 在每个 HTTP 会话的生命周期内，通过单个 `BeanDefinition` 创建的实例只有一个 |
| application | 在每个 `ServletContext`  的生命周期内，通过单个 `BeanDefinition` 创建的实例只有一个 |
| websocket   | 在每个 `WebSocket`  的生命周期内，通过单个 `BeanDefinition` 创建的实例只有一个 |

此外，Spring 还支持开发者创建自定义的 Bean 作用域，具体做法可以参考 [Custom Scopes](https://docs.spring.io/spring-framework/docs/current/reference/html/core.html#beans-factory-scopes-custom)。

### Bean 的生命周期

Bean 本质上是一个 Java 对象。我们先回顾下 [Java 对象的生命周期](/posts/java/jvm/java_object_lifecycle/)，JVM 中的对象一生大概会经历以下几个阶段：

![Java object lifecycle](/images/java/spring/java-object-lifecycle.png "Java 对象生命周期")

站在 JVM 的角度来看，Bean 的生命周期也就是这样。但是，由于 Bean 是 IoC 容器管理的，容器可能给它定义额外的生命周期，也就是添加新的阶段。所以我们需要从 IoC 容器的角度看 Bean 的生命周期。

IoC 容器中 Bean 的生命周期主要有 4 个大的阶段：

1. 实例化（Instantiation）
2. 初始化（Initialization）
3. 使用（In Use）
4. 销毁（Destruction）

这和 Java 对象的生命周期有点不一样。但如果我们将 Bean 的生命周期看成创建、使用和销毁这三个大的阶段是不是就好理解了一些呢。Bean 的使用就不用说了，销毁也只是在容器关闭前（详见 `ConfigurableApplicationContext#close`）调用一下，复杂的都在 Bean 的创建过程。所以下面我们重点来看 Bean 的创建过程。

#### Bean 的创建

先声明以下，这里说的 Bean 的创建并不只是说把 Bean 实例化出来就行了，而是指实例化和初始化两个步骤。普通非延迟初始化的 Bean 创建流程的入口其实在 `org.springframework.context.support.AbstractApplicationContext#refresh()` 方法中的 `finishBeanFactoryInitialization(beanFactory)`，感兴趣的同学可以打开源码一探究竟。一番探索之后，发现最终的 Bean 创建逻辑位于 `org.springframework.beans.factory.support.AbstractAutowireCapableBeanFactory#doCreateBean` 方法。`doCreateBean()` 的方法体还是不短，为了抓住主线，先贴出主干代码：
```Java
protected Object doCreateBean(String beanName, RootBeanDefinition mbd, @Nullable Object[] args)
			throws BeanCreationException {
		// Instantiate the bean.
		BeanWrapper instanceWrapper = null;
		if (mbd.isSingleton()) {
			instanceWrapper = this.factoryBeanInstanceCache.remove(beanName);
		}
		if (instanceWrapper == null) {
			instanceWrapper = createBeanInstance(beanName, mbd, args);
		}
		Object bean = instanceWrapper.getWrappedInstance();
		// ...

		// Allow post-processors to modify the merged bean definition.
		synchronized (mbd.postProcessingLock) {
			if (!mbd.postProcessed) {
				try {
					applyMergedBeanDefinitionPostProcessors(mbd, beanType, beanName);
				} catch (Throwable ex) {
					// ...
				}
				mbd.postProcessed = true;
			}
		}

		// Eagerly cache singletons to be able to resolve circular references
		// even when triggered by lifecycle interfaces like BeanFactoryAware.
		boolean earlySingletonExposure = (mbd.isSingleton() && this.allowCircularReferences &&
				isSingletonCurrentlyInCreation(beanName));
		if (earlySingletonExposure) {
			// ...
			addSingletonFactory(beanName, () -> getEarlyBeanReference(beanName, mbd, bean));
		}

		// Initialize the bean instance.
		Object exposedObject = bean;
		try {
			populateBean(beanName, mbd, instanceWrapper);
			exposedObject = initializeBean(beanName, exposedObject, mbd);
		} catch (Throwable ex) {
			// ...
		}

		// Register bean as disposable.
		try {
			registerDisposableBeanIfNecessary(beanName, bean, mbd);
		} catch (BeanDefinitionValidationException ex) {
			// ...
		}

		return exposedObject;
}
```

这代码就清爽多了。所以 Bean 的创建步骤主要是以下几步：

![创建 Bean](/images/java/spring/doCreateBean.png "Bean 的创建")

#### BeanPostProcessor

`BeanPostProcessor` 允许我们对 Bean 进行个性化定制处理。该接口有两个方法：
* `postProcessBeforeInitialization(Object bean, String beanName)`：在 Bean 初始化之前调用
* `postProcessAfterInitialization(Object bean, String beanName)`：在 Bean 初始化之后调用

`BeanPostProcessor` 有一系列的子接口，比如 `InstantiationAwareBeanPostProcessor` 、`DestructionAwareBeanPostProcessor`、`BeanFactoryPostProcessor`、`ApplicationContextAwareProcessor` 等。`BeanPostProcessor` 系列接口中的回调是容器级别的，对所有的 Bean 生效。不同子接口发挥作用的时间不同，后面会进行介绍。

#### 实例化 Bean

创建 Bean 的第一步是实例化，入口方法是 `AbstractAutowireCapableBeanFactory#createBeanInstance`。容器会根据配置元数据，采取合适的策略（工厂方法或构造器）[实例化 Bean](https://docs.spring.io/spring-framework/docs/current/reference/html/core.html#beans-factory-class)。

`InstantiationAwareBeanPostProcessor` 提供了三个非常重要的方法：
* `postProcessBeforeInstantiation(Class<?> beanClass, String beanName)`：在实例化 Bean 之前调用
* `postProcessAfterInstantiation(Object bean, String beanName)`：在实例化 Bean 之后、正式填充属性之前调用
* `postProcessProperties(PropertyValues pvs, Object bean, String beanName)`：在填充属性之前对属性值作处理

加入这三个方法之后的 Bean 创建过程如下：

![实例化 Bean](/images/java/spring/doCreateBean-instantiation-callback.png "实例化 Bean")

#### 初始化 Bean

初始化 Bean 的入口方法是 `AbstractAutowireCapableBeanFactory#initializeBean`，主干代码如下：
```Java
protected Object initializeBean(String beanName, Object bean, @Nullable RootBeanDefinition mbd) {
		invokeAwareMethods(beanName, bean);

		Object wrappedBean = bean;
		if (mbd == null || !mbd.isSynthetic()) {
			wrappedBean = applyBeanPostProcessorsBeforeInitialization(wrappedBean, beanName);
		}

		try {
			invokeInitMethods(beanName, wrappedBean, mbd);
		}
		catch (Throwable ex) {
			// ...
		}
		if (mbd == null || !mbd.isSynthetic()) {
			wrappedBean = applyBeanPostProcessorsAfterInitialization(wrappedBean, beanName);
		}

		return wrappedBean;
	}
```

从上到下的逻辑主要是：调用 `Aware` 类型的回调方法，`BeanPostProcessor` 初始化前置处理，调用初始化方法，调用 `BeanPostProcessor` 初始化后置处理。我们一个一个来看。

##### Bean 初始化 Aware

`Aware` 类型的接口众多，但是在 Bean 的初始化过程中只可能会调用 `BeanNameAware`、`BeanClassLoaderAware` 和 `BeanFactoryAware` 三个接口的回调方法。具体逻辑可以参考`AbstractAutowireCapableBeanFactory#initializeBean` 方法调用的 `invokeAwareMethods(beanName, bean)` 方法。方法不长，我直接贴出来：
```Java
private void invokeAwareMethods(String beanName, Object bean) {
		if (bean instanceof Aware) {
			if (bean instanceof BeanNameAware) {
				((BeanNameAware) bean).setBeanName(beanName);
			}
			if (bean instanceof BeanClassLoaderAware) {
				ClassLoader bcl = getBeanClassLoader();
				if (bcl != null) {
					((BeanClassLoaderAware) bean).setBeanClassLoader(bcl);
				}
			}
			if (bean instanceof BeanFactoryAware) {
				((BeanFactoryAware) bean).setBeanFactory(AbstractAutowireCapableBeanFactory.this);
			}
		}
	}
```

##### 正式初始化

`org.springframework.beans.factory.InitializingBean` 允许 Bean 在所有属性填充完毕之后执行初始化操作，接口定义如下：
```Java
public interface InitializingBean {

	/**
	 * Invoked by the containing BeanFactory after it has set all bean properties
	 * and satisfied BeanFactoryAware, ApplicationContextAware etc.
	 */
	void afterPropertiesSet() throws Exception;

}
```

`afterPropertiesSet()` 方法会在 Bean 的属性设置完毕、各种 `Aware` 调用完成之后执行。实际上，Spring 并不推荐我们使用这个接口来进行初始化操作，因为这会导致我们的代码与 Spring 框架强耦合。推荐的做法是使用自定义的 `init()` 方法或 [JSR-250](http://en.wikipedia.org/wiki/JSR_250) 定义的 `@PostConstruct` 注解。

`invokeInitMethods()` 方法会尝试先判断 Bean 是否实现 `InitializingBean` 接口。若是，则调用 Bean 的 `afterPropertiesSet()` 方法。然后，判断 Bean 是否有自定义的初始化方法。若有，则调用自定义的 `init()` 方法。你可能已经发现了，这里没有调用 `@PostConstruct` 注解的方法，因为它是在 `#BeanPostProcessor#postProcessBeforeInitialization` 中调用的，感兴趣的同学可以查看 `InitDestroyAnnotationBeanPostProcessor#postProcessBeforeInitialization` 的源码。`invokeInitMethods()` 的主干代码如下：
```Java
protected void invokeInitMethods(String beanName, Object bean, @Nullable RootBeanDefinition mbd)
			throws Throwable {
		boolean isInitializingBean = (bean instanceof InitializingBean);
		if (isInitializingBean && (mbd == null || !mbd.isExternallyManagedInitMethod("afterPropertiesSet"))) {
			// ...
      ((InitializingBean) bean).afterPropertiesSet();
      // ...
		}

		if (mbd != null && bean.getClass() != NullBean.class) {
			String initMethodName = mbd.getInitMethodName();
			if (StringUtils.hasLength(initMethodName) &&
					!(isInitializingBean && "afterPropertiesSet".equals(initMethodName)) &&
					!mbd.isExternallyManagedInitMethod(initMethodName)) {
				invokeCustomInitMethod(beanName, bean, mbd);
			}
		}
	}
```

到这里，Bean 的初始化过程基本就分析完了，我们来完善一下之前的图：

![Bean 的创建过程](/images/java/spring/doCreateBean-initialization-callback.png "Bean 的创建过程")


#### 销毁 Bean

跟 `InitializingBean` 类似，Spring 为我们提供了 `DisposableBean` 用于容器关闭前执行 Bean 的清理工作。Spring 并不推荐我们使用它，因为这会导致程序代码与 Spring 强耦合。推荐的做法是使用 JSR-250 定义的 `@PreDestroy` 注解或配置自定义的 `destroy()` 方法。如果同时使用了几种，那么方法的执行顺序是：
1. `@PreDestroy` 注解的方法
2. `DisposableBean` 的 `destory()` 方法
3. 配置的自定义 `destroy()` 方法

到这里，Bean 的生命周期基本就介绍完了。用一张图总结下：

![Bean 的生命周期](/images/java/spring/bean-lifecycle.png "Bean 的生命周期")

## 未完待续

时间有限，先写到这里。写东西从来都不是一次性过程，要常看，常思考，常更新。

## 参考资料

1. [Spring Framework Documentation](https://docs.spring.io/spring-framework/docs/current/reference/html/core.html#spring-core).
2. [一文读懂 Spring Bean 的生命周期](https://blog.csdn.net/riemann_/article/details/118500805).