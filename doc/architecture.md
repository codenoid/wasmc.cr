# Qiyuna Compiler Architecture

## Modules

- module Meta: Program Meta Informations, that's Language Concepts.
    - class Program
    - abstract class Type < FormalSet
    - class StructType < Type
    - class UnionType < Type
    - class SubType < Type
    - class Contract < StructType
    - class Generic
    - And formal proof related:
    - module FormalProof
        - module Element
        - class Node
    - abstract class FormalSet
        include FormalProof::Element
    - class ArithmeticSet < FormalSet
    - class Lema
        include FormalProof::Element
        - class Prove
            include FormalProof::Element
    - class Predict
        include FormalProof::Element

## Keyword -> Representation Map

- set: LiteralSet
- type: Type

## Details

File meta.cr:

- module Meta

- class Program
    - f contracts, structs(including contracts?)
- class StructType
    - f fields: Hash(name: Identity, FieldMeta)
- struct Identity
    - m to_s: String
    - m equal: reference of name
- class FieldMeta
    - f name: Identity
    - f type: Type
- class Type
    - m size_value
    - m size_class
- class MethodMeta
    - f name: Identity
    - f args: Array(ArgMeta)
    - c ArgMeta
        - f name: Identity
        - f type: Type
        - f default: ASTNode?
    - f ret: Type

File formal_proof/type.cr:

- module FormalProof
    - class Node
        - f translate(io: IO)
    - module Element
        - f compile(): Node
- class ArithmeticSet
    - m ∪, ∩, /, -, ∋, ⊆, ⊂, ⊃, ⊇
- class LiteralSet < ArithmeticSet
    - m << # so that : Set{1, 2, 3}
- abstract class Type
    - m abstract origin_type: Array(StructType)
    - m sub(&block): SubType
    - m |, union(t: Type): UnionType
- class UnionType
    - f types: Array(Type)
    - m origin_type: Array(StructType)
        # implementation: types.map &origin_type
    - m override union(t: Type): UnionType
- class SubType
    - f base_type: Type
    - m origin_type: Array(StructType)
        # implementation: base_type.origin_type
- class StructType
    - m origin_type: Array(StructType)

File formal_proof.cr

- module FormalProof
- c Lema < SugarImplementer
    - m sugar()
    

File type.cr:

- c Generic:
    - m generate(arg: GenericArgument)
    - f generator_block
    使用 method_missing tech，套在跟 struct 元函数一样的壳子里
- c GenericArgument:
    - f args: Hash(Identity, Object) # could be anything
    - m [] # warpper to args

File builder.cr:

- alias Block = Proc(Nil)
- c StructType
    - f default_init: Hash(Identity, ASTNode)
    - mc build(name: String, &block): StructType
    - c Builder
        - m field(**fields: Hash(String, Type))
        - macro func(node: ASTNode)
            func aaa(x: BB) { CC } ->
            def_func(:aaa, " CC ", x: BB)
        - m def_func(name: String | Symbol, code: String 
            **args: Hash(String, Type))
            call MethodMeta.build
        - macro init
            init aa: xxx, bb: ccc ->
            def_init(aa: Block.new { xxx }, bb: Block.new { ccc })
        - m def_init(**args = Hash(Symbol, String))
            add to default_init, parsed by compiler
- c MethodMeta
    - mc build(name: String, code: String, \*\*args: Hash(String, Type))
- m FormalProof
    - c Builder
        - f@ symbols: Set(Identity)
        - m ∀, ∃
        - m method_missing
- c Lema < FormalProof::Form
    - mc 

File formal_proof/ast.cr

- m FormalProof
    - c ASTNode
    - c abstract Form < ASTNode
        - pr name: Identity
        - pr syms: Hash(Identity, FormalSet)
        - pr body: ASTNode?
    - c Predict < Form
        - pr body: ASTNode
    - c Any < Form
    - c Exists < Form
    

File sugar.cr:

- module Sugar
    - macro lema
        lema AA = xx ->
            def_meta Lema.build 

File program.cr:

- c Program

## Language Concepts

- program
- type
- struct aka type
- 

