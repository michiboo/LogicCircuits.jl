# helper test functions to check for SDD properties holding

function validate(sdd::Sdd)
   for node in linearize(sdd) # linearize first so that callee can use bit field
      validate_node(node)
   end
    #TODO make one of these for structured decomposability
    @test isdecomposable(sdd)
    @test iscanonical(sdd, 5; verbose = true)
 end
   
function validate_node(n::Sdd)
   validate_node(GateType(n), n)
end

function validate_node(::⋁Gate, n::Sdd)
   size = num_children(n)
   primes = compile(mgr(n),false)
   for i = 1:size
      element = children(n)[i]
      # has alternating layers
      @test GateType(element) isa ⋀Gate
      for j = i+1:size
         other_element = children(n)[j]
         # is deterministic
         @test isfalse(prime(element) & prime(other_element))
         # is compressed
         @test sub(element) !== sub(other_element)
      end
      primes = primes | prime(element)
   end
   # is exhaustive
   @test istrue(primes)
   # cannot be trimmed to the sub
   @test size >= 1
   # cannot be trimmed to the prime
   if size == 2
      e1 = children(n)[1]
      e2 = children(n)[2]
      has_false_sub = (isfalse(sub(e1)) || isfalse(sub(e2)))
      has_true_sub = (istrue(sub(e1)) || istrue(sub(e2)))
      @test !(has_false_sub && has_true_sub)
   end
   @test NodeType(vtree(n)) isa Inner
end

function validate_node(::⋀Gate, n::Sdd)
   @test num_children(n) == 2
   @test !(GateType(prime(n)) isa ⋀Gate)
   @test !(GateType(sub(n)) isa ⋀Gate)
   # has no false prime
   @test !isfalse(prime(n))
   @test NodeType(vtree(n)) isa Inner 
   @test GateType(prime(n)) isa ConstantGate || varsubset_left(prime(n), n)
   @test GateType(sub(n)) isa ConstantGate || varsubset_right(sub(n), n)
end

function validate_node(::LiteralGate, l::Sdd)
   @test variable(l) == first(variables(vtree(l)))
end

function validate_node(::ConstantGate, ::Sdd)
   # nothing to check?
end