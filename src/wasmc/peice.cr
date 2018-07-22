
class Class
    private setter unions = [] of Value
    def unions
        @unions.empty? ? [self] : @unions
    end
    def |(o : Class)
        ret = previous_def o
        ret.unions = unions + o.unions
    end
end

AA = Int32 | String
p AA.unions

