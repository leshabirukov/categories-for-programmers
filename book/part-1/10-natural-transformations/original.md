## Polymorphic Functions

We talked about the role of functors (or, more specifically, endofunctors) in programming. They correspond to type constructors that map types to types. They also map functions to functions, and this mapping is implemented by a higher order function `fmap` (or `transform`, `then`, and the like in C++).

To construct a natural transformation we start with an object, here a type, `a`. One functor, `F`, maps it to the type `F a`. Another functor, `G`, maps it to `G a`. The component of a natural transformation `alpha` at `a` is a function from `F a` to `G a`. In pseudo-Haskell:

```
alpha<sub>a</sub> :: F a -> G a
```

A natural transformation is a polymorphic function that is defined for all types `a`:

```
alpha :: forall a . F a -> G a
```

The `forall a` is optional in Haskell (and in fact requires turning on the language extension `ExplicitForAll`). Normally, you would write it like this:

```
alpha :: F a -> G a
```

Keep in mind that it's really a family of functions parameterized by `a`. This is another example of the terseness of the Haskell syntax. A similar construct in C++ would be slightly more verbose:

```
template<class A> G<A> alpha(F<A>);
```

There is a more profound difference between Haskell's polymorphic functions and C++ generic functions, and it's reflected in the way these functions are implemented and type-checked. In Haskell, a polymorphic function must be defined uniformly for all types. One formula must work across all types. This is called *parametric polymorphism*.

C++, on the other hand, supports by default *ad hoc polymorphism*, which means that a template doesn't have to be well-defined for all types. Whether a template will work for a given type is decided at instantiation time, where a concrete type is substituted for the type parameter. Type checking is deferred, which unfortunately often leads to incomprehensible error messages.

In C++, there is also a mechanism for function overloading and template specialization, which allows different definitions of the same function for different types. In Haskell this functionality is provided by type classes and type families.

Haskell's parametric polymorphism has an unexpected consequence: any polymorphic function of the type:

```
alpha :: F a -> G a
```

where `F` and `G` are functors, automatically satisfies the naturality condition. Here it is in categorical notation (`f` is a function `f::a->b`):

```
G f ∘ α<sub>a</sub> = α<sub>b</sub> ∘ F f
```

In Haskell, the action of a functor `G` on a morphism `f` is implemented using `fmap`. I'll first write it in pseudo-Haskell, with explicit type annotations:

```
fmap<sub>G</sub> f . alpha<sub>a</sub> = alpha<sub>b</sub> . fmap<sub>F</sub> f
```

Because of type inference, these annotations are not necessary, and the following equation holds:

```
fmap f . alpha = alpha . fmap f
```

This is still not real Haskell — function equality is not expressible in code — but it's an identity that can be used by the programmer in equational reasoning; or by the compiler, to implement optimizations.

The reason why the naturality condition is automatic in Haskell has to do with &#8220;theorems for free.&#8221; Parametric polymorphism, which is used to define natural transformations in Haskell, imposes very strong limitations on the implementation &#8212; one formula for all types. These limitations translate into equational theorems about such functions. In the case of functions that transform functors, free theorems are the naturality conditions. [You may read more about free theorems in my blog <a title="Parametricity: Money for Nothing and Theorems for Free" href="https://bartoszmilewski.com/2014/09/22/parametricity-money-for-nothing-and-theorems-for-free/" target="_blank">Parametricity: Money for Nothing and Theorems for Free</a>.]

One way of thinking about functors in Haskell that I mentioned earlier is to consider them generalized containers. We can continue this analogy and consider natural transformations to be recipes for repackaging the contents of one container into another container. We are not touching the items themselves: we don't modify them, and we don't create new ones. We are just copying (some of) them, sometimes multiple times, into a new container.

The naturality condition becomes the statement that it doesn't matter whether we modify the items first, through the application of `fmap`, and repackage later; or repackage first, and then modify the items in the new container, with its own implementation of `fmap`. These two actions, repackaging and `fmap`ping, are orthogonal. &#8220;One moves the eggs, the other boils them.&#8221;

Let’s see a few examples of natural transformations in Haskell. The first is between the list functor, and the `Maybe` functor. It returns the head of the list, but only if the list is non-empty:

```
safeHead :: [a] -> Maybe a
safeHead [] = Nothing
safeHead (x:xs) = Just x
```

It’s a function polymorphic in `a`. It works for any type `a`, with no limitations, so it is an example of parametric polymorphism. Therefore it is a natural transformation between the two functors. But just to convince ourselves, let’s verify the naturality condition.

```
fmap f . safeHead = safeHead . fmap f
```

We have two cases to consider; an empty list:

```
fmap f (safeHead []) = fmap f Nothing = Nothing
```

```
safeHead (fmap f []) = safeHead [] = Nothing
```

and a non-empty list:

```
fmap f (safeHead (x:xs)) = fmap f (Just x) = Just (f x)
```

```
safeHead (fmap f (x:xs)) = safeHead (f x : fmap f xs) = Just (f x)
```

I used the implementation of `fmap` for lists:

```
fmap f [] = []
fmap f (x:xs) = f x : fmap f xs
```

and for `Maybe`:

```
fmap f Nothing = Nothing
fmap f (Just x) = Just (f x)
```

An interesting case is when one of the functors is the trivial `Const` functor. A natural transformation from or to a `Const` functor looks just like a function that’s either polymorphic in its return type or in its argument type.

For instance, `length` can be thought of as a natural transformation from the list functor to the `Const Int` functor:

```
length :: [a] -> Const Int a
length [] = Const 0
length (x:xs) = Const (1 + unConst (length xs))
```

Here, `unConst` is used to peel off the `Const` constructor:

```
unConst :: Const c a -> c
unConst (Const x) = x
```

Of course, in practice `length` is defined as:

```
length :: [a] -> Int
```

which effectively hides the fact that it's a natural transformation.

Finding a parametrically polymorphic function *from* a `Const` functor is a little harder, since it would require the creation of a value from nothing. The best we can do is:

```
scam :: Const Int a -> Maybe a
scam (Const x) = Nothing
```

Another common functor that we've seen already, and which will play an important role in the Yoneda lemma, is the `Reader` functor. I will rewrite its definition as a `newtype`:

```
newtype Reader e a = Reader (e -> a)
```

It is parameterized by two types, but is (covariantly) functorial only in the second one:

```
instance Functor (Reader e) where  
    fmap f (Reader g) = Reader (\x -> f (g x))
```

For every type `e`, you can define a family of natural transformations from `Reader e` to any other functor `f`. We'll see later that the members of this family are always in one to one correspondence with the elements of `f e` (the <a href="https://bartoszmilewski.com/2015/09/01/the-yoneda-lemma/" target="_blank">Yoneda lemma</a>).

For instance, consider the somewhat trivial unit type `()` with one element `()`. The functor `Reader ()` takes any type `a` and maps it into a function type `()->a`. These are just all the functions that pick a single element from the set `a`. There are as many of these as there are elements in `a`. Now let's consider natural transformations from this functor to the `Maybe` functor:

```
alpha :: Reader () a -> Maybe a
```

There are only two of these, `dumb` and `obvious`:

```
dumb (Reader _) = Nothing
```

and

```
obvious (Reader g) = Just (g ())
```

(The only thing you can do with `g` is to apply it to the unit value `()`.)

And, indeed, as predicted by the Yoneda lemma, these correspond to the two elements of the `Maybe ()` type, which are `Nothing` and `Just ()`. We'll come back to the Yoneda lemma later — this was just a little teaser.

## Beyond Naturality

A parametrically polymorphic function between two functors (including the edge case of the `Const` functor) is always a natural transformation. Since all standard algebraic data types are functors, any polymorphic function between such types is a natural transformation.

We also have function types at our disposal, and those are functorial in their return type. We can use them to build functors (like the `Reader` functor) and define natural transformations that are higher-order functions.

However, function types are not covariant in the argument type. They are *contravariant*. Of course contravariant functors are equivalent to covariant functors from the opposite category. Polymorphic functions between two contravariant functors are still natural transformations in the categorical sense, except that they work on functors from the opposite category to Haskell types.

You might remember the example of a contravariant functor we've looked at before:

```
newtype Op r a = Op (a -> r)
```

This functor is contravariant in `a`:

```
instance Contravariant (Op r) where
    contramap f (Op g) = Op (g . f)
```

We can write a polymorphic function from, say, `Op Bool` to `Op String`:

```
predToStr (Op f) = Op (\x -> if f x then "T" else "F")
```

But since the two functors are not covariant, this is not a natural transformation in **Hask**. However, because they are both contravariant, they satisfy the &#8220;opposite&#8221; naturality condition:

```
contramap f . predToStr = predToStr . contramap f
```

Notice that the function `f` must go in the opposite direction than what you'd use with `fmap`, because of the signature of `contramap`:

```
contramap :: (b -> a) -> (Op Bool a -> Op Bool b)
```

Are there any type constructors that are not functors, whether covariant or contravariant? Here's one example:

```
a -> a
```

This is not a functor because the same type `a` is used both in the negative (contravariant) and positive (covariant) position. You can't implement `fmap` or `contramap` for this type. Therefore a function of the signature:

```
(a -> a) -> f a
```

where `f` is an arbitrary functor, cannot be a natural transformation. Interestingly, there is a generalization of natural transformations, called dinatural transformations, that deals with such cases. We'll get to them when we discuss ends.

## Functor Category

Now that we have mappings between functors &#8212; natural transformations &#8212; it's only natural to ask the question whether functors form a category. And indeed they do! There is one category of functors for each pair of categories, C and D. Objects in this category are functors from C to D, and morphisms are natural transformations between those functors.

We have to define composition of two natural transformations, but that's quite easy. The components of natural transformations are morphisms, and we know how to compose morphisms.

Indeed, let's take a natural transformation α from functor F to G. Its component at object `a` is some morphism:

```
α<sub>a</sub> :: F a -> G a
```

We'd like to compose α with β, which is a natural transformation from functor G to H. The component of β at `a` is a morphism:

```
β<sub>a</sub> :: G a -> H a
```

These morphisms are composable and their composition is another morphism:

```
β<sub>a</sub> ∘ α<sub>a</sub> :: F a -> H a
```

We will use this morphism as the component of the natural transformation β ⋅ α &#8212; the composition of two natural transformations β after α:

```
(β ⋅ α)<sub>a</sub> = β<sub>a</sub> ∘ α<sub>a</sub>
```

<a href="https://bartoszmilewski.files.wordpress.com/2015/04/5_vertical.jpg"><img class="alignnone wp-image-4351 size-medium" src="https://bartoszmilewski.files.wordpress.com/2015/04/5_vertical.jpg?w=300&#038;h=203" alt="5_Vertical" width="300" height="203" /></a>

One (long) look at a diagram convinces us that the result of this composition is indeed a natural transformation from F to H:

```
H f ∘ (β ⋅ α)<sub>a</sub> = (β ⋅ α)<sub>b</sub> ∘ F f
```

<a href="https://bartoszmilewski.files.wordpress.com/2015/04/6_verticalnaturality.jpg"><img class="alignnone wp-image-4352 size-medium" src="https://bartoszmilewski.files.wordpress.com/2015/04/6_verticalnaturality.jpg?w=300&#038;h=291" alt="6_VerticalNaturality" width="300" height="291" /></a>

Composition of natural transformations is associative, because their components, which are regular morphisms, are associative with respect to their composition.

Finally, for each functor F there is an identity natural transformation 1<sub>F</sub> whose components are the identity morphisms:

```
id<sub>F a</sub> :: F a -> F a
```

So, indeed, functors form a category.

A word about notation. Following Saunders Mac Lane I use the dot for the kind of natural transformation composition I have just described. The problem is that there are two ways of composing natural transformations. This one is called the vertical composition, because the functors are usually stacked up vertically in the diagrams that describe it. Vertical composition is important in defining the functor category. I'll explain horizontal composition shortly.

<a href="https://bartoszmilewski.files.wordpress.com/2015/04/6a_vertical.jpg"><img class="alignnone wp-image-4353 " src="https://bartoszmilewski.files.wordpress.com/2015/04/6a_vertical.jpg?w=220&#038;h=145" alt="6a_Vertical" width="220" height="145" /></a>

The functor category between categories C and D is written as `Fun(C, D)`, or `[C, D]`, or sometimes as `D<sup>C</sup>`. This last notation suggests that a functor category itself might be considered a function object (an exponential) in some other category. Is this indeed the case?

Let's have a look at the hierarchy of abstractions that we've been building so far. We started with a category, which is a collection of objects and morphisms. Categories themselves (or, strictly speaking *small* categories, whose objects form sets) are themselves objects in a higher-level category **Cat**. Morphisms in that category are functors. A Hom-set in **Cat** is a set of functors. For instance Cat(C, D) is a set of functors between two categories C and D.

<a href="https://bartoszmilewski.files.wordpress.com/2015/04/7_cathomset.jpg"><img class="alignnone wp-image-4354 " src="https://bartoszmilewski.files.wordpress.com/2015/04/7_cathomset.jpg?w=215&#038;h=211" alt="7_CatHomSet" width="215" height="211" /></a>

A functor category [C, D] is also a set of functors between two categories (plus natural transformations as morphisms). Its objects are the same as the members of Cat(C, D). Moreover, a functor category, being a category, must itself be an object of **Cat** (it so happens that the functor category between two small categories is itself small). We have a relationship between a Hom-set in a category and an object in the same category. The situation is exactly like the exponential object that we've seen in the last section. Let's see how we can construct the latter in **Cat**.

As you may remember, in order to construct an exponential, we need to first define a product. In **Cat**, this turns out to be relatively easy, because small categories are *sets* of objects, and we know how to define cartesian products of sets. So an object in a product category C × D is just a pair of objects, `(c, d)`, one from C and one from D. Similarly, a morphism between two such pairs, `(c, d)` and `(c', d')`, is a pair of morphisms, `(f, g)`, where `f :: c -> c'` and `g :: d -> d'`. These pairs of morphisms compose component-wise, and there is always an identity pair that is just a pair of identity morphisms. To make the long story short, **Cat** is a full-blown cartesian closed category in which there is an exponential object D<sup>C</sup> for any pair of categories. And by &#8220;object&#8221; in **Cat** I mean a category, so D<sup>C</sup> is a category, which we can identify with the functor category between C and D.

## 2-Categories

With that out of the way, let's have a closer look at **Cat**. By definition, any Hom-set in **Cat** is a set of functors. But, as we have seen, functors between two objects have a richer structure than just a set. They form a category, with natural transformations acting as morphisms. Since functors are considered morphisms in **Cat**, natural transformations are morphisms between morphisms.

This richer structure is an example of a 2-category, a generalization of a category where, besides objects and morphisms (which might be called 1-morphisms in this context), there are also 2-morphisms, which are morphisms between morphisms.

In the case of **Cat** seen as a 2-category we have:

<ul>
<li>Objects: (Small) categories</li>
<li>1-morphisms: Functors between categories</li>
<li>2-morphisms: Natural transformations between functors.</li>
</ul>
Instead of a Hom-set between two categories C and D, we have a Hom-category &#8212; the functor category D<sup>C</sup>. We have regular functor composition: a functor F from D<sup>C</sup> composes with a functor G from E<sup>D</sup> to give G ∘ F from E<sup>C</sup>. But we also have composition inside each Hom-category &#8212; vertical composition of natural transformations, or 2-morphisms, between functors.

<a href="https://bartoszmilewski.files.wordpress.com/2015/04/8_cat-2-cat.jpg"><img class="alignnone wp-image-4355 " src="https://bartoszmilewski.files.wordpress.com/2015/04/8_cat-2-cat.jpg?w=216&#038;h=172" alt="8_Cat-2-Cat" width="216" height="172" /></a>

With two kinds of composition in a 2-category, the question arises: How do they interact with each other?

Let's pick two functors, or 1-morphisms, in **Cat**:

```
F :: C -> D
G :: D -> E
```

and their composition:

```
G ∘ F :: C -> E
```

Suppose we have two natural transformations, α and β, that act, respectively, on functors F and G:

```
α :: F -> F'
β :: G -> G'
```

<a href="https://bartoszmilewski.files.wordpress.com/2015/04/10_horizontal.jpg"><img class="alignnone wp-image-4357 size-medium" src="https://bartoszmilewski.files.wordpress.com/2015/04/10_horizontal.jpg?w=300&#038;h=166" alt="10_Horizontal" width="300" height="166" /></a>

Notice that we cannot apply vertical composition to this pair, because the target of α is different from the source of β. In fact they are members of two different functor categories: D <sup>C</sup> and E <sup>D</sup>. We can, however, apply composition to the functors F' and G', because the target of F' is the source of G' &#8212; it's the category D. What's the relation between the functors G'∘ F' and G ∘ F?

Having α and β at our disposal, can we define a natural transformation from G ∘ F to G'∘ F'? Let me sketch the construction.

<a href="https://bartoszmilewski.files.wordpress.com/2015/04/9_horizontal.jpg"><img class="alignnone wp-image-4356 " src="https://bartoszmilewski.files.wordpress.com/2015/04/9_horizontal.jpg?w=369&#038;h=268" alt="9_Horizontal" width="369" height="268" /></a>

As usual, we start with an object `a` in C. Its image splits into two objects in D: `F a` and `F'a`. There is also a morphism, a component of α, connecting these two objects:

```
α<sub>a</sub> :: F a -> F'a
```

When going from D to E, these two objects split further into four objects:

```
G (F a), G'(F a), G (F'a), G'(F'a)
```

We also have four morphisms forming a square. Two of these morphisms are the components of the natural transformation β:

```
β<sub>F a</sub> :: G (F a) -> G'(F a)
β<sub>F'a</sub> :: G (F'a) -> G'(F'a)
```

The other two are the images of α<sub>a</sub> under the two functors (functors map morphisms):

```
G α<sub>a</sub> :: G (F a) -> G (F'a)
G'α<sub>a</sub> :: G'(F a) -> G'(F'a)
```

That's a lot of morphisms. Our goal is to find a morphism that goes from `G (F a)` to `G'(F'a)`, a candidate for the component of a natural transformation connecting the two functors G ∘ F and G'∘ F'. In fact there's not one but two paths we can take from `G (F a)` to `G'(F'a)`:

```
G'α<sub>a</sub> ∘ β<sub>F a</sub>
β<sub>F'a</sub> ∘ G α<sub>a</sub>
```

Luckily for us, they are equal, because the square we have formed turns out to be the naturality square for β.

We have just defined a component of a natural transformation from G ∘ F to G'∘ F'. The proof of naturality for this transformation is pretty straightforward, provided you have enough patience.

We call this natural transformation the *horizontal composition* of α and β:

```
β ∘ α :: G ∘ F -> G'∘ F'
```

Again, following Mac Lane I use the small circle for horizontal composition, although you may also encounter star in its place.

Here's a categorical rule of thumb: Every time you have composition, you should look for a category. We have vertical composition of natural transformations, and it's part of the functor category. But what about the horizontal composition? What category does that live in?

The way to figure this out is to look at **Cat** sideways. Look at natural transformations not as arrows between functors but as arrows between categories. A natural transformation sits between two categories, the ones that are connected by the functors it transforms. We can think of it as connecting these two categories.

<a href="https://bartoszmilewski.files.wordpress.com/2015/04/sideways.jpg"><img class="alignnone size-medium wp-image-4375" src="https://bartoszmilewski.files.wordpress.com/2015/04/sideways.jpg?w=300&#038;h=87" alt="Sideways" width="300" height="87" /></a>

Let's focus on two objects of **Cat** &#8212; categories C and D. There is a set of natural transformations that go between functors that connect C to D. These natural transformations are our new arrows from C to D. By the same token, there are natural transformations going between functors that connect D to E, which we can treat as new arrows going from D to E. Horizontal composition is the composition of these arrows.

We also have an identity arrow going from C to C. It's the identity natural transformation that maps the identity functor on C to itself. Notice that the identity for horizontal composition is also the identity for vertical composition, but not vice versa.

Finally, the two compositions satisfy the interchange law:

```
(β' ⋅ α') ∘ (β ⋅ α) = (β' ∘ β) ⋅ (α' ∘ α)
```

I will quote Saunders Mac Lane here: The reader may enjoy writing down the evident diagrams needed to prove this fact.

There is one more piece of notation that might come in handy in the future. In this new sideways interpretation of **Cat** there are two ways of getting from object to object: using a functor or using a natural transformation. We can, however, re-interpret the functor arrow as a special kind of natural transformation: the identity natural transformation acting on this functor. So you'll often see this notation:

```
F ∘ α
```

where F is a functor from D to E, and α is a natural transformation between two functors going from C to D. Since you can't compose a functor with a natural transformation, this is interpreted as a horizontal composition of the identity natural transformation 1<sub>F</sub> after α.

Similarly:

```
α ∘ F
```

is a horizontal composition of α after 1<sub>F</sub>.

## Conclusion

This concludes the first part of the book. We've learned the basic vocabulary of category theory. You may think of objects and categories as nouns; and morphisms, functors, and natural transformations as verbs. Morphisms connect objects, functors connect categories, natural transformations connect functors.

But we've also seen that, what appears as an action at one level of abstraction, becomes an object at the next level. A set of morphisms turns into a function object. As an object, it can be a source or a target of another morphism. That's the idea behind higher order functions.

A functor maps objects to objects, so we can use it as a type constructor, or a parametric type. A functor also maps morphisms, so it is a higher order function &#8212; `fmap`. There are some simple functors, like `Const`, product, and coproduct, that can be used to generate a large variety of algebraic data types. Function types are also functorial, both covariant and contravariant, and can be used to extend algebraic data types.

Functors may be looked upon as objects in the functor category. As such, they become sources and targets of morphisms: natural transformations. A natural transformation is a special type of polymorphic function.

## Challenges

<ol>
<li>Define a natural transformation from the `Maybe` functor to the list functor. Prove the naturality condition for it.</li>
<li>Define at least two different natural transformations between `Reader ()` and the list functor. How many different lists of `()` are there?</li>
<li>Continue the previous exercise with `Reader Bool` and `Maybe`.</li>
<li>Show that horizontal composition of natural transformation satisfies the naturality condition (hint: use components). It's a good exercise in diagram chasing.</li>
<li>Write a short essay about how you may enjoy writing down the evident diagrams needed to prove the interchange law.</li>
<li>Create a few test cases for the opposite naturality condition of transformations between different `Op` functors. Here's one choice:
```
op :: Op Bool Int
op = Op (\x -> x > 0)
```

and

```
f :: String -> Int
f x = read x
```

</li>
</ol>
Next: <a title="Category Theory and Declarative Programming" href="https://bartoszmilewski.com/2015/04/15/category-theory-and-declarative-programming/">Declarative Programming</a>.

## Acknowledgments

I'd like to thank Gershom Bazerman for checking my math and logic, and André van Meulebrouck, who has been volunteering his editing help.<br />

