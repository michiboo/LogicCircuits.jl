using Test
using LogicCircuits
using LogicCircuits: Element # test some internals

@testset "Trimmed SDD test" begin

    num_vars = 7
    mgr = SddMgr(num_vars, :balanced)
    
    @test num_variables(mgr) == num_vars
    @test num_nodes(mgr) == 2*num_vars-1
    @test num_edges(mgr) == 2*num_vars-2
    @test mgr isa SddMgr

    @test varsubset(left_most_descendent(mgr), mgr)
    @test varsubset(mgr.left, mgr)
    @test varsubset(mgr.right, mgr)
    @test varsubset_left(mgr.left, mgr)
    @test varsubset_left(mgr.left.left, mgr)
    @test varsubset_left(mgr.left.right, mgr)
    @test varsubset_right(mgr.right, mgr)
    @test varsubset_right(mgr.right.right, mgr)
    @test varsubset_right(mgr.right.left, mgr)

    @test !varsubset(mgr, left_most_descendent(mgr))
    @test !varsubset_left(mgr.right, mgr)
    @test !varsubset_left(mgr.right.left, mgr)
    @test !varsubset_left(mgr.right.right, mgr)
    @test !varsubset_left(mgr, mgr)
    @test !varsubset_left(mgr, mgr.left)
    @test !varsubset_left(mgr, mgr.right)
    @test !varsubset_right(mgr.left, mgr)
    @test !varsubset_right(mgr.left.right, mgr)
    @test !varsubset_right(mgr.left.left, mgr)
    @test !varsubset_right(mgr, mgr)
    @test !varsubset_right(mgr, mgr.left)
    @test !varsubset_right(mgr, mgr.right)

    x = Var(1)
    y = Var(2)
    
    x_c = compile(mgr, var2lit(x))
    y_c = compile(mgr, var2lit(y))

    @test x_c != y_c 

    @test variable(x_c) == x
    @test literal(x_c) == var2lit(x)
    @test vtree(x_c) ∈ mgr
    @test ispositive(x_c)
    @test x_c == compile(mgr, var2lit(x))

    @test variable(y_c) == y
    @test literal(y_c) == var2lit(y)
    @test vtree(y_c) ∈ mgr
    @test ispositive(y_c)
    @test y_c == compile(mgr, var2lit(y))

    notx = -var2lit(x)

    notx_c = compile(mgr,notx)

    @test sat_prob(x_c) == 1//2
    @test sat_prob(notx_c) == 1//2
    @test model_count(x_c,num_vars) == BigInt(2)^(num_vars-1)
    @test model_count(notx_c,num_vars) == BigInt(2)^(num_vars-1)
    @test !notx_c(true)
    @test notx_c(false)

    @test variable(notx_c) == x
    @test literal(notx_c) == notx
    @test vtree(notx_c) ∈ mgr
    @test isnegative(notx_c)
    @test notx_c == compile(mgr, notx)

    true_c = compile(mgr,true)

    @test istrue(true_c)
    @test constant(true_c) == true
    
    false_c = compile(mgr,false)
    
    @test isfalse(false_c)
    @test constant(false_c) == false

    @test !true_c == false_c
    @test !false_c == true_c
    @test !x_c == notx_c
    @test !notx_c == x_c 

    @test model_count(true_c,num_vars) == BigInt(2)^(num_vars)
    @test model_count(false_c,num_vars) == BigInt(0)

    v1 = compile(mgr, Lit(1))
    v2 = compile(mgr, Lit(2))
    v3 = compile(mgr, Lit(3))
    v4 = compile(mgr, Lit(4))
    v5 = compile(mgr, Lit(5))
    v6 = compile(mgr, Lit(6))
    v7 = compile(mgr, Lit(7))
    @test_throws Exception compile(mgr, Lit(8))

    p1 = [Element(true_c,v3)]
    @test canonicalize(p1, mgr.left.right) === v3
    p2 = [Element(v1,true_c), Element(!v1,false_c)]
    @test canonicalize(p2, mgr.left) === v1

    p3 = [Element(v1,v4), Element(!v1,v7)]
    n1 = canonicalize(p3, mgr)
    p4 = [Element(!v1,v7), Element(v1,v4)]
    n2 = canonicalize(p4,mgr)
    @test n1.vtree.left === mgr.left
    @test n1.vtree.right === mgr.right
    @test n1 === n2
    @test isdeterministic(n1)
    @test n1(true, false, false, true, false, false, false)
    @test !n1(false, true, false, true, false, false, false)

end