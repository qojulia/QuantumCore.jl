##
# Basis checks
##

const BASES_CHECK = Ref(true)

"""
    @compatiblebases

Macro to skip checks for compatible bases. Useful for `*`, `expect` and similar
functions.
"""
macro compatiblebases(ex)
    return quote
        BASES_CHECK.x = false
        local val = $(esc(ex))
        BASES_CHECK.x = true
        val
    end
end

function check_addible(b1, b2)
    if BASES_CHECK[] && !addible(b1, b2)
        throw(IncompatibleBases())
    end
end

function check_multiplicable(b1, b2)
    if BASES_CHECK[] && !multiplicable(b1, b2)
        throw(IncompatibleBases())
    end
end

addible(a::AbstractQObjType, b::AbstractQObjType) = false
addible(a::AbstractBra, b::AbstractBra) = (basis(a) == basis(b))
addible(a::AbstractKet, b::AbstractKet) = (basis(a) == basis(b))
addible(a::AbstractOperator, b::AbstractOperator) =
    (basis_l(a) == basis_l(b)) && (basis_r(a) == basis_r(b))

multiplicable(a::AbstractQObjType, b::AbstractQObjType) = false
multiplicable(a::AbstractBra, b::AbstractKet) = (basis(a) == basis(b))
multiplicable(a::AbstractOperator, b::AbstractKet) = (basis_r(a) == basis(b))
multiplicable(a::AbstractBra, b::AbstractOperator) = (basis(a) == basis_l(b))
multiplicable(a::AbstractOperator, b::AbstractOperator) = (basis_r(a) == basis_l(b))

basis(a::StateVector) = throw(ArgumentError("basis() is not defined for this type of state vector: $(typeof(a))."))
basis_l(a::AbstractOperator) = throw(ArgumentError("basis_l() is not defined for this type of operator: $(typeof(a))."))
basis_r(a::AbstractOperator) = throw(ArgumentError("basis_r() is not defined for this type of operator: $(typeof(a))."))
basis(a::AbstractOperator) = (basis_l(a) == basis_r(a); basis_l(a))

##
# tensor, reduce, ptrace
##

tensor(b::Basis) = b

"""
    tensor(x::Basis, y::Basis, z::Basis...)

Create a [`CompositeBasis`](@ref) from the given bases.

Any given CompositeBasis is expanded so that the resulting CompositeBasis never
contains another CompositeBasis.
"""
tensor(b1::Basis, b2::Basis) = CompositeBasis([length(b1); length(b2)], (b1, b2))
tensor(b1::CompositeBasis, b2::CompositeBasis) = CompositeBasis([b1.shape; b2.shape], (b1.bases..., b2.bases...))
function tensor(b1::CompositeBasis, b2::Basis)
    N = length(b1.bases)
    shape = vcat(b1.shape, length(b2))
    bases = (b1.bases..., b2)
    CompositeBasis(shape, bases)
end
function tensor(b1::Basis, b2::CompositeBasis)
    N = length(b2.bases)
    shape = vcat(length(b1), b2.shape)
    bases = (b1, b2.bases...)
    CompositeBasis(shape, bases)
end
tensor(bases::Basis...) = reduce(tensor, bases)

function Base.:^(b::Basis, N::Integer)
    if N < 1
        throw(ArgumentError("Power of a basis is only defined for positive integers."))
    end
    tensor([b for i=1:N]...)
end

"""
    reduced(a, indices)

Reduced basis, state or operator on the specified subsystems.

The `indices` argument, which can be a single integer or a vector of integers,
specifies which subsystems are kept. At least one index must be specified.
"""
function reduced(b::CompositeBasis, indices)
    if length(indices)==0
        throw(ArgumentError("At least one subsystem must be specified in reduced."))
    elseif length(indices)==1
        return b.bases[indices[1]]
    else
        return CompositeBasis(b.shape[indices], b.bases[indices])
    end
end

"""
    ptrace(a, indices)

Partial trace of the given basis, state or operator.

The `indices` argument, which can be a single integer or a vector of integers,
specifies which subsystems are traced out. The number of indices has to be
smaller than the number of subsystems, i.e. it is not allowed to perform a
full trace.
"""
function ptrace(b::CompositeBasis, indices)
    J = [i for i in 1:length(b.bases) if i ∉ indices]
    length(J) > 0 || throw(ArgumentError("Tracing over all indices is not allowed in ptrace."))
    reduced(b, J)
end

ptrace(a::AbstractOperator, index) = arithmetic_unary_error("Partial trace", a)
_index_complement(b::CompositeBasis, indices) = complement(length(b.bases), indices)
reduced(a, indices) = ptrace(a, _index_complement(basis(a), indices))
traceout!(s::StateVector, i) = ptrace(s,i)

##
# nsubsystems
##

nsubsystems(s::AbstractKet) = nsubsystems(basis(s))
nsubsystems(s::AbstractOperator) = nsubsystems(basis(s))
nsubsystems(b::CompositeBasis) = length(b.bases)
nsubsystems(b::Basis) = 1
nsubsystems(::Nothing) = 1 # TODO Exists because of QuantumSavory; Consider removing this and reworking the functions that depend on it. E.g., a reason to have it when performing a project_traceout measurement on a state that contains only one subsystem

##
# directsum
##

"""
    directsum(b1::Basis, b2::Basis)

Construct the [`SumBasis`](@ref) out of two sub-bases.
"""
directsum(b1::Basis, b2::Basis) = SumBasis(Int[length(b1); length(b2)], Basis[b1, b2])
directsum(b::Basis) = b
directsum(b::Basis...) = reduce(directsum, b)
function directsum(b1::SumBasis, b2::Basis)
    shape = [b1.shape;length(b2)]
    bases = [b1.bases...;b2]
    return SumBasis(shape, (bases...,))
end
function directsum(b1::Basis, b2::SumBasis)
    shape = [length(b1);b2.shape]
    bases = [b1;b2.bases...]
    return SumBasis(shape, (bases...,))
end
function directsum(b1::SumBasis, b2::SumBasis)
    shape = [b1.shape;b2.shape]
    bases = [b1.bases...;b2.bases...]
    return SumBasis(shape, (bases...,))
end

directsum(x::StateVector...) = reduce(directsum, x)
directsum(a::AbstractOperator...) = reduce(directsum, a)
