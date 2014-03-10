## linalg.jl: Some generic Linear Algebra definitions

scale(X::AbstractArray, s::Number) = scale!(copy(X), s)
scale(s::Number, X::AbstractArray) = scale!(copy(X), s)

function scale{R<:Real,S<:Complex}(X::AbstractArray{R}, s::S)
    Y = Array(promote_type(R,S), size(X))
    copy!(Y, X)
    scale!(Y, s)
end

scale{R<:Real}(s::Complex, X::AbstractArray{R}) = scale(X, s)

function scale!(X::AbstractArray, s::Number)
    for i in 1:length(X)
        @inbounds X[i] *= s
    end
    X
end
scale!(s::Number, X::AbstractArray) = scale!(X, s)

cross(a::AbstractVector, b::AbstractVector) = [a[2]*b[3]-a[3]*b[2], a[3]*b[1]-a[1]*b[3], a[1]*b[2]-a[2]*b[1]]

triu(M::AbstractMatrix) = triu(M,0)
tril(M::AbstractMatrix) = tril(M,0)
#triu{T}(M::AbstractMatrix{T}, k::Integer)
#tril{T}(M::AbstractMatrix{T}, k::Integer)
triu!(M::AbstractMatrix) = triu!(M,0)
tril!(M::AbstractMatrix) = tril!(M,0)

#diff(a::AbstractVector)
#diff(a::AbstractMatrix, dim::Integer)
diff(a::AbstractMatrix) = diff(a, 1)
diff(a::AbstractVector) = [ a[i+1] - a[i] for i=1:length(a)-1 ]

function diff(A::AbstractMatrix, dim::Integer)
    if dim == 1
        [A[i+1,j] - A[i,j] for i=1:size(A,1)-1, j=1:size(A,2)]
    else
        [A[i,j+1] - A[i,j] for i=1:size(A,1), j=1:size(A,2)-1]
    end
end


gradient(F::AbstractVector) = gradient(F, [1:length(F)])
gradient(F::AbstractVector, h::Real) = gradient(F, [h*(1:length(F))])
#gradient(F::AbstractVector, h::AbstractVector)

diag(A::AbstractVector) = error("use diagm instead of diag to construct a diagonal matrix")
#diag(A::AbstractMatrix)

#diagm{T}(v::AbstractVecOrMat{T})

# special cases of vecnorm; note that they don't need to handle isempty(x)
function vecnormMinusInf(x)
    s = start(x)
    (v, s) = next(x, s)
    minabs = abs(v)
    while !done(x, s)
        (v, s) = next(x, s)
        minabs = Base.scalarmin(minabs, abs(v))
    end
    return float(minabs)
end
function vecnormInf(x)
    s = start(x)
    (v, s) = next(x, s)
    maxabs = abs(v)
    while !done(x, s)
        (v, s) = next(x, s)
        maxabs = Base.scalarmax(maxabs, abs(v))
    end
    return float(maxabs)
end
function vecnorm1(x)
    s = start(x)
    (v, s) = next(x, s)
    av = float(abs(v))
    T = typeof(av)
    sum::promote_type(Float64, T) = av
    while !done(x, s)
        (v, s) = next(x, s)
        sum += abs(v)
    end
    return convert(T, sum)
end
function vecnorm2(x)
    maxabs = vecnormInf(x)
    maxabs == 0 && return maxabs
    s = start(x)
    (v, s) = next(x, s)
    T = typeof(maxabs)
    scale::promote_type(Float64, T) = 1/maxabs
    y = abs(v)*scale
    sum::promote_type(Float64, T) = y*y
    while !done(x, s)
        (v, s) = next(x, s)
        y = abs(v)*scale
        sum += y*y
    end
    return convert(T, maxabs * sqrt(sum))
end
function vecnormp(x, p)
    if p > 1 || p < 0 # need to rescale to avoid overflow/underflow
        maxabs = vecnormInf(x)
        maxabs == 0 && return maxabs
        s = start(x)
        (v, s) = next(x, s)
        T = typeof(maxabs)
        spp::promote_type(Float64, T) = p
        scale::promote_type(Float64, T) = 1/maxabs
        ssum::promote_type(Float64, T) = (abs(v)*scale)^spp
        while !done(x, s)
            (v, s) = next(x, s)
            ssum += (abs(v)*scale)^spp
        end
        return convert(T, maxabs * ssum^inv(spp))
    else # 0 < p < 1, no need for rescaling (but technically not a true norm)
        s = start(x)
        (v, s) = next(x, s)
        av = float(abs(v))
        T = typeof(av)
        pp::promote_type(Float64, T) = p
        sum::promote_type(Float64, T) = av^pp
        while !done(x, s)
            (v, s) = next(x, s)
            sum += abs(v)^pp
        end
        return convert(T, sum^inv(pp))
    end
end
function vecnorm(itr, p::Real=2)
    isempty(itr) && return float(real(zero(eltype(itr))))
    p == 2 && return vecnorm2(itr)
    p == 1 && return vecnorm1(itr)
    p == Inf && return vecnormInf(itr)
    p == 0 && return convert(typeof(float(real(zero(eltype(itr))))),
                             countnz(itr))
    p == -Inf && return vecnormMinusInf(itr)
    vecnormp(itr,p)
end
vecnorm(x::Number, p::Real=2) = p == 0 ? real(x==0 ? zero(x) : one(x)) : abs(x)

norm(x::AbstractVector, p::Real=2) = vecnorm(x, p)

function norm1{T}(A::AbstractMatrix{T})
    m,n = size(A)
    nrm = zero(real(zero(T)))
    @inbounds begin
        for j = 1:n
            nrmj = zero(real(zero(T)))
            for i = 1:m
                nrmj += abs(A[i,j])
            end
            nrm = max(nrm,nrmj)
        end
    end
    return nrm
end
function norm2(A::AbstractMatrix)
    m,n = size(A)
    if m == 0 || n == 0 return real(zero(eltype(A))) end
    svdvals(A)[1]
end
function normInf{T}(A::AbstractMatrix{T})
    m,n = size(A)
    nrm = zero(real(zero(T)))
    @inbounds begin
        for i = 1:m
            nrmi = zero(real(zero(T)))
            for j = 1:n
                nrmi += abs(A[i,j])
            end
            nrm = max(nrm,nrmi)
        end
    end
    return nrm
end
function norm{T}(A::AbstractMatrix{T}, p::Real=2)
    p == 2 && return norm2(A)
    p == 1 && return norm1(A)
    p == Inf && return normInf(A)
    throw(ArgumentError("invalid p-norm p=$p. Valid: 1, 2, Inf"))
end

function norm(x::Number, p=2)
    if p == 1 || p == Inf || p == -Inf return abs(x) end
    p == 0 && return ifelse(x != 0, 1, 0)
    float(abs(x))
end

rank(A::AbstractMatrix, tol::Real) = sum(svdvals(A) .> tol)
function rank(A::AbstractMatrix)
    m,n = size(A)
    (m == 0 || n == 0) && return 0
    sv = svdvals(A)
    return sum(sv .> maximum(size(A))*eps(sv[1]))
end
rank(x::Number) = x==0 ? 0 : 1

function trace(A::AbstractMatrix)
    chksquare(A)
    sum(diag(A))
end
trace(x::Number) = x

#kron(a::AbstractVector, b::AbstractVector)
#kron{T,S}(a::AbstractMatrix{T}, b::AbstractMatrix{S})

#det(a::AbstractMatrix)

inv(a::AbstractVector) = error("argument must be a square matrix")
inv{T}(A::AbstractMatrix{T}) = A_ldiv_B!(A,eye(T, chksquare(A)))

function \{TA,TB}(A::AbstractMatrix{TA}, B::AbstractVecOrMat{TB})
    TC = typeof(one(TA)/one(TB))
    A_ldiv_B!(convert(typeof(A).name.primary{TC}, A), TB == TC ? copy(B) : convert(typeof(B).name.primary{TC}, B))
end
\(a::AbstractVector, b::AbstractArray) = reshape(a, length(a), 1) \ b
/(A::AbstractVecOrMat, B::AbstractVecOrMat) = (B' \ A')'
# \(A::StridedMatrix,x::Number) = inv(A)*x Should be added at some point when the old elementwise version has been deprecated long enough
# /(x::Number,A::StridedMatrix) = x*inv(A)

cond(x::Number) = x == 0 ? Inf : 1.0
cond(x::Number, p) = cond(x)

#Skeel condition numbers
condskeel(A::AbstractMatrix, p::Real=Inf) = norm(abs(inv(A))*abs(A), p)
condskeel{T<:Integer}(A::AbstractMatrix{T}, p::Real=Inf) = norm(abs(inv(float(A)))*abs(A), p)
condskeel(A::AbstractMatrix, x::AbstractVector, p::Real=Inf) = norm(abs(inv(A))*abs(A)*abs(x), p)
condskeel{T<:Integer}(A::AbstractMatrix{T}, x::AbstractVector, p::Real=Inf) = norm(abs(inv(float(A)))*abs(A)*abs(x), p)

function issym(A::AbstractMatrix)
    m, n = size(A)
    m==n || return false
    for i = 1:(n-1), j = (i+1):n
        if A[i,j] != A[j,i]
            return false
        end
    end
    return true
end

issym(x::Number) = true

function ishermitian(A::AbstractMatrix)
    m, n = size(A)
    m==n || return false
    for i = 1:n, j = i:n
        if A[i,j] != conj(A[j,i])
            return false
        end
    end
    return true
end

ishermitian(x::Number) = (x == conj(x))

function istriu(A::AbstractMatrix)
    m, n = size(A)
    for j = 1:min(n,m-1), i = j+1:m
        if A[i,j] != 0
            return false
        end
    end
    return true
end

function istril(A::AbstractMatrix)
    m, n = size(A)
    for j = 2:n, i = 1:min(j-1,m)
        if A[i,j] != 0
            return false
        end
    end
    return true
end

istriu(x::Number) = true
istril(x::Number) = true

linreg{T<:Number}(X::StridedVecOrMat{T}, y::Vector{T}) = [ones(T, size(X,1)) X] \ y

# weighted least squares
function linreg(x::AbstractVector, y::AbstractVector, w::AbstractVector)
    sw = sqrt(w)
    [sw sw.*x] \ (sw.*y)
end

# multiply by diagonal matrix as vector
#diagmm!(C::AbstractMatrix, A::AbstractMatrix, b::AbstractVector)

#diagmm!(C::AbstractMatrix, b::AbstractVector, A::AbstractMatrix)

scale!(A::AbstractMatrix, b::AbstractVector) = scale!(A,A,b)
scale!(b::AbstractVector, A::AbstractMatrix) = scale!(A,b,A)

#diagmm(A::AbstractMatrix, b::AbstractVector)
#diagmm(b::AbstractVector, A::AbstractMatrix)

#^(A::AbstractMatrix, p::Number)

#findmax(a::AbstractArray)
#findmin(a::AbstractArray)

#rref{T}(A::AbstractMatrix{T})

function peakflops(n::Integer=2000; parallel::Bool=false)
    a = rand(100,100)
    t = @elapsed a*a
    a = rand(n,n)
    t = @elapsed a*a
    parallel ? sum(pmap(peakflops, [ n for i in 1:nworkers()])) : (2*n^3/t)
end

# BLAS-like in-place y=alpha*x+y function (see also the version in blas.jl
#                                          for BlasFloat Arrays)
function axpy!(alpha, x::AbstractArray, y::AbstractArray)
    n = length(x)
    n==length(y) || throw(DimensionMismatch(""))
    for i = 1:n
        @inbounds y[i] += alpha * x[i]
    end
    y
end
function axpy!{Ti<:Integer,Tj<:Integer}(alpha, x::AbstractArray, rx::AbstractArray{Ti}, y::AbstractArray, ry::AbstractArray{Tj})
    length(x)==length(y) || throw(DimensionMismatch(""))
    if minimum(rx) < 1 || maximum(rx) > length(x) || minimum(ry) < 1 || maximum(ry) > length(y) || length(rx) != length(ry)
        throw(BoundsError())
    end
    for i = 1:length(rx)
        @inbounds y[ry[i]] += alpha * x[rx[i]]
    end
    y
end

# Elementary reflection similar to LAPACK. The reflector is not Hermitian but ensures that tridiagonalization of Hermitian matrices become real. See lawn72
function elementaryLeft!(A::AbstractMatrix, row::Integer, col::Integer)
    m, n = size(A)
    1 <= row <= m || throw(BoundsError("row cannot be less than one or larger than $(size(A,1))"))
    1 <= col <= n || throw(BoundsError("col cannot be less than one or larger than $(size(A,2))"))
    @inbounds begin
        ξ1 = A[row,col]
        normu = abs2(ξ1)
        for i = row+1:m
            normu += abs2(A[i,col])
        end
        normu = sqrt(normu)
        ν = copysign(normu,real(ξ1))
        A[row,col] += ν
        ξ1 += ν
        A[row,col] = -ν
        for i = row+1:m
            A[i,col] /= ξ1
        end
    end
    ξ1/ν
end
function elementaryRight!(A::AbstractMatrix, row::Integer, col::Integer)
    m, n = size(A)
    1 <= row <= m || throw(BoundsError("row cannot be less than one or larger than $(size(A,1))"))
    1 <= col <= n || throw(BoundsError("col cannot be less than one or larger than $(size(A,2))"))
    row <= col || error("col cannot be larger than row")
    @inbounds begin
        ξ1 = A[row,col]
        normu = abs2(ξ1)
        for i = col+1:n
            normu += abs2(A[row,i])
        end
        normu = sqrt(normu)
        ν = copysign(normu,real(ξ1))
        A[row,col] += ν
        ξ1 += ν
        A[row,col] = -ν
        for i = col+1:n
            A[row,i] /= ξ1
        end
    end
    conj(ξ1/ν)
end
function elementaryRightTrapezoid!(A::AbstractMatrix, row::Integer)
    m, n = size(A)
    1 <= row <= m || throw(BoundsError("row cannot be less than one or larger than $(size(A,1))"))
    @inbounds begin
        ξ1 = A[row,row]
        normu = abs2(A[row,row])
        for i = m+1:n
            normu += abs2(A[row,i])
        end
        normu = sqrt(normu)
        ν = copysign(normu,real(ξ1))
        A[row,row] += ν
        ξ1 += ν
        A[row,row] = -ν
        for i = m+1:n
            A[row,i] /= ξ1
        end
    end
    conj(ξ1/ν)
end
