/**
    INuObject interface

    Copyright:
        Copyright © 2025, Kitsunebi Games
        Copyright © 2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nuplugin.object;

/**
    A name for an element within a plugin; names are expressed in
    reverse domain notation, eg. `com.inochi2d.numod.MyClass`.
*/
struct ObjectName { string name; }

/**
    Gets the $(D ObjectName) for the given type if possible.

    You can check if a type has a Name with a $(D is(__nameof!T)) expression.
*/
template __nameof(T) {
    import nuplugin.object : ObjectName;

    static foreach(attr; __traits(getAttributes, T)) {
        static if (is(typeof(attr) == ObjectName) && is(typeof(__nameof) == void))
            enum __nameof = attr.name;
    }
}

/**
    Gets whether $(D T) has a $(D ObjectName) attribute attached.
*/
enum hasName(T) = !is(typeof(__nameof!T) == void);

static assert(__traits(isCOMClass, INuObject), "INuObject no longer counts as COM class?");

/**
    A reference counted object in the plugin system
*/
@ObjectName("INuObject")
interface INuObject : IUnknown {
extern(C) @nogc:
    
    /**
        Queries the interface whether it supports the given
        name.

        Params:
            name = The name to query, in reverse domain notation.
        
        Returns:
            A pointer to the requested object, or $(D null)
            if the interface isn't compatible.
    */
    void* query(string name);

    /**
        Queries the interface whether it supports the given
        name.
        
        Returns:
            A pointer to the requested object, or $(D null)
            if the interface isn't compatible.
    */
    T query(T)() { return cast(T)query(__nameof!T); }

    /**
        Retains a reference to a valid object.

        Notes:
            The object validity is determined by the refcount.
            Uninitialized refcounted classes will be invalid.
            As such, releasing an invalid object will not
            invoke the destructor of said object.
    */
    IUnknown retain();
    
    /**
        Releases a reference from a valid object.

        Notes:
            The object validity is determined by the refcount.
            Uninitialized refcounted classes will be invalid.
            As such, releasing an invalid object will not
            invoke the destructor of said object.

        Returns:
            The class instance release was called on, $(D null) if
            the class was freed.
    */
    IUnknown release();
}

/**
    Base interface, taken from COM.

    Do note that this interface is NOT compatible with COM, it implements
    none of the base COM vtable.
*/
@ObjectName("IUnknown")
interface IUnknown { }