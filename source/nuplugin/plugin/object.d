/**
    NuPlugin Plugin Interface

    Copyright:
        Copyright © 2025, Kitsunebi Games
        Copyright © 2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nuplugin.plugin.object;
import nuplugin.object;
import numem;

version(IsPlugin):

/**
    Implementation of a INuObject interface.
*/
abstract
class NuObjectEx : NuObject, INuObject {
@nogc:
private:
    uint refcount = 0;

public:
    
    /**
        Constructor
    */
    this() @safe @nogc nothrow {
        refcount = 1;
    }

    /**
        Queries the interface whether it supports the given
        name.

        Params:
            name = The name to query, in reverse domain notation.
        
        Returns:
            A pointer to the requested object, or $(D null)
            if the interface isn't compatible.
    */
    extern(C)
    void* query(string name) @trusted {
        if (name == __nameof!INuObject)
            return cast(void*)this;
        
        return null;
    }

    /**
        Retains a reference to a valid object.

        Notes:
            The object validity is determined by the refcount.
            Uninitialized refcounted classes will be invalid.
            As such, releasing an invalid object will not
            invoke the destructor of said object.
    */
    extern(C)
    INuObject retain() @trusted {
        refcount++;
        return this;
    }

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
    extern(C)
    INuObject release() @trusted {
        if (refcount > 0) {
            refcount--;

            if (refcount == 0) {
                NuObjectEx self = this;
                nogc_delete(self);
                return null;
            }
        }
        return this;
    }
}