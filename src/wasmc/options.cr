
module WasmC
    class Options
        getter bits : Int8
        def initialize(* @bits = 32)
            raise "bits can only be 32 or 64" unless @bits == 32 || @bits == 64
        end
        def x32?
            @bits == 32
        end
        def x86?
            x32?
        end
        def x64?
            @bits == 64
        end

        def as_bits(x : Int)
            if x64?
                x.to_u64
            else 
                x.to_u32
            end
        end
        def null_ptr : Int32 | Int64
            x64? ? 0_u64 : 0_u32
        end
    end
end

