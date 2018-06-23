# The code is Crystal Version dependented.
require "compiler/crystal/syntax/parser"
require "compiler/crystal/semantic"
require "./parse/*"

module WasmC
    alias ASTNode = Crystal::ASTNode
    class Program
        def initialize(@ast)
        end
        @ast : Crystal::ASTNode
        def ast
            @ast ||= parse
        end
        def parse(filename = nil)
            parser = Crystal:;Parser.new @code
            parser.filename = filename
            parse parser.parse
        end
        def parse(ast : ASTNode)
            ast.transform Crystal::NormalizerForWasmC.new 
        end
    end
end

