Qiyuna designing
===

Despite the top language syntax design, the document only talk about the bottom implentmentation about the compiler.

The language consists by abstract structure which are only modules, classes, fields, methods and fomal proof related concept including set, type, lema, predic, provement.

Designing for blockcahin, there is **no GC**, since the running duration of each calling should be really quick so the calling shouldn't have too much workload.

Depending on the same reason, all object in the language are both reference type, allocated on heap, except primitives.
(Another reason is function of WASM implentmented by Binaryen can only returns primitive but structure.)

**No link**. All the code should be compiled into one file.
Any 3rd part library should be either compiled into one file or use system call, which will pause the current code and create a new execution environment to run the library.

## Compile time and Runtime

The language is based on `Crystal`.

The source file of the language is either a `Crystal` source file. And the running result of the source using `Crystal` interpreter is the compiled WASM result.

So the source file is either a compile script.

There is no executor-like compiler but library like, and the running of the script is the compile time.

However the script is written in `Crystal` lang, which means there is compeletly runtime environment of `Crystal` lang, and user could use any component and library in the `Crystal`, including algorithms, code optimizers, formal proof, emulations and tests, or even code downloader and user developed library manager.
That is, code generates code, source is either an IDE, and compile time is another runtime.

But for runtime, it's either on chain or in test. The resource and tools are all really limited. It should be all for performance.

## Class Object

Any thing is an Object, including `Class`!

A Class is just an object with `new` method which calls `allocate(Class)` primitive function and `initialize` private instance method.
So, there is **no keyword `new`**.

- All object are instance of its class.
- All class are instance of `Class` (class of class object is `Class` object), which is the root of all classes.
- At last the `Class`, is a ghost object only living in compile time, and whose class, is Crystal lang `Module`.

That is, compile time object spawns runtime object, and in fact, all runtime object are spawned from compile time object.

### Inheirtance

No inheritance at current stage, but the implementation is designed.

Only single inheritance is supported.

`Class Object` has a readonly field named `superclass` pointed to super class object.

Without link, all information about the code are collected, and are classes are sealed, which means, we know all the inheritance information. Even without `virtual` keyword indication, all virtual method are defined.

So a virtual function table could be build and `Class Object` stores the start index as an integer in a field named `vftable`.
And then, every object stores the class pointer in a field named `class`.

Sine the `Class` is a ghost, the `class` field of class in runtime is a `GHOST` constant, but Crystal object `Class` in compile time.

#### Superclass tree

all class is inherited from `Object`.

## Calling binding

Without inheritance, every calling is static and bound in compiling time.

However with inheritance, calling for virtual function are bound using `vftable`.


## Type Arithmetic

All of type arithmetic are classified into 2 kinds, verification and construction.

### Verification Arithmetic

For the purpose of formal proof, all kinds of strict type of arguments or return values should be precisely described or derivable, which constitute a set.
Which means, the arguments and return value of a function aren't a Type but a set of Type.

``` crystal
def foo(score : Integer, user : Student | Teacher) : Course?
end
```

`Student | Teacher` consists a set which represented as `{Student, Teacher}` in mathmetical.
And the symbol `Course?` equals to `Course | Nil`, which is a syntax sugar.

### Type

What's Type? If we say `Student` is a type then does `Student | Teacher` is a type?

The answer for the language is, yes.

The concept of Type is enlarged for the language and alternatively using mathematical theory, **Type is defined as a set which variables or arguments belong to**.

As a set, Type has set arithmetic :

```
type Woman = Person.sub {|x| x.gender == :woman }
# or
type Woman = Person.sub &.gender == :woman
type WomanWithAge = cartesian Woman, age: Number
type Composite = Number.sub {|x| ∃ y: Number < x { y | x } }
type WomanOrNumber = Woman | Number
set  WomanSet = Set.new x: Person { x.gender == :woman }
set  CompositeSet = Set.new x: Number { ∃ y: Number < x { y | x } } 
# => Set.all x { x ∈ Number & ∃ y: Number < x { y | x } }
set  CompositeSet = Composite.as_set
# Type is aka Set but Set may isn't aka Type.
# Type is the Set known the base module entities.
set union_of_A = Set.new x { ∃ B: A { x ∈ B } }
# Here 

type Prime = Number - Composite
# => Prime = Type.new Number - Composite
lema CompositeLema = ∀ x: Composite { ∃ y: Number < x { y | x } }
lema CompositeLema { ∀ x: Composite { ∃ y: Number < x { y | x } } }
# Or anonymous lema:
lema Prime.∩ Composite == ∅
# which used for step by step formal proof.
# Predict function
predict IsPrime(x: Number) { x.∈ Prime }
# x#∈ alias with x#is_a?


```

Type 类型的运算：
- #sub { HOL expression including ∃ ∀ λ } 
- #| type union

Set :
- #sub
- #∪, ∩, /, -, <, >, ⊆, ⊂, ⊃, ⊇
- .∀: Set

HOL:
- .∀
- .∃

```
# FOL
logic ∀ x: Integer, ∃y ∈ Integer, y | x
type Prime = { x ∈ Integer | \nexists  }
∀ x: Integer, ∃ y: Integer { y | x }
```




All object has a pointer field to indicate the class object, which named `class`. But the virtual function table of the class object could be empty.
User could explicitly indicate a class as virtual by keyword.
Any class support update 


## Class System

Has inheritance, and virtual functions.
Virtual information are collect.

但是函数的签名，即HOL签名，必须上下兼容。

keyword : super, previous_def

类型信息仅在编译时维护，include 在编译时发生，即将所有 Members 加入各自的列表，previous_def 只是逆向查找列表中上一个同名的。
include 不能在运行时发生。

def 只是将函数信息添加到类型信息，但不进行编译。

最后统一编译。(可以编译过期)

继承重载HOL只能变窄，
def 重写可以变宽也可以变窄

## 编译流程：

1. 先建立类型信息 / 结构
2. 发射 Isebella HOL 进行验证
3. 编译，编译时与 HOL 无关


## Generic:

Generic = TypeFunction, a function generating type.
Meta programming.

```
set AnyType = Set.all x: Type
generic Array(x: Set{Int, String}, y: AnyType) {
    # ...
}
# =>
def generator_array(x, y): StructType
```

本质上 Type 是 二阶逻辑
Set 是 高阶逻辑
generic 是高阶逻辑函数

## Macro

the same with Crystal.

