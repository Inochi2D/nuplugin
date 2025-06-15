/**
    The plugin interface.
*/
module plugin;
import nuplugin;

@ObjectName("IGreeter")
interface IGreeter : INuObject {
@nogc extern(C):
    string greet();
}

version(IsPlugin):

/**
    Our Greeter class.
*/
@ObjectName("Greeter")
class Greeter : NuObjectEx, IGreeter {
public:
@nogc:
    /**
        Queries the interface whether it supports the given
        name.

        Params:
            name = The name to query, in reverse domain notation.
        
        Returns:
            A pointer to the requested object, or $(D null)
            if the interface isn't compatible.
    */
    override
    extern(C) void* query(string name) {
        if (name == __nameof!IGreeter)
            return cast(void*)cast(IGreeter)this;

        return super.query(name);
    }

    /**
        Our greeter function, just returns hello world.
    */
    extern(C)
    string greet() { return "Hello, world!"; }
}

// Register our object and plugin.
mixin RegisterObject!(Greeter, IGreeter);
mixin RegisterPlugin!(nuplugin_info_t(
    namespace: "com.inochi2d.greeter",
    name: "Example Greeter",
    version_: "1.0.0",
    authors: ["Luna the Foxgirl"]
));