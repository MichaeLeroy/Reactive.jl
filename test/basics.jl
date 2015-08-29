using FactCheck
using Reactive
using Compat

step() = Reactive.run(1)
number() = round(Int, rand()*1000)

## Basics

facts("Basic checks") do

    a = Input(number())
    b = consume(x -> x*x, a)

    context("consume") do

        # Lift type
        #@fact typeof(b) => Reactive.Lift{Int}

        # type conversion
        push!(a, 1.0)
        step()
        @fact value(b) => 1
        # InexactError to be precise
        push!(a, 2.1)
        @fact_throws step()

        @fact value(b) => 1

        push!(a, number())
        step()
        @fact value(b) => value(a)^2

        push!(a, -number())
        step()
        @fact value(b) => value(a)^2

        ## Multiple inputs to Lift
        c = consume(+, a, b, typ=Int)
        @fact value(c) => value(a) + value(b)

        push!(a, number())
        step()
        @fact value(c) => value(a) + value(b)

        push!(b, number())
        step()
        @fact value(c) => value(a) + value(b)
    end


    context("merge") do

        ## Merge
        d = Input(number())
        e = merge(d, b, a)

        # precedence to d
        @fact value(e) => value(d)

        push!(a, number())
        step()
        # precedence to b over a -- a is older.
        @fact value(e) => value(a)

        c = consume(_->_, a) # Make a younger than b
        f = merge(d, c, b)
        push!(a, number())
        step()
        @fact value(f) => value(c)
    end

    context("foldp") do

        ## foldl over time
        push!(a, 0)
        step()
        f = foldp(+, 0, a)
        nums = round(Int, rand(100)*1000)
        map(x -> begin push!(a, x); step() end, nums)

        @fact sum(nums) => value(f)
    end

    context("filter") do
        # filter
        g = Input(0)
        pred = x -> x % 2 != 0
        h = filter(pred, 1, g)

        @fact value(h) => 1

        push!(g, 2)
        step()
        @fact value(h) => 1

        push!(g, 3)
        step()
        @fact value(h) => 3
    end

    context("sampleon") do
        # sampleon
        g = Input(0)

        push!(g, number())
        step()
        i = Input(true)
        j = sampleon(i, g)
        # default value
        @fact value(j) => value(g)
        push!(g, value(g)-1)
        step()
        @fact value(j) => value(g)+1
        push!(i, true)
        step()
        @fact value(j) => value(g)
    end

    context("droprepeats") do
        # droprepeats
        count = s -> foldp((x, y) -> x+1, 0, s)

        k = Input(1)
        l = droprepeats(k)

        @fact value(l) => value(k)
        push!(k, 1)
        step()
        @fact value(l) => value(k)
        push!(k, 0)
        step()
        #println(l.value, " ", value(k))
        @fact value(l) => value(k)

        m = count(k)
        n = count(l)

        seq = [1, 1, 1, 0, 1, 0, 1, 0, 0]
        map(x -> begin push!(k, x); step() end, seq)

        @fact value(m) => length(seq)
        @fact value(n) => 6
    end

    context("dropwhen") do
        # dropwhen
        b = Input(true)
        n = Input(1)
        dw = dropwhen(b, 0, n)
        @fact value(dw) => 0
        push!(n, 2)
        step()
        @fact value(dw) => 0
        push!(b, false)
        step()
        @fact value(dw) => 0
        push!(n, 1)
        step()
        @fact value(dw) => 1
        push!(n, 2)
        step()
        @fact value(dw) => 2
        dw = dropwhen(b, 0, n)
        @fact value(dw) => 2
    end
end