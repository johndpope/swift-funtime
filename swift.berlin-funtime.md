# Swift funtime

## swift.berlin #7

### Boris Bügling - @NeoNacho

![20%, original, inline](images/contentful.png)

![](images/swift-slide.png)

---

## CocoaPods

![](images/cocoapods.jpg)

---

## Contentful

![](images/contentful-bg.png)

---

>> “Swift’s clean slate [...] is an opportunity to reimagine how software development works.”

![](images/taylor-swift.jpg)

---

# Agenda

- What is a Swift object?
- Objective-C runtime in the age of Swift
- Swift runtime

![](images/swift-bg.jpg)

---

# What is a Swift object?

![](images/swift-bg.jpg)

---

# It depends

![](images/swift-bg.jpg)

---

```swift
class MyObject : NSObject {
}
```

![](images/swift-bg.jpg)

---

- behaves like any old Objective-C object
- instance variables are *properties*
- fully interopable with ObjC

![](images/swift-bg.jpg)

---


```swift
class MyObject {
}
```

![](images/swift-bg.jpg)

---

- has *SwiftObject* as superclass
- instance variables are *ivars*
- ivars have no type encoding
- methods are **not** ObjC methods
- not interoperable with ObjC

![](images/swift-bg.jpg)

---

### Playground!

```
import ObjectiveC.runtime
```

but

```
Playground execution failed: Error in auto-import:
failed to get module 'runtime' from AST context
```

(rdar://problem/18482380)

![](images/swift-bg.jpg)

---

# 😢🐼

![](images/swift-bg.jpg)

---

### SwiftObject

Ivar: magic {SwiftObject_s="isa"^v"refCount"q}
Protocol: NSObject

### NSObject

Ivar: isa #
Protocol: NSObject

![](images/swift-bg.jpg)

---

```swift
class MySwiftClass {
    var foo = "bar";

    init() {
    }
}

import Foundation
import ObjectiveC.runtime

var ivar = class_getInstanceVariable(MySwiftClass().dynamicType, "foo")
var value : AnyObject = object_getIvar(MySwiftClass(), ivar)!
```

Segmentation fault: 11

![](images/swift-bg.jpg)

---

```objc
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

@interface MyClass : NSObject

@property (nonatomic, retain) NSString* foo;

@end

#pragma mark -

@implementation MyClass

-(instancetype)init {
    self = [super init];
    if (self) {
        self.foo = @"bar";
    }
    return self;
}

@end

#pragma mark -

int main(int argc, char *argv[])
{
    @autoreleasepool {
        MyClass* object = [MyClass new];
        Ivar ivar = class_getInstanceVariable(object.class, "_foo");
        id value = object_getIvar(object, ivar);
        NSLog(@"%@", value);
        return 0;
    }
}
```

![left](images/dinosuar-t-rex.jpg)

---

# value types should be *structs*

```swift
struct MyObject {
	var a : String
	var b : Array<Int>
}
```

![](images/swift-bg.jpg)

---

## In pure Swift, there's no introspection 😭

![](images/swift-bg.jpg)

---

## There is hope

```swift
/// How children of this value should be presented in the IDE.
enum MirrorDisposition {
    case Struct
    case Class
    case Enum
    case Tuple
    [...]
}

/// A protocol that provides a reflection interface to an underlying value.
protocol MirrorType {
	[...]

    /// Get the number of logical children this value has.
    var count: Int { get }
    subscript (i: Int) -> (String, MirrorType) { get }

    /// Get a string description of this value.
    var summary: String { get }

    [...]
}
```

![](images/swift-bg.jpg)

---

```swift
// From: https://gist.github.com/peebsjs/9288f79322ed3119ece4

infix operator --> {}
func --> (instance: Any, key: String) -> Any? {
    let mirror = reflect(instance)

    for index in 0 ..< mirror.count {
        let (childKey, childMirror) = mirror[index]
        if childKey == key {
            return childMirror.value
        }
    }

    return nil
}

//Example
struct MyPoint {
    let x: Float
    let y: Float
}

let point = MyPoint(x: 1, y: 2)
println(point --> "x")
println(point --> "y")
```

![](images/swift-bg.jpg)

---

```swift
#!/usr/bin/env xcrun swift
 
func info<T>(x: T) {
    println("\(x) is a \(_stdlib_getDemangledTypeName(x))")
}
 
 
let array = [0, 1, 2] // appending 'as AnyObject' here yields a compiler error
info(array)
 
import Foundation
 
let objc_array: AnyObject = [0, 1, 2] as AnyObject
info(objc_array)
 
// comparing different array types => compiler error as well
//let equal = objc_array == array
```

![](images/swift-bg.jpg)

---

# Objective-C runtime in the age of Swift

![](images/dinosuar-t-rex.jpg)

---

## Inherit from `NSObject` and it just works!

![](images/dinosuar-t-rex.jpg)

---

# Even swizzling 😱

![](images/dinosuar-t-rex.jpg)

---

```swift
import Foundation
import ObjectiveC.runtime

extension NSString {
    func swizzle_description() -> NSString {
        return "💥"
    }
}

var myString = "foobar" as NSString

println(myString.description)

var originalMethod = class_getInstanceMethod(NSString.self, "description")
var swizzledMethod = class_getInstanceMethod(NSString.self, "swizzle_description")

method_exchangeImplementations(originalMethod, swizzledMethod)

println(myString.description)
```

![](images/swift-bg.jpg)

---

![](images/wat.jpg)

---

![250%](images/swizzle.jpg)

---

# Or replacing methods

```
import Foundation
import ObjectiveC.runtime

let myString = "foobar" as NSString

println(myString.description)

let myBlock : @objc_block (AnyObject!) -> String = { (sself : AnyObject!) -> (String) in
    "✋"
}

let myIMP = imp_implementationWithBlock(unsafeBitCast(myBlock, AnyObject.self))
let method = class_getInstanceMethod(myString.dynamicType, "description")
method_setImplementation(method, myIMP)

println(myString.description)
```

![](images/swift-bg.jpg)

---

## *Let's take a step back*

![](images/fall-back.gif)

---

# Objects

```c
typedef struct objc_object {
	Class isa;
} *id;
```

![](images/dinosuar-t-rex.jpg)

---

# Classes

```c
struct objc_class {
	Class isa;

#if !__OBJC2__
    Class super_class                                        OBJC2_UNAVAILABLE;
    const char *name                                         OBJC2_UNAVAILABLE;
    long version                                             OBJC2_UNAVAILABLE;
    long info                                                OBJC2_UNAVAILABLE;
    long instance_size                                       OBJC2_UNAVAILABLE;
    struct objc_ivar_list *ivars                             OBJC2_UNAVAILABLE;
    struct objc_method_list **methodLists                    OBJC2_UNAVAILABLE;
    struct objc_cache *cache                                 OBJC2_UNAVAILABLE;
    struct objc_protocol_list *protocols                     OBJC2_UNAVAILABLE;
#endif
} OBJC2_UNAVAILABLE;
```

![](images/dinosuar-t-rex.jpg)

---

## Objects

- struct `magic`
- contains `refCount` and `isa`
- methods are in virtual table, like in C++

## Classes

- have mangled names, which contain the module name

![](images/swift-bg.jpg)

---

# Name mangling

another C++ concept

```
_TFV4test1eCfMS0_FT_S0_ ---> test.e.init (test.e.Type)() -> test.e
_TMLCCC4test1a1b1c ---> lazy cache variable for type metadata for test.a.b.c
_TMmCCC4test1a1b1c ---> metaclass for test.a.b.c
_TMnCC4test1a1b ---> nominal type descriptor for test.a.b

_TTWOV4test1e1fSs9EquatableFS2_oi2eeUS2___fMQPS2_FTS3_S3__Sb ---> protocol witness for Swift.
Equatable.== infix <A : Swift.Equatable>(Swift.Equatable.Self.Type)
(Swift.Equatable.Self, Swift.Equatable.Self) -> Swift.Bool in conformance test.e.f : Swift.Equatable

_TWoFC4test1aCfMS0_FT_S0_ ---> witness table offset for 
test.a.__allocating_init (test.a.Type)() -> test.a

_TWoFCCC4test1a1b1c1dfS2_FT1zS0_1xS1_1vFT1xSi_Si_OVS_1e1f ---> witness table offset 
for test.a.b.c.d (test.a.b.c)(z : test.a, x : test.a.b, v : 
(x : Swift.Int) -> Swift.Int) -> test.e.f
```

---

# How are emoji formed?

```
$ echo 'class 👍 {}'|xcrun swiftc -emit-library -o test -
$ nm -g test
...
0000000000000db0 T __TFC4testX4ypIhD
...
$ xcrun swift-demangle __TFC4testX4ypIhD
_TFC4testX4ypIhD ---> test.👍.__deallocating_deinit
```

*X4 ypIh* ~ *xn--yp8h*

---

# Methods

```c
struct objc_method {
    SEL method_name                                          OBJC2_UNAVAILABLE;
    char *method_types                                       OBJC2_UNAVAILABLE;
    IMP method_imp                                           OBJC2_UNAVAILABLE;
} OBJC2_UNAVAILABLE;
```

![](images/dinosuar-t-rex.jpg)

---

# Method Implementations

```c
typedef struct objc_selector     *SEL;

typedef id (*IMP)(id self, SEL _cmd ,...);
```

![](images/dinosuar-t-rex.jpg)

---

# Message forwarding

```c
+(BOOL)resolveInstanceMethod:(SEL)aSEL;

-(void)forwardInvocation:(NSInvocation*)anInvocation;

-(NSMethodSignature*)methodSignatureForSelector:(SEL)selector;

-(BOOL)respondsToSelector:(SEL)aSelector;
```

![](images/dinosuar-t-rex.jpg)

---

# From *UIViewController.h*

```c
- (void)attentionClassDumpUser:(id)arg1 
  yesItsUsAgain:(id)arg2 
  althoughSwizzlingAndOverridingPrivateMethodsIsFun:(id)arg3 
  itWasntMuchFunWhenYourAppStoppedWorking:(id)arg4 
  pleaseRefrainFromDoingSoInTheFutureOkayThanksBye:(id)arg5;
```

![](images/Apple-logo.png)

---

# Change classes at runtime

- method_setImplementation()

- class_addMethod()

- ...

![](images/dinosuar-t-rex.jpg)

---

### NSInvocation does not exist

![180%](images/WcCXCSZ.gif)

---

## But what can we do about pure Swift?

![](images/swift-bg.jpg)

---

# SWRoute

- PoC of function hooking in Swift
- Uses `rd_route`, a Mach specific injection library for C

![](images/swift-bg.jpg)

---

```c
#include <stdint.h>

#define kObjectFieldOffset sizeof(uintptr_t)

struct swift_func_object {
    uintptr_t *original_type_ptr;
#if defined(__x86_64__)
    uintptr_t *unknown0;
#else
    uintptr_t *unknown0, *unknown1;
#endif
    uintptr_t function_address;
    uintptr_t *self;
};

uintptr_t _rd_get_func_impl(void *func) {
    struct swift_func_object *obj = (struct swift_func_object *)*(uintptr_t *)(func + kObjectFieldOffset);

    return obj->function_address;
}
```

![](images/swift-bg.jpg)

---

# What is a function?

```swift
func add(a: Int, b: Int) -> Int {
    return a + b 
}

let f = add

f(1, 2)
// $R0: Int = 3

println(f)
// (Function)
```

![](images/swift-bg.jpg)

---

# Name mangling

```
$ xcrun swiftc func.swift 
$ nm -g func
0000000100000f10 T __TF4func3addFTSiSi_Si
[...]
$ xcrun swift-demangle __TF4func3addFTSiSi_Si
_TF4func3addFTSiSi_Si ---> func.add (Swift.Int, Swift.Int) -> Swift.Int
```

![](images/swift-bg.jpg)

---

# Memory layout

- 8 bytes => Pointer to `_TPA__TTRXFo_dSidSi_dSi_XFo_iTSiSi__iSi_`
- 8 bytes => Pointer to struct

```
_TPA__TTRXFo_dSidSi_dSi_XFo_iTSiSi__iSi_ ---> 
partial apply forwarder for reabstraction thunk helper 
[...]
```

![](images/swift-bg.jpg)

---

# Memory layout

- 16 bytes => Swift object
- 8 bytes => Pointer to `_TF6memory3addFTSiSi_Si`

__Function pointer__ 🎉

![](images/swift-bg.jpg)

---

```swift
struct f_trampoline {
    var trampoline_ptr: COpaquePointer
    var function_obj_ptr: UnsafeMutablePointer<function_obj>
}

struct function_obj {
    var some_ptr_0: COpaquePointer
    var some_ptr_1: COpaquePointer
    var function_ptr: COpaquePointer
}
```

![](images/swift-bg.jpg)

---

```swift
import Darwin

@asmname("floor") func my_floor(dbl: Double) -> Double
println(my_floor(6.7))

let handle = dlopen(nil, RTLD_NOW)
let pointer = COpaquePointer(dlsym(handle, "ceil"))

typealias FunctionType = (Double) -> Double
```

![](images/swift-bg.jpg)

---

```swift
struct f_trampoline { [...] }
struct function_obj { [...] }

let orig = unsafeBitCast(my_floor, f_trampoline.self)
let new = f_trampoline(prototype: orig, new_fp: pointer)
let my_ceil = unsafeBitCast(new, FunctionType.self)
println(my_ceil(6.7))
```

![](images/swift-bg.jpg)

---

```
$ xcrun swift -Onone hook.swift 
6.0
7.0
```

![](images/swift-bg.jpg)

---

```c
void executeFunction(void(*f)(void)) {
    f();
}
```

```swift
@asmname("executeFunction") func 
executeFunction(fp: CFunctionPointer<()->()>)
```

![](images/swift-bg.jpg)

---

```swift
func greeting() {
    println("Hello from Swift")
}

let t = unsafeBitCast(greeting, f_trampoline.self)
let fp = CFunctionPointer<()->()>
    (t.function_obj_ptr.memory.function_ptr)
executeFunction(fp)
```

```
Hello from Swift
Program ended with exit code: 0
```

![](images/swift-bg.jpg)

---

# Swift runtime

![40%](images/swift-logo.png)

---

- libswiftCore.dylib

implementations of `NSSwiftArray`, etc.

- libswiftRuntime.a

low-level primitives like `swift_release`

![](images/swift-bg.jpg)

---

# Hopper

![](images/Hopper_v3.png)

---

## Compatibility

- App Compatibility ✅
- Binary Compatibility ⛔️
- Source Compatibility ⛔️

![](images/swift-bg.jpg)

---

```
Foo.app boris$ find . -type f
./Frameworks/libswiftCore.dylib
./Frameworks/libswiftCoreGraphics.dylib
./Frameworks/libswiftCoreImage.dylib
./Frameworks/libswiftDarwin.dylib
./Frameworks/libswiftDispatch.dylib
./Frameworks/libswiftFoundation.dylib
./Frameworks/libswiftObjectiveC.dylib
./Frameworks/libswiftUIKit.dylib
./Info.plist
./PkgInfo
./Foo
```

![](images/swift-bg.jpg)

---

# Two final tidbits

![](images/swift-bg.jpg)

---

# Speed

- less dynamic dispatch
- omits `_cmd` - freeing one register
- usually no pointer aliasing

```
int *ptrA = malloc(100 * sizeof(*ptrA));
int *ptrB = ptrA;
```

![](images/swift-bg.jpg)

---

```
class BankAccount {
    var balance: Double = 0.0
    
    func deposit(amount: Double) {
        balance += amount
    }
}

let account = BankAccount()
account.deposit(100)

let depositor = BankAccount.deposit
depositor(account)(100)

BankAccount.deposit(account)(100)
```

![](images/swift-bg.jpg)

---

## Methods are curried functions 

![](images/azb6mBK_460sa_v1.gif)

---

# Thank you!

![](images/4ovUfVD.gif)

---

- https://www.mikeash.com/pyblog/
- http://airspeedvelocity.net/
- https://developer.apple.com/swift/blog/
- http://www.russbishop.net/swift-how-did-i-do-horrible-things

---

@NeoNacho

boris@contentful.com

http://buegling.com/talks

![](images/cocoapods.jpg)

