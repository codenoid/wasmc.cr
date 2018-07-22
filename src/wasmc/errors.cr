require "compiler/crystal/syntax/ast"
require "colorize"

module WasmC
    module Error
        extend self

        class CompileFail < Exception
            property node : ASTNode?
            def initialize(message = nil, @node = nil, cause = nil)
                super message, cause
            end
            def to_s(io : IO)
                Error.code_info io, :error, message, node
            end
        end
        class NotSupport < CompileFail
            getter feature : String
            def initialize(fea, *args)
                @feature = fea.to_s
                super *args
            end
            def message
                "Currently not support #{feature}"
            end
        end
        class SyntaxError < CompileFail
            def initialize(message : String, *args)
                message = "Syntax Error. #{message}"
                super message, *args
            end
        end

        INFO_COLORS = {info: :light_gray, error: :ref, warning: :yellow}
        def code_info(io : IO, type : Symbol = :info, info, node : ASTNode? = nil)
            io << "#{node.location.filename}:#{node.location.line_number}:#{
                    node.location.column_number} + s " if node
            io << "#{type}: ".colorize INFO_COLORS[type]
            io << info
        end
        def code_error(io : IO, reason, node : ASTNode? = nil)
            code_info io, :error, reason, node
        end
    end
end

