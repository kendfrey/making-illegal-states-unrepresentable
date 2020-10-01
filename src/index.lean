/-*
---
title: Making Illegal States Unrepresentable
---

<!-- .slide: class="center" -->

# Making Illegal States Unrepresentable

## Dependent Types And Why They're Useful

---

<!-- .slide: class="center" -->

# Prologue: Why Types?

----

Types serve two major purposes:

- Abstraction - humans need to understand code.
- Static code analysis - computers need to understand code, too.

----

## Abstraction

Types let us make code "about" useful concepts like dates, users, and files.
We're no longer restricted to thinking about a single kind of data, such as bytes.

Types define which values and operations are valid in a given context.
We can write code "about" sending an email or opening a file.

In the words of Yaron Minsky, we can use types to
[make illegal states unrepresentable](https://blog.janestreet.com/effective-ml-revisited/).
The simplest example is a yes/no flag.
When all we have are bytes, there are 256 possible states, but we only want there to be two (yes and no).
There will be 254 illegal or redundant states.

A boolean type solves this problem by having only two possible states, by definition.

This approach is fantastically useful in making code more robust without needing to write a lot of error checking.
The definitions of types can avoid giving us ways to make mistakes.

----

## Static analysis

The most directly useful way to use types is to allow the compiler to check our code for certain kinds of errors.

```csharp
DateTime MyFunction(int a, string b)
{
    return a / b;
}
```

This code is syntactically correct, but obvious nonsense.
You can't divide a number by a string, especially not in a way that produces a date/time.

In order to understand what went wrong, we need the concept of types.
And once we have a compiler that understands types,
it can check code automatically to make sure it follows the rules of types.

---

<!-- .slide: class="center" -->

# Chapter 1: Simple types

----

We'll be using Lean from here on. Lean is a functional programming language with dependent types.

Let's start writing some code.
*-/

-- Ignore the default math notation and stick to ASCII.
set_option pp.unicode false

/-*
----

In Lean, every expression has a type. Let's check the types of a few expressions.
*-/

#check 1 + 1
-- 1 + 1 : nat

#check "Hello, World!"
-- "Hello, World!" : string

#check int
-- int : Type

/-*
`1 + 1` is a `nat`, that is, a natural number (nonnegative integer). `"Hello, World!"` is a string, and `int` is a type.

You may notice that the syntax for `int` is the same as the other values.
Lean has first-class types, meaning that types can be assigned to variables and passed to functions,
just like data.

----

## Creating new types

Most languages come with a few ways to define new complex types from simpler types.

Here are several useful kinds of complex types.
*-/

namespace simple

/-*
----

## Functions

In functional programming, functions are values, and therefore they have types.

Let's declare a variable that contains the type of functions that accept a string and return an integer,
using the `->` notation.
*-/

def my_function_type := string -> int

#check my_function_type
-- my_function_type : Type

/-*
This is indeed a type.

----

We can create a value of this type by defining a function.
*-/

def my_function : my_function_type := fun s, s.length

#check my_function
-- my_function : my_function_type

#check my_function "Hello, World!"
-- my_function "Hello, World!" : int

#eval my_function "Hello, World!"
-- 13

/-*
If we apply the function to a string, it will return an `int`.
If we apply it to `"Hello, World!"`, it will return 13, since that is the length of the string.

----

## Records

To store multiple related pieces of data together, we use record types (or structures).

Let's define a type for a person with a name and an age, using the `structure` keyword.
*-/

structure person := (name : string) (age : nat)

#check person
-- person : Type

/-*
Once again, we have a type.

----

Unsurprisingly, we can create a value of this type:
*-/

def kendall : person := { name := "Kendall", age := 42 }

#check kendall
-- kendall : person

#check kendall.name
-- kendall.name : string

#eval kendall.name
-- "Kendall"

/-*
Record types are very common in modern programming.
Objects are based on records, and so all object-oriented languages implicitly use the concept of records.

----

## Unions

To store one of multiple possible types of values, we use union types (or sum types).

Lean doesn't support union type definitions directly like it does records.
It does have a `sum` type, which is a built-in type that represents a union of two types.
*-/

def int_or_string := sum int string

#check int_or_string
-- int_or_string : Type

/-*
----

Once again, we can create a value of this type.
`sum.inl` is the way to create a value of the "left" side of a sum.
*-/

def forty_two : int_or_string := sum.inl 42

#check forty_two
-- forty_two : int_or_string

/-*
----

## Inductive Types

Inductive type definitions are a combination of records and unions.
They are very powerful and used in many languages.

Inductive types have zero or more constructors. Each constructor takes zero or more parameters.

----

An **enum** can be implemented as an inductive type where none of the constructors take parameters:
*-/

inductive boolean
| true
| false

#check boolean
-- boolean : Type

#check boolean.true
-- boolean.true : boolean

/-*
----

A **union** can be implemented as an inductive type where each constructor takes one parameter:
*-/

inductive int_or_string2
| from_int (n : int)
| from_string (s : string)

#check int_or_string2
-- int_or_string2 : Type

#check int_or_string2.from_int
-- int_or_string2.from_int : int -> int_or_string2

def forty_three := int_or_string2.from_int 43

#check forty_three
-- forty_three : int_or_string2

/-*
Constructors that take parameters are functions.

----

A **record** can be implemented as an inductive type with only one constructor:
*-/

inductive vector
| make (x : int) (y : int)

#check vector.make
-- vector.make : int -> int -> vector

def origin := vector.make 0 0

#check origin
-- origin : vector

/-*
----

Inductive types can also be more complex. Here is how a list of natural numbers is defined, using recursion:
*-/

inductive list
| empty
| make (head : nat) (tail : list)

#check list.empty
-- list.empty : list

#check list.make
-- list.make : nat -> list -> list

#check list.make 42 list.empty
-- list.make 42 list.empty : list

/-*
This reads as: A list of nats is either the empty list or a nat (the first one in the list)
plus a list of nats (the rest of the list).

----

Inductive types are the main way to create types in many functional programming languages,
just like classes are in many object-oriented languages.

This includes types like lists or arrays, which don't need to be built into the compiler but can be defined in code.
*-/

end simple

/-*
---

<!-- .slide: class="center" -->

# Chapter 2: Generic types

----

There's a problem with the simple type system we've seen so far.
We defined a type that can represent a list of nats, but what if we want a list of ints, or a list of strings?
It wouldn't be good to repeat the same definition over and over for each possible type.

Generic types solve this problem.
They let us pass types as parameters, so we can create a version of the generic type for any type we wish.
*-/

namespace generic

/-*
----

## Inductive types

Here's what a list looks like as a generic type:
*-/

inductive list (a : Type)
| empty : list
| make (head : a) (tail : list) : list

#check list
-- list : Type -> Type

#check list string
-- list string : Type

/-*
Here `list` takes a parameter `a` which is the type of elements in the list.

A generic type is a function that accepts a type and returns a type.

----

## Function types

It's possible to define generic function types as well.
*-/

def serializer (a : Type) := a -> string

#check serializer
-- serializer : Type -> Type

#check serializer nat
-- serializer nat : Type

/-*
A `serializer a` is a function that converts an `a` to a string.

----
*-/

def my_serializer : serializer nat := fun x, to_string x

#check my_serializer
-- my_serializer : serializer nat

#check my_serializer 42
-- my_serializer 42 : string

#eval my_serializer 42
-- "42"

/-*
Passing a nat to a nat serializer results in a string.

----

## Records

Records can also be generic.
*-/

structure vector (a : Type) := (x : a) (y : a)

#check vector
-- vector : Type -> Type

#check vector int
-- vector int : Type

/-*
This is a vector that can store two coordinates of any type.

----

Even strings, if we wish.
*-/

def not_origin : vector string := { x := "0", y := "Hello, World!" }

#check not_origin
-- not_origin : vector string

#check not_origin.y
-- not_origin.y : string

#eval not_origin.y
-- "Hello, World!"

/-*
----

Generic types are supported by many popular languages. They're extremely helpful in writing reusable code.
*-/

end generic

/-*
---

<!-- .slide: class="center" -->

# Chapter 3 : Generalized Algebraic Data Types

----

Let's briefly look at generalized algebraic data types, or GADTs for short.
GADTs are generic inductive types where different constructors return different types.
*-/

namespace gadt

/-*
----

If we were writing a parser for some language, one of the types we might want is a type for literal expressions.
*-/

-- These are placeholder definitions
constant float : Type
constant regex : Type
constant date : Type

inductive literal : Type -> Type
| numeric (n : float) : literal float -- e.g. 3.14
| string (s : string) : literal string -- e.g. "Hello, World!"
| regex (r : regex) : literal regex -- e.g. /.+@.+\..+/
| date (d : date) : literal date -- e.g. #2000-01-01#

#check literal
-- literal : Type -> Type

/-*
Instead of having four different types for each kind of literal,
we can have a single type that can represent any literal expression.

----

`literal` does not restrict what types you can pass to it.
*-/

-- This is cool, we defined a constructor for this.
#check literal string
-- literal string : Type

-- We didn't define a constructor for this.
#check literal (list int)
-- literal (list int) : Type

/-*
Even though `literal (list int)` is a real type, it has no constructors. There is no way to create a value of that type.
Every literal expression is one of only four kinds.

----

GADTs let us restrict the kinds of values a type can have.
This is necessary for some more advanced types, as we'll soon see.
*-/

end gadt

/-*
---

<!-- .slide: class="center" -->

# Chapter 4: Dependent Types

----

Generic types are constructed from other types. However, we can also define types that are constructed from values.
These are called dependent types.
*-/

namespace dependent

/-*
----

## Dependent Inductive Types

The classic example of a dependent type is a vector. A vector is like a list with a fixed length.
*-/

inductive vector (a : Type) : nat -> Type
| empty : vector 0
| make {n : nat} (head : a) (tail : vector n) : vector (n + 1)

#check vector
-- vector : Type -> nat -> Type

#check vector int 5
-- vector int 5 : Type

/-*
Like a generic type, `vector` is a function returning a type.

A `vector int 5` is a list of exactly 5 ints.

----
*-/

#check vector.make 42 vector.empty
-- vector.make 42 vector.empty : vector nat (0 + 1)

/-*
By adding an item to the empty vector (length 0), we get a vector of length 0 + 1.

`vector` is a GADT. The only way to make a 0-vector is with `vector.empty`,
and the only way to make an n+1-vector is by adding a value to an n-vector with `vector.make`.

----

## Dependent Records
*-/

structure n_vector := (n : nat) (vec : vector int n)

#check n_vector
-- n_vector : Type

/-*
This is a type consisting of a nat and a vector of that length.
This turns out to be equivalent to a list, but this time the length is stored as part of the data structure.

----

## Dependent Functions
*-/

def vector_builder := forall (n : nat), vector int n

#check vector_builder
-- vector_builder : Type

/-*
`forall` is the way to write dependent function types, much like `->` is used for ordinary function types.

This is a type representing functions that accept a nat and return a vector of that length.

----
*-/

def origin : vector_builder
| 0 := vector.empty
| (n + 1) := vector.make 0 (origin n)

#check origin
-- origin : vector_builder

#check origin 3
-- origin 3 : vector int 3

/-*
This function returns the zero vector for any given number of dimensions.
For example, `origin 3` is the vector (0, 0, 0).

----

Dependent types are an even more powerful than generic types, and can be used to make some very specific types.
*-/

end dependent

/-*
---

<!-- .slide: class="center" -->

# Chapter 5 : Propositions

----

Propositions are statements of fact that have a truth value. 1 + 1 = 2 is true, and 2 + 2 = 1 is false.
We can write propositions about our code that let us reason about its behaviour.
*-/

#check 1 + 1 = 2
-- 1 + 1 = 2 : Prop

#check 10 > 100
-- 10 > 100 : Prop

/-*
This looks a lot like a boolean. The problem with booleans is that they don't carry any information.

As it turns out, we can implement propositions as dependent types.
Values of those types are evidence (or proofs). They carry information about *why* the proposition is true.
A false proposition has no evidence, and so its type has no values.
*-/

namespace proposition

/-*
----

We can define propositions in the same way we define types, but by using `Prop` instead of `Type`.
*-/

inductive even : nat -> Prop
| zero : even 0
| plus_two {n : nat} (h : even n) : even (n + 2)

/-*
This defines what it means for a natural number to be even, by defining what kind of evidence is possible.
`even.zero` is evidence that 0 is even.
`even.plus_two` takes evidence that `n` is even and produces evidence that `n + 2` is even.

----
*-/

#check even 1
-- even 1 : Prop

def even_2 := even.plus_two even.zero

#check even_2
-- even_2 : even (0 + 2)

/-*
`even_2` is a value of type `even 2`. It's evidence that 2 is even.

There is no way to construct a value of type `even 1`. There can never be evidence that 1 is even.

----

The is how to define the proposition that a list contains some value.
*-/

inductive contains {a : Type} : a -> generic.list a -> Prop
| head (x : a) (xs : generic.list a) : contains x (generic.list.make x xs)
| tail (x : a) (y : a) (xs : generic.list a) (h : contains x xs)
  : contains x (generic.list.make y xs)

/-*
`contains.head` is evidence that a list beginning with some value contains that value.
`contains.tail` takes evidence that a list contains some value,
and produces evidence that a bigger list made from that list contains the same value.

There is no value of type `contains x list.empty`. There can never be evidence that the empty list contains any value.

----
*-/

#check contains 5
-- contains 5 : generic.list nat -> Prop

#check contains "Hello" generic.list.empty
-- contains "Hello" generic.list.empty : Prop

/-*
`contains x` is a function that accepts a list and returns a proposition (whether the list contains `x`).

----

Probably the most useful kind of proposition is equality.
*-/

inductive equals {a : Type} : a -> a -> Prop
| reflexive (x : a) : equals x x

#check equals.reflexive 42
-- equals.reflexive 42 : equals 42 42

/-*
This is pretty much how the `=` operator is implemented in Lean.
The only kind of evidence that `a = b` is by having `a` and `b` be the same thing.
If they weren't the same thing, they wouldn't be equal.

----

Proposition types let us store evidence for facts about our data,
which makes it possible to guarantee certain requirements at compile time.
*-/

end proposition

/-*
---

<!-- .slide: class="center" -->

# Chapter 6: Making Illegal States Unrepresentable

----

One way we can make it easier to write bug-free code is to make it impossible to create invalid data.
Something simple like using unsigned integers for values that are not allowed to be negative can prevent bugs.

Most of the time it's possible to create types where every possible value is meaningful and valid,
avoiding the need to write code checking for invalid values.
*-/

namespace making_illegal_states_unrepresentable

/-*
----

Most programmers know about `NullReferenceException`, `NullPointerException`,
or some such error caused by that infamous value, null.
Tony Hoare called the invention of null references his
["billion dollar mistake"](https://www.youtube.com/watch?v=YYkOWzrO3xg).

In Lean and many other functional languages, there is no concept of null.
If you want an optional value, you must explicitly say so at compile time, using the generic `option` type.
*-/

inductive option (a : Type)
| none : option
| some (x : a) : option

/-*
Values of an `option` type are either `some` value, or `none`.
*-/

def optional_int_1 : option int := option.some 42
def optional_int_2 : option int := option.none

/-*
Importantly, `option` variables cannot be used as if they are non-optional variables,
like nullable variables can in many languages.

----

Another common problem is `IndexOutOfRangeException` or `IndexOutOfBoundsException`,
caused by using a number which isn't a valid index into a list.
We can solve this with the `fin` dependent type, allowing us to restrict a number to a finite bound.
*-/

structure fin (n : nat) := (x : nat) (h : x < n)

/-*
`fin 5` is the type representing numbers less than five, that is, zero through four.
It's impossible to represent a number five or greater,
because every number comes with evidence that it is less than five.

This can be used to make an indexer function that has compile-time bounds checking.
*-/

constant element_at {a : Type} (l : list a) (i : fin l.length) : a

/-*
A function with this type accepts a list and a number less than the length of the list, which is always a valid index.
Unfortunately, most of the time evidence like this must be created manually,
because the compiler isn't always smart enough to create it automatically.

----

Here are more examples of problems that could be caught at compile time by using dependent types and/or propositions:

- Trying to get the first item of an empty list - require evidence that the list's length is greater than zero.
- Division by zero - require evidence that the denominator is not equal to zero.
- Binary search on an unsorted list - require evidence that the list is sorted.
- Passing the wrong number or wrong type of arguments to a string formatting function
(e.g. `string.Format` or `sprintf`) -
use a dependent function to make the function require the correct arguments based on the format string.
Brian McKenna has [a demonstration](https://www.youtube.com/watch?v=fVBck2Zngjo).
*-/

end making_illegal_states_unrepresentable

/-*
---

<!-- .slide: class="center" -->

# Epilogue: So What?

----

I'm not trying to tell you that dependent types are the solution to all your problems.
I'm not even trying to tell you to learn a dependently typed language.

I just want you to be aware of some of the patterns that exist to make code more reliable using a good type system.

Strong typing is your friend. Use it. Your compiler might not thank you, but your future self will.

----

If you're interested in learning more about type systems or dependent types, I have some suggestions.

- If you want to learn functional programming and some of the simpler concepts I showed,
[Haskell](https://www.haskell.org/) is very good at this.
- If you want to try writing programs using dependent types, [Idris](https://www.idris-lang.org/) is a practical option.
It's very similar to Haskell, but with dependent types.
- If you want to learn more about type theory and how mathematicians use dependent types to write and verify
mathematical proofs, I suggest trying [Lean](https://leanprover.github.io/), the language I've been using throughout.

----

If you want to try the code samples for yourself, the source code for this slideshow is at
https://example.com/insert-link-here.

---

<!-- .slide: class="center" -->

# Thank You
*-/