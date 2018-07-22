require "compiler/crystal/syntax/ast"
require "binaryen"
require "./options"
require "io/memory"

module WasmC
    class Options
        def int_type
            x64? ? Binaryen::Types::Int64 : Binaryen::Types::Int32
        end
        def int_return_info
            x64? ? Builder::ReturnInfo::I64 : Builder::ReturnInfo::I32
        end
    end
end

module Crystal
    abstract class ASTNode
        property ret_type : WasmC::Builder::ReturnInfo = 
            WasmC::Builder::ReturnInfo::Unknown
        property wasm_exp : Binaryen::Expression?
        def set_trans_result(r_type, w_exp)
            @ret_type, @wasm_exp = r_type, w_exp
            self
        end
    end
end

module WasmC
    class Builder
        include WasmC::Error

        @modl : Binayen::Module
        @opt  : Options
        @string_map : Hash(String, UInt32)
        @heap_pointer : String
        @text_seg : Binaryen::MemorySettingSegment
        @text_seg_loc : UInt32
        @text : IO::Memory = IO::Memory.new

        module TextLoc
            HeapPointer = 0
        end
        struct ReturnInfo
            enum Kind
                Unknown, None, Block
                Reference
            end
            getter kind : Kind
            getter klass : ClassInfo | Nil | ClassInfo::GenericTypeParameter = nil
            getter? constant : Bool
            def initialize(@kind, *, @constant? = false)
            end
            def initialize(@klass, *, @constant? = false)
                @kind = Kind::Reference
            end
            def as_constant
                @as_constant? = true
                self
            end
            def size : UInt64
                return @opt.int_size if kind.pointer > 0
                case kind
                when Kind::Unknown, Kind::None, Kind::Block then 0
                when Kind::Int, Kind::Reference then @opt.int_size
                when Kind::I32, Kind::U32, Kind::F32 then 4
                when Kind::I64, Kind::U64, Kind::F64 then 8
                else 0
                end
            end
            def klass! : ClassInfo
                return @klass.resolve! if @klass.is_a? ClassInfo::GenericTypeParameter
                @klass.not_nil!
            end

            def_equals_and_hash kind, pointer, klass, as_constant

            # least compatibale
            def merge(o : ReturnInfo?)
                return self if o.nil? || self == o


            end

            Int = ReturnInfo.new Kind::Int
            I32 = ReturnInfo.new Kind::I32
            I64 = ReturnInfo.new Kind::I64
            U32 = ReturnInfo.new Kind::U32
            U64 = ReturnInfo.new Kind::U64
            F32 = ReturnInfo.new Kind::F32
            F64 = ReturnInfo.new Kind::F64
            Unknown = ReturnInfo.new Kind::Unknown
            None = ReturnInfo.new Kind::None
            Block = ReturnInfo.new Kind::Block
            Nil = ReturnInfo.new ClassInfo::Nil
            Integers = [I32, I64, U32, U64]
            Numbers = Integers + [F32, F64]
            FromSymbol = {i32: I32, i64: I64, u32: U32, u64: U64}
        end

        def initialize(@modl : Binaryen::Module? = nil)
            @modl ||= Binayen::Module.new
            @text_seg_loc = 0x10
            @text_seg = Binaryen::MemorySettingSegment.new Bytes.empty,
                @modl.exp_const @opt.as_arch @text_seg_loc
            @text.write_bytes @opt.as_arch 0
            @modl.memory_setting.segments << @text_seg
            @heap_pointer = @modl.add_global "_WasmC_Heap_", @opt.int_type,
                true, gen_load_text(TextLoc::HeapPointer)
        end

        getter heap_pointer

        def compile
            @text_seg.data = @text.buffer
        end

        def text_loc(text : String)
            @string_map[text] ||= begin
                v = @text.pos
                @text.write text.bytes
                @text.write 0_u8
                v
            end
        end


        def gen_load_text(offset : UInt32, t : Class) 
            @modl.exp_load offset, t, @modl.exp_const(@text_seg_loc)
        end


        def trans(op : Nil)
            nil
        end
        def trans(op : Crystal::Nop)
            op.set_trans_result ReturnInfo::None, @modl.exp_nop
        end
        def trans(op : Crystal::Expressions)
            op.set_trans_result ReturnInfo::Block, 
                @modl.exp_block nil, op.expressions.map{|a| trans a}
        end
        def trans(op : Crystal::NilLiteral)
            op.set_trans_result ReturnInfo::Nil,
                @modl.exp_const @opt.null_ptr
        end
        def trans(op : Crystal::BoolLiteral)
            op.set_trans_result @opt.int_return_info,
                @modl.exp_const @opt.as_arch(op.value ? 1 : 0)
        end
        def trans(op : Crystal::NumberLiteral)
            op.set_trans_result ReturnInfo::FromSymbol.fetch(op.kind,
                @opt.int_builder_type, ReturnInfo::Int), 
                @modl.exp_const(case op.kind
                when :f32
                    op.value.to_f32
                when :f64
                    op.value.to_f64
                when :i64
                    op.value.to_i64
                when :u64
                    op.value.to_u64
                when :u32
                    op.value.to_u32
                else
                    @opt.as_arch op.value.to_i
                end)
        end
        def trans(op : Crystal::CharLiteral)
            op.set_trans_result ReturnInfo::U32, @modl.exp_const op.value.to_u32
        end
        def trans(op : Crystal::StringLiteral)
            op.set_trans_result ReturnInfo::U32.as_pointer.as_constant,
                @modl.exp_const text_loc op.value
        end
        def trans(op : Crystal::StringInterpolation)
            raise Error::NotSupport.new typeof op
        end
        def trans(op : Crystal::SymbolLiteral)
            op.set_trans_result ReturnInfo::U32.as_pointer.as_constant,
                @modl.exp_const text_loc op.value
        end
        def trans(op : Crystal::ArrayLiteral)
            if op.name.nil?
                type = trans(op.of).try &.ret_type
                eles = elements.map{|a| trans a }
                raise Error::SyntaxError.new
                    "empty array should use keyword to indicate type, like [] of Type", op if eles.empty? && type.nil?
                type = eles.first.ret_type
                raise Error::SyntaxError.new "array can only have one kind of element type" unless eles.all? &.r_type == type
            else
                raise Error::NotSupport.new "#{typeof op} with name", op
            end
        end
    end
    class AstTranslatorVistor < Crystal::Visitor
        def translate_error
        end
        def visit(op : Crystal::Nop)
            
        end
    end
end

