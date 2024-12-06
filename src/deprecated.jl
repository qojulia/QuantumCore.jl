function equal_bases(a, b)
    Base.depwarn("`==` should be preferred over `equal_bases`!", :equal_bases)
    if a===b
        return true
    end
    for i=1:length(a)
        if a[i]!=b[i]
            return false
        end
    end
    return true
end

Base.@deprecate PauliBasis(num_qubits) NQubitBasis(num_qubits) false

function equal_shape(a, b)
    if a === b
        return true
    end
    if length(a) != length(b)
        return false
    end
    for i=1:length(a)
        if a[i]!=b[i]
            return false
        end
    end
    return true
end

macro samebases(ex)
    return quote
        BASES_CHECK.x = false
        local val = $(esc(ex))
        BASES_CHECK.x = true
        val
    end
end

function check_samebases(b1, b2)
    if BASES_CHECK[] && !samebases(b1, b2)
        throw(IncompatibleBases())
    end
end

function check_multiplicable(b1, b2)
    if BASES_CHECK[] && !multiplicable(b1, b2)
        throw(IncompatibleBases())
    end
end

samebases(b1::Basis, b2::Basis) = b1==b2
samebases(b1::Tuple{Basis, Basis}, b2::Tuple{Basis, Basis}) = b1==b2 # for checking superoperators
samebases(a::AbstractOperator) = samebases(a.basis_l, a.basis_r)::Bool # FIXME issue #12
samebases(a::AbstractOperator, b::AbstractOperator) = samebases(a.basis_l, b.basis_l)::Bool && samebases(a.basis_r, b.basis_r)::Bool # FIXME issue #12
check_samebases(a::Union{AbstractOperator, AbstractSuperOperator}) = check_samebases(a.basis_l, a.basis_r) # FIXME issue #12

multiplicable(b1::Basis, b2::Basis) = b1==b2

function multiplicable(b1::CompositeBasis, b2::CompositeBasis)
    if !equal_shape(b1.shape,b2.shape)
        return false
    end
    for i=1:length(b1.shape)
        if !multiplicable(b1.bases[i], b2.bases[i])
            return false
        end
    end
    return true
end

multiplicable(a::AbstractOperator, b::AbstractOperator) = multiplicable(a.basis_r, b.basis_l) # FIXME issue #12
