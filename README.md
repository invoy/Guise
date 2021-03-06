
<!-- [![Build Status](https://travis-ci.org/Prosumma/Guise.svg)](https://travis-ci.org/Prosumma/Guise) -->
[![CocoaPods compatible](https://img.shields.io/cocoapods/v/Guise.svg)](https://cocoapods.org)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Language](https://img.shields.io/badge/Swift-4.0-orange.svg)](http://swift.org)
![Platforms](https://img.shields.io/cocoapods/p/Guise.svg)

Guise is an elegant, flexible, type-safe dependency resolution framework for Swift.

- [x] Flexible dependency resolution, with optional caching
- [x] Elegant, straightforward registration
- [x] Thread-safe
- [x] Simplifies unit testing
- [x] Support for containers, named dependencies, and arbitrary types
- [x] Pass arbitrary state when resolving
- [x] Support for arbitrary metadata
- [x] Swift 4
- [x] Support for iOS 8.1+, macOS 10.9+, watchOS 2+, tvOS 9+

### What Makes Guise Better Than Those Other Guys?

- Guise doesn't require any modification to the types you register. There are no special interfaces like `Injectable` or `Component` to implement. There are no special initializers or properties to add. Any type can be registered as is.
- Guise was designed with Swift in mind. Other DI frameworks for Swift appear to be translations of frameworks from other languages, particularly C&#x266f; and Java. These languages have strengths and weaknesses that are different from those of Swift, and those strengths and weaknesses are reflected in the design of these frameworks. This makes them clumsy in Swift.
- Many of these frameworks register _types_ directly. Guise registers _blocks_ directly and _types_ indirectly. This simple distinction removes an enormous amount of complexity while introducing greater compile-time safety. When combined with Swift's `@autoclosure` attribute, it makes registration elegant and minimal. (See the sections on factory and instance registration below.)
- Guise was designed to be simple rather than easy. Turns out it's both.

### Prerequisites

Dependency resolution is a somewhat advanced topic. For the sake of brevity, this document assumes that you know what dependency resolution and injection are. It also assumes you have a strong knowledge of the Swift language, including generics, blocks, and the distinction between value and reference types.

### Usage Styles

Guise can be used in two different ways. The simplest way is to use the static methods of the `Guise` struct, and that is the approach taken here in this document.

The other way is to create an instance of the `Resolver` class and use its instance methods. For instance, one can say:

```swift
Guise.register{ Plink() }
```

Or one can say,

```swift
let resolver = Resolver()
resolver.register { Plink() }
```

Note: `Resolver` was originally called `DependencyResolver`. `DependencyResolver` is now a `typealias` for `Resolver`, is marked as deprecated, and will be removed in a future release.

### Registration Basics

Before a dependency can be resolved, it must first be registered. Guise does not register dependencies directly. Instead, it registers a block&mdash;called the _resolution block_&mdash;that returns the desired dependency.

```swift
Guise.register{ Plink() }
```

(The `register` overloads return an instance of `Key<T>`, which we are ignoring here. More on that later.)

The return type of the resolution block is called the _registered type_. When we ask Guise to resolve this dependency, we use the registered type to do so:

```swift
let plink = Guise.resolve(type: Plink.self)!
```

All of the `resolve` overloads return `T?`, where `T` is the registered type. If the registration is not found, `nil` is returned. In this case, we're very sure we have registered `Plink`, so we force-unwrap it.

### Abstraction

> **Guise**, _n._ An external form, appearance, or manner of presentation, typically concealing the true nature of something.

Registering concrete types defeats the purpose of dependency resolution. In general, we want the registered type to be an abstraction such as a protocol or base class so that we can vary the implementation based on factors such as whether the code is executing in `DEBUG` mode or in a unit test and so on. In other words, we want our implementations to appear _in the guise of_ some other type.

Consider the following:

```swift
protocol Plonk {
  func plonk()
}

class Plink: Plonk {
  func plonk() {
    print("plonk")
  }
}

class DebugPlink: Plonk {
  func plonk() {
    print("DEBUG: plonk")
  }
}

#if DEBUG
  Guise.register{ DebugPlink() as Plonk }
#else
  Guise.register{ Plink() as Plonk }
#endif
```

Remember: The return type of the resolution block is the registered type. In this case, the registered type is not `DebugPlink` or `Plink`, it's `Plonk`:

```swift
let plonk: Plonk = Guise.resolve()!
```

Depending upon whether the `DEBUG` flag is set, the `Plonk` we get will either be a `DebugPlink` or a `Plink`.

### Caching

In many cases, we don't want the resolution block to be called over and over again. Once it's been evaluated, we want Guise to cache the result and just return it every time, effectively creating a singleton. This is achieved as follows:

```swift
Guise.register(cached: true) { Plink() as Plonk }
```

Guise will evaluate the resolution block the first time, but after that it will return the cached value. The semantics of returning the cached value vary depending upon whether the cached value is a value type or a reference type. This is a feature of the Swift language and has nothing directly to do with Guise. If the cached value is a reference type, you will get a reference to it. If it's a value type, you'll get a copy, but its initializer will not be called again.

When resolving, it is possible to override the registered caching behavior by passing an explicit value for the `cached` parameter, e.g.,

```swift
let plonk = Guise.resolve(cached: false)! as Plonk
```

By passing `cached: false`, we are telling Guise to call the resolution block again and return its value. (Any previously cached value will _not_ be overwritten.)

Similarly…

```swift
let plonk = Guise.resolve(cached: true)! as Plonk
```

By passing `cached: true`, we are telling Guise to use any previously cached value. If there is no cached value, Guise will call the resolution block and cache it, using it whenever `cached: true` is called again.

If no value for `cached` is specified when resolving, the registered behavior is used:

```swift
Guise.register(cached: true) { Plink() as Plonk }
let plonk = Guise.resolve()! as Plonk // Returns cached value
```

The default behavior when registering is _not_ to cache.

### Factory Registration

One of the most common cases in dependency resolution is to register a factory from which many distinct instances of the same type will be created. Guise has a clever overload of `register` to handle this.

```swift
Guise.register(factory: Plink() as Plonk)
```

Before explaining this, it will be helpful to give the type of the `factory` parameter: `@escaping @autoclosure () -> T`. This means that `Plink() as Plonk` is not evaluated at the call site, but is actually a block that is saved for later execution. The code above is exactly equivalent to…

```swift
Guise.register(cached: false) { Plink() as Plonk }
```

(`cached: false` is the default. We could have omitted it, but stating it this way makes it clearer.)

### Instance Registration

Instance registration is analogous to factory registration, except that the result of the resolution block is always cached.

```swift
Guise.register(instance: Plink() as Plonk)
```

Again, this is exactly equivalent to…

```swift
Guise.register(cached: true) { Plink() as Plonk }
```

The `instance` parameter's type signature is exactly the same as that of `factory` above: `@escaping @autoclosure () -> T`. This means that even instances are not evaluated eagerly. However, they are always cached after they are evaluated.

If you want eager evaluation for instance registration, you should instantiate your instance first, then pass it to Guise:

```swift
let s = "registered string"
Guise.register(instance: s)
```

### Named Registrations

A registration that registers the same type as a previous registration silently overwrites that registration, e.g.,

```swift
Guise.register(instance: DebugPlink() as Plonk)
Guise.register(instance: Plink() as Plonk)
```

The registration of `DebugPlink` as a `Plonk` is obliterated by the line that comes after it. So how can multiple `Plonk` registrations be made? By naming them:

```swift
Guise.register(instance: DebugPlink() as Plonk, name: "debug")
Guise.register(instance: Plink() as Plonk)
```

The first registration is given the name "debug", while the second one is not explicitly given a name. (It turns out it does indeed have a name, but more on that in a moment.) Because each registration has a different name, they are different registrations.

When resolving, the appropriate name must be passed:

```swift
let debugPlonk: Plonk = Guise.resolve(name: "debug")!
```

Strings, however, are not the best names. It turns out that any `Hashable` type can be used as a name. Simple enumerations in Swift are `Hashable` by default and I strongly recommend their use for names in Guise. In fact, the default name for a registration is `Guise.Name.default`.

It is the combination of registered type and name that disambiguates a registration. If disparate types are registered with the same name, they are separate registrations, e.g.,

```swift
Guise.register(factory: Foo(), name: Name.foo)
Guise.register(factory: Bar(), name: Name.foo)
```

Both of these registrations are made with the name `Name.foo`, but because they register different types, they are different registrations.

### Containers

In addition to names, registrations can be made in containers. A container is a group of related registrations. How they are related is up to you, but a common use case might be a set of plugins. The advantage of a container is that it can be easy to unregister all of the registrations in a container at once. (More on that later.)

```swift
Guise.register(factory: Plink(), container: Container.plinks)
```

A container is just another name and any `Hashable` type can be used here. Enumerations are strongly recommended. The default container, which never needs to be specified, is `Guise.Container.default`.

Registrations made in a container are distinct from registrations made in another container. Registrations _within_ a container can be disambiguated using a name, e.g.,

```swift
Guise.register(factory: Plink(), name: Name.plink, container: Container.plinks)
Guise.register(instance: Plink(), container: Container.plinks)
```

The two registrations above are disambiguated by name, though they register the same type in the same container. The name of the first registration is `Name.plink` and the second is `Guise.Name.default`.

### Keys

The return type of the `register` overloads is `Key<T>`, where `T` is the registered type. A key uniquely identifies a registration. Any two registrations that would produced the same key are the same registration. A subsequent registration producing the same key as a previous registration overwrites the previous registration, as discussed above in the section on names. A key consists of three facts about a registration: its registered type, name, and container. Other details, such as metadata (see below) and caching do not distinguish registrations.

There are two types of keys: the type-safe `Key<T>` and the type-erased `AnyKey`. In the case of `AnyKey`, the registered type is still "remembered", but it is remembered as a string and not as a generic type parameter.

Direct use of keys is uncommon. There are `register` and `resolve` overloads that take keys. In fact, the other overloads construct a key and then call these "master" overloads. The primary use of keys is with filtering and unregistering, both of which will be discussed below.

### Parameters

Most of the time, you should perform registration with the `factory:` and `instance:` overloads of the `register` method, rather than registering a resolution block directly. However, one case in which you cannot do this is when a parameter must be passed when resolving. The resolution block can take an optional parameter (but only one):

```swift
struct Wibble {
  let thibb: String
  init(thibb: String) {
    self.thibb = thibb
  }
}

Guise.register{ Wibble(thibb: $0) }
```

Swift figures out the type of `$0` through type inference. Resolution is straightforward:

```swift
let wibble: Wibble = Guise.resolve(parameter: "flerb")!
```

If more than one parameter is needed, pass a tuple or other structured type.

### Dependency Injection

Very often dependencies have other dependencies. Explicitly using Guise within a type is not recommended. For instance, don't do this:

```swift
struct Slib {
  init() {

  }
}

Guise.register(factory: Slib())

struct Throckmorton {
  let slib: Slib
  init() {
    // This is unwise.
    slib = Guise.resolve()!
  }
}

Guise.register(factory: Throckmorton())
```

Instead, do this:

```swift
struct Throckmorton {
  let slib: Slib
  init(slib: Slib) {
    self.slib = slib
  }
}

Guise.register(factory: Throckmorton(slib: Guise.resolve()!))
```

Of course, there are situations in which this is not possible. In Cocoa and Cocoa Touch, one usually does not have control over the creation of controllers. The framework does this for you. So the direct use of Guise in controllers is unavoidable.

### Metadata

Arbitrary metadata may be attached to a registration, e.g.,

```swift
let metadata = (wubble: 18, fuzzle: "threlf")
Guise.register(factory: Slib(), metadata: metadata)
```

Metadata is chiefly useful for anonymous registrations, discussed below.

### Filtering

Filtering searches for registrations and returns their keys, which can then be used for resolving, looking up metadata, unregistering, and so on.

Searches can be typed or untyped. In the former case, `Set<Key<T>>` is returned. In the latter, `Set<AnyKey>`.

A typed search looks like this:

```swift
let keys = Guise.filter(type: Slib.self, container: Container.öystër)
```

This query finds all registrations of type `Slib` in the container `Container.öystër`. These registrations can have _any_ name.

An untyped search simply omits the `type` parameter:

```swift
let keys = Guise.filter(container: Container.öystër)
```

Because the registered types in `Container.öystër` may be heterogeneous, `Set<AnyKey>` is returned.

In addition to filtering by registered type, name, and container, Guise also supports metadata filters.

```swift
typealias SlibMetadata = (wubble: Int, fuzzle: String)
let keys = Guise.filter(type: Slib.self) { (metadata: SlibMetadata) in
  metadata.wubble < 20
}
```

In order for the metadata filter to be satisfied, the registered metadata must be of type `SlibMetadata` _and_ the filter itself must return true.

If the underlying metadata is `Equatable` and we are concerned only with an equality comparison, there is a shortcut:

```swift
let keys = Guise.filter(type: Throckmorton.self, metadata: 8)
```

This gets all keys registering `Throckmorton` whose registered metadata is `8`.

### Unregistering

To remove registrations from Guise, use one of the overloads of `unregister`. In the simplest case, just pass a key, which you can easily construct yourself.

```swift
let key = Key<Slib>(name: Name.wob)
let unregistered = Guise.unregister(keys: [key])
```

The `unregister` method returns the number of items unregistered. The type of the `keys` argument is actually `Set<K>`, where `K` is any type conforming to the `Keyed` protocol, i.e., `Key<T>` and `AnyKey`.

Because the `filter` methods return a `Set` of keys, we can combine `unregister` and `filter` together:

```swift
Guise.unregister(keys: Guise.filter(name: "disposable", container: Container.garbage))
```

The above unregisters all registrations with the name "disposable" in `Container.garbage`, irrespective of type.

In fact, this usage is so common that `unregister` actually has overloads that mimic those of `filter`. So for the above it would be more natural to say…

```swift
Guise.unregister(name: "disposable", container: Container.garbage)
```

Be careful when filtering and unregistering. It's important to understand what code such as that below does:

```swift
Guise.unregister(type: Wiffle.self)
```

This unregisters _all_ registrations of type `Wiffle`, with any name, and across all containers. It does not simply unregister those that were originally registered without an explicit name or container. To do that, you must provide those values:

```swift
Guise.unregister(type: Wiffle.self, name: Guise.Name.default, container: Guise.Container.default)
```

This unregisters all registrations of type `Wiffle` having the default name in the default container.

To remove _all_ registrations from Guise, use `clear`, which takes no parameters.

### Anonymous Registrations

Sometimes we wish to register some types _en masse_ and we do not care to distinguish them, e.g.,

```swift
Guise.register(factory: Impl1() as Plugin, name: UUID())
Guise.register(factory: Impl2() as Plugin, name: UUID())
Guise.register(factory: Impl3() as Plugin, name: UUID())
// and so on
```

By using a `UUID` as the name, we are guaranteed to get a unique, random name for each registration. If we want to resolve them all at once, we can use filtering:

```swift
let keys = Guise.filter(type: Plugin.self, container: Guise.Container.default)
let plugins: [Plugin] = Guise.resolve(keys: keys)
```

Perhaps the plugins are similar enough that they all implement the `Plugin` protocol, but still have subtly different capabilities. There are many techniques available here, depending upon our needs. We could put each `Plugin` subtype into a separate container, for instance.

Another approach is to use metadata. The metadata can be queried in a filter so that we only get and resolve exactly those registrations that we need:

```swift
Guise.register(factory: Impl1() as Plugin, name: UUID(), metadata: PluginMetadata.viewer)
Guise.register(factory: Impl2() as Plugin, name: UUID(), metadata: PluginMetadata.viewer)
Guise.register(factory: Impl3() as Plugin, name: UUID(), metadata: PluginMetadata.editor)

let keys = Guise.filter(type: Plugin.self, container: Guise.Container.default, metadata: PluginMetadata.editor)
let editors: [Plugin] = Guise.resolve(keys: keys)
```

### Weak Registration

Because Guise is global, it can keep references alive past their useful life and cause memory leaks. This is especially true with controllers. For instance,

```swift
func viewDidLoad() {
  super.viewDidLoad()
  Guise.register(instance: self)
}
```

This holds on to a reference to this controller and prevents it from being released until it is unregistered or a subsequent registration overwrites this one. If you really understand the implications of this, it can be acceptable.

However, another technique, _weak registration_, can be used to avoid holding a reference to the controller:

```swift
class StrongViewController: UIViewController {
  func viewDidLoad() {
    super.viewDidLoad()
    // Don't cache the result
    Guise.register{ [weak self] in self }
  }
}
```

By capturing a weak reference to `self`, Guise will not hold a reference to the controller, allowing it to be released normally. The trade-off is that the registered type is an optional. In this case, it is not `StrongViewController` but `StrongViewController?`:

```swift
guard let strongViewController = Guise.resolve(type: StrongViewController?.self)! else { return }
```

When the registered type is an optional, the return type is a _double optional_, in this case `Optional<StrongViewController>?`. The outer optional returns `nil` if the registration does not exist. The inner optional returns `nil` if Swift has assigned `nil` to the weak reference. This is why we still have an optional even after force-unwrapping the result of `resolve`, so the `guard` statement works correctly.

Confused? Avoid this technique unless you really need it.

### Concurrency

Guise uses a private concurrent queue for key lookup and registration. This queue allows multiple readers for resolution but only one writer for registration. _No other operations (such as resolution) are performed on this queue._ 

Guise uses a serial queue per registration when generating cached values to avoid a race condition that could occur when an attempt is made to cache the same registration on two or more threads. In this case, the resolution block will be called synchronously inside of this queue. This is the only time a resolution block is invoked inside of a queue created by Guise.

Beyond this, thread safety is up to you.
