#!/usr/bin/xcrun swift

import Foundation
import ObjectiveC.runtime

func inspectClass(myClass : AnyObject.Type) -> Void {
    println("Name: " + NSStringFromClass(myClass))

    var ivarCount : UInt32 = 0
    var ivars : UnsafeMutablePointer<Ivar> = class_copyIvarList(myClass, &ivarCount)

    for i in 0..<ivarCount {
        print("Ivar: " + String.fromCString(ivar_getName(ivars[Int(i)]))!)
        println(" " + String.fromCString(ivar_getTypeEncoding(ivars[Int(i)]))!)
    }

    var propertyCount : UInt32 = 0
    var properties : UnsafeMutablePointer<objc_property_t> = class_copyPropertyList(myClass,
        &propertyCount)

    for i in 0..<propertyCount {
        println("Property: " + String.fromCString(property_getName(properties[Int(i)]))!)
    }

    /*var methodCount : UInt32 = 0
    var methods : UnsafeMutablePointer<Method> = class_copyMethodList(myClass, &methodCount)

    for i in 0..<methodCount {
        print("Method: ")
        println(method_getName(methods[Int(i)]))
    }*/

    var protocolCount : UInt32 = 0
    var protocols : AutoreleasingUnsafeMutablePointer<Protocol?> = class_copyProtocolList(myClass,
        &protocolCount)

    for i in 0..<protocolCount {
        println("Protocol: " + String.fromCString(protocol_getName(protocols[Int(i)]))!)
    }
}

func inspect(obj : AnyObject) -> Void {
    // TODO: Missing in Swift 1.2
    //println("Mangled name: \(_stdlib_getTypeName(obj))")

    var myClass: AnyObject.Type = obj.dynamicType
    inspectClass(myClass)

    var superClass: AnyObject.Type = class_getSuperclass(myClass)
    inspectClass(superClass)
}

println("# Swift based class")

class MyObject {
    var foo : String = "foo"

    func bar(str : String) -> Bool {
        return false
    }

    init() {
    }
}

inspect(MyObject())

println("\n# Objective-C based class")

class MyNSObject : NSObject {
    var foo : String = "foo"

    func bar(str : String) -> Bool {
        return false
    }

    override init() {
    }
}

inspect(MyNSObject())

/*var foo = ["foo", "bar"]
inspect(foo)

var bar = ["foo": "bar"]
inspect(bar)*/

