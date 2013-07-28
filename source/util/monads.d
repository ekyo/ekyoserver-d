/**
* Chained null checks, Maybe Monad, D Programming UFCS.
*
* Author:   M1xA, www.m1xa.com
* Date:     2013.02.23
* Licence:  MIT
* Version:  3.0
*
* Examples:
*---
* (new Person())
*     .select!(x => x.address)
*     .select!(x => to!string(x.postCode))("Empty")
*     .writeln();
*
* Output: "Empty" if x.address is null.
*---
*/
module maybe;

import std.traits;

/**
* If object is not null a lambda expression - fun - is executed.
*
* Params: o = input parameter of fun.
* Returns: Reference to same object.
*/
I call(alias fun, I)(I o)
{
    return o is null ? null : (fun(o), o);
}

/** Example: call. */
unittest
{
    int* i;
    assert(i.call!(x => ++ *x) is null);
    i = new int();
    assert(i.call!(x => ++ *x) !is null);
    assert(*i == 1);
}

/**
* Params: o = parameter with object or value semantics.
* Returns: result of fun(object) if object is not null,
* otherwise - null.
*/
auto select(alias fun, I)(I o)
{
    static if(isAssignable!(I, typeof(null)))
    {
        return o is null ? null : fun(o);
    }
    else
        return fun(o);
}

/** Example: select. */
unittest
{
    class Test { int i; }
    auto update = function Test (Test v) { ++ v.i; return v; };
    Test t;
    assert(t.select!(x => x) is null);
    t = new Test();
    assert(t.select!(x => update(x)) !is null);
    assert(t.i == 1);
}

/**
* Returns: failureResult if object is null,
* otherwise - result of fun(object).
*/
R select(alias fun, I, R)(I o, lazy R failureResult)
{
    return o is null ? failureResult : fun(o);
}

/** Example: select with failureResult. */
unittest
{
    int* i;
    assert(i.select!(x => *x)(42) == 42);
    i = new int();
    *i = 42;
    assert(i.select!(x => *x)(0) != 0);
}

/**
* Put a value into call chain.
*
* Params: o = parameter with value semantics.
* Returns: result of fun(value).
*
* Example:
* ---
* class Test { int v; this(int value) { v = value; } }
* int i = 55;
* Test t = i.selectValue!(x => new Test(x)).call!(x => ++x.v);
* Output: 56.
* ---
*/
auto selectValue(alias fun, I)(I o)
{
    return fun(o);
}

/**
* Returns: same reference if object is not null
* and result of lambda expression - fun - is false,
* otherwise - null.
*/
I unless(alias fun, I)(I o)
{
    return o is null ? null : fun(o) ? null : o;
}

/** Example: unless. */
unittest
{
    class Test { int v = 5; }
    Test t;
    assert(t is null);
    t = new Test();
    assert(t.unless!(x => x.v > 5).select!(x => x.v + 42)(0) == 47);
}

/**
* Returns: Same reference if object is not null
* and result of lambda expression - fun - is true,
* otherwise - null.
*/
I when(alias fun, I)(I o)
{
    return o is null ? null : fun(o) ? o : null;
}

/** Example: when. */
unittest
{
    int* i;
    int v = 42;
    assert(i.when!(x => *x > 0).select!(x => *x * *x)(0) == 0);
    i =  &v;
    assert(i.when!(x => *x > 0).select!(x => *x * *x)(0) == (42 * 42));
}
