"""
Abstract type for all specialized bases of a Hilbert space.

The `Basis` type specifies an orthonormal basis for the Hilbert
space of the studied system. All subtypes must implement `Base.:(==)`,
and `Base.size`. `size` should return a tuple representing the total dimension
of the Hilbert space with any tensor product structure the basis has such that 
`length(b::Basis) = prod(size(b))` gives the total Hilbert dimension

Composite systems can be defined with help of [`CompositeBasis`](@ref).

All relevant properties of subtypes of `Basis` defined in `QuantumInterface`
should be accessed using their documented functions and should not
assume anything about the internal representation of instances of these  
types (i.e. don't access the struct's fields directly).
"""
abstract type Basis end

"""
Abstract type for `Bra` and `Ket` states.

The state vector class stores an abstract state with respect
to a certain basis. All subtypes must implement the `basis`
method which should this basis as a subtype of `Basis`.
"""
abstract type StateVector end
abstract type AbstractKet <: StateVector end
abstract type AbstractBra <: StateVector end

"""
Abstract type for all operators and super operators.

All subtypes must implement the methods `basis_l` and
`basis_r` which return subtypes of `Basis` and
represent the left and right bases that the operator
maps between and thus is compatible with a `Bra` defined
in the left basis and a `Ket` defined in the right basis.

For fast time evolution also at least the function
`mul!(result::Ket,op::AbstractOperator,x::Ket,alpha,beta)` should be
implemented. Many other generic multiplication functions can be defined in
terms of this function and are provided automatically.
"""
abstract type AbstractOperator end

const AbstractQObjType = Union{<:StateVector,<:AbstractOperator}
