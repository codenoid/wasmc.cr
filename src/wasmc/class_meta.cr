
module WasmC
    class ClassInfo
        struct FieldInfo < ReturnInfo
            property offset : UInt64
            def initialize(@offset, *args)
                super *args
            end
            def initialize(owner : ClassInfo, *args)
                @offset = owner.size!
                super *args
            end
        end
        record GenericTypeParameter, name : String, 
            owner : ClassInfo do
            def resolve
                @owner.generics[self]
            end
            def resolve!
                (resolve || raise Error::GenericNotResolved.new self).not_nil!
            end
            def_equals_and_hash owner, name
        end

        getter name : String
        # can only added
        getter fields = {} of (String, FieldInfo)
        getter generics : Hash(GenericTypeParameter, ClassInfo?)

        def initialize(@name, **@fields)
        end
        private def initialize_dup
            @fields, @generics = @fields.dup, @generics.dup
            self
        end

        @size : UInt64 = 0
        def size!
            @fields.each_value.sum &.size
        end
        def size
            @final ? @size : size!
        end
        def add_generic(name : String)
            raise "The same generic #{name} has existed" if @generic.has_key? name
            @generics[name] = nil 
            self
        end
        def instantiation(**vals)
            ret = clone
            vals.each do |k, v|
                unless k.is_a? GenericTypeParameter
                    k = k.to_s unless k.is_a? String
                    k = GenericTypeParameter.new k, self
                end
                ret.generics[k] = v
            end
            ret
        end

        class Error::GenericNotResolved
            getter generic : GenericTypeParameter
            def initialize(@generic, node = nil)
                supper nil, node
            end
            def message
                "Generic parameter #{generic.name} of #{generic.owner} not instanised"
            end
        end
        @generic_resolved : Bool = false
        def generic_resolve!
            return if @final && @generic_resolved
            generics.each do |k,v|
                raise Error::GenericNotResolved.new k if v.nil?
                v.generic_resolve!
            end
            @generic_resolved = true
            self
        end

        @final : Bool = false
        def final
            @final = true
            @size = size!
        end
        def to_s
            name
        end
        def clone
            dup.initialize_dup
        end

        Nil = self.new

        Array = self.new "Array", len: FieldInfo.new self, ReturnInfo::Kind::U32,
            constant: true
        Array.add_generic "Element"
        String = Array.instantiation Element: 
            self.new "String", len: FieldInfo.new self, ReturnInfo::Kind::U32,
            constant: true
    end
end
