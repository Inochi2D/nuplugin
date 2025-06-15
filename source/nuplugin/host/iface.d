/**
    NuPlugin Host Interface

    Copyright:
        Copyright © 2025, Kitsunebi Games
        Copyright © 2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nuplugin.host.iface;
import nuplugin;

/**
    Base Host Object.

    This object is owned by the host, so there's no
    refcounting.
*/
@ObjectName("IHost")
interface IHost : IUnknown {
extern(C) @nogc:

    /**
        Finds an object within the plugins, searched by namespace and name.
        Eg. `com.test.MyPlugin.SomeObject`, then tries to create an instance
        of it.

        Params:
            name = Full name of the object to find.
        
        Returns:
            A reference to the object matching the given name,
            otherwise $(D null);
    */
    INuObject createObject(string name);
    
    /**
        Finds an object within the plugins, searched by namespace and name.
        Eg. `com.test.MyPlugin.SomeObject`, then tries to create an instance
        of it; casting it to the requested interface, if possible.

        Params:
            name = Full name of the object to find.
        
        Returns:
            A reference to the PluginObject matching the given name,
            otherwise $(D null);
    */
    pragma(inline, true)
    T createObject(T)(string name) if (is(T : INuObject)) {
        if (auto pobj = this.createObject(name)) {
                if (auto robj = pobj.query!T()) {
                    return robj;
                }
                
                // Not the correct kind of object.
                pobj.release();
        }
        return null;
    }
}