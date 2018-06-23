require "compiler/crystal/syntax/visitor"
require "binaryen"
require "./options"
require "io/memory"

module WasmC
    class Builder
        @modl : Binayen::Module
        @opt  : Options
        @string_map : Hash(String, UInt32)
        @heap_pointer : UInt32 = 0x0
        @text_base : UInt32
        @text : IO::Memory = IO::Memory.new
        @text_seg_ind : Int32

        def initialize(@modl : Binaryen::Module? = nil)
            @modl ||= Binayen::Module.new
            @text_base = 0x10
            @text_seg_ind = @modl.memory_setting.segments.size
            @modl.memory_setting.segments << Bytes.empty
        end

        def compile
            @modl.memory_setting.segments[@text_seg_ind] = @text.buffer
        end

        def text_loc(text : String)
            @string_map[text] ||= begin
                v = @text.pos
                @text.write text.bytes
                @text.write 0_u8
                v
            end
        end

        private def error_not_support(fea)
            raise "Currently not suport #{fea}"
        end


        def trans(op : Crystal::Nop)
            @modl.exp_nop
        end
        def trans(op : Crystal::Expressions)
            @modl.exp_block nil, op.expressions.map{|a| trans a}
        end
        def trans(op : Crystal::NilLiteral)
            @modl.exp_const @opt.null_ptr
        end
        def trans(op : Crystal::BoolLiteral)
            @modl.exp_const @opt.as_bits(op.value ? 1 : 0)
        end
        def trans(op : Crystal::NumberLiteral)
            @modl.exp_const case op.kind
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
                    op.value.to_i
                end
        end
        def trans(op : Crystal::CharLiteral)
            @modl.exp_const op.value.to_u32
        end
        def trans(op : Crystal::StringLiteral)
            @modl.exp_const text_loc op.value
        end
        def trans(op : Crystal::StringInterpolation)
            error_not_support 
        end
        def trans(op : Crystal::SymbolLiteral)
            @modl.exp_const text_loc op.value
        end
        def trans(op : Crystal::ArrayLiteral)

        end
    end
    class AstTranslatorVistor < Crystal::Visitor
        def translate_error
        end
        def visit(op : Crystal::Nop)
            
        end
    end
end

