require "compiler/crystal/syntax/ast"
require "./parse/*"
require "./options"

module WasmC
    alias ASTNode = Crystal::ASTNode
    class Program
        def initialize(code_or_ast : String | ASTNode, 
                       @options : Options = Options.new)
            case code_or_ast
            when String
                @code = code_or_ast
                @ast = parse @code
            when ASTNode
                @ast = code_or_ast
            end
        end

        getter code : String? = nil
        getter ast  : ASTNode
        private def parse(filename = nil)
            parser = Crystal:;Parser.new @code
            parser.filename = filename
            parse parser.parse
        end
        private def compile(ast : ASTNode)
            @ast = ast.transform Crystal::NormalizerForWasmC.new self

        end


        @temp_var_counter = 0
        def new_temp_var_name
            "_wasmc_tmp_#{@temp_var_counter+=1}"
        end
        def new_temp_var : Crystal::Var
            Crystal::Var.new new_temp_var_name
        end
    end
end

