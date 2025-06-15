module nuplugin.plugin;
import nuplugin.tables;
import nuplugin.object;

public import nuplugin.plugin.object;

version(IsPlugin):
version(LDC):

/**
    Registers the plugin with the NuPlugin Runtime.

    Params:
        namespace = The namespace that the plugin uses.
*/
mixin template RegisterPlugin(string namespace) {
    import ldc.attributes : section;

    @section(MAKE_SECTION_SEG!NU_PLUGIN_INF_SECT)
    pragma(mangle, "_nuplugin_info")
    export __gshared nuplugin_info_t _nuplugin_info = nuplugin_info_t(
        namespace: namespace,
        abi: NU_PLUGIN_ABI
    );
}

/**
    Registers the plugin with the NuPlugin Runtime.

    Params:
        info = The plugin information.
*/
mixin template RegisterPlugin(nuplugin_info_t info) {
    import ldc.attributes : section;

    @section(MAKE_SECTION_SEG!NU_PLUGIN_INF_SECT)
    pragma(mangle, "_nuplugin_info")
    export __gshared nuplugin_info_t _nuplugin_info = nuplugin_info_t(
        namespace: info.namespace,
        abi: NU_PLUGIN_ABI,
        name: info.name,
        copyright: info.copyright,
        version_: info.version_,
        authors: info.authors
    );
}

/**
    Registers the given object with the NuPlugin Runtime.

    Params:
        ObjectT = The type of the object to register.
        InterfaceT = The type of the interface to register.

    Note:
        All exposed objects MUST conform to the INuObject ABI.
*/
mixin template RegisterObject(ObjectT, InterfaceT) {
    import ldc.attributes : section;
    import numem.lifetime : nogc_new;

    static assert(is(InterfaceT : INuObject), InterfaceT.stringof~" does not conform to the INuObject ABI!");
    static assert(is(ObjectT : InterfaceT), ObjectT.stringof~" does not implement "~InterfaceT.stringof~"!");
    static assert(is(typeof(() @nogc nothrow => nogc_new!ObjectT())), ObjectT.stringof~" can not be default constructed!");
    static assert(hasName!ObjectT, ObjectT.stringof~" has no name defined!");
    static assert(hasName!InterfaceT, InterfaceT.stringof~" has no name defined!");

    // NOTE:    The IUnknown cast here makes sure that the object is
    //          aligned to the interface; not the object itself.
    extern(C)
    alias factory = () => cast(void*)cast(IUnknown)nogc_new!ObjectT();

    pragma(mangle, "_nuplugin_obj_"~ObjectT.mangleof)
    @(section(MAKE_SECTION_SEG!NU_PLUGIN_OBJ_SECT))
    export __gshared nuplugin_object_t _nuplugin_object = nuplugin_object_t(
        name: __nameof!ObjectT,
        protocol: __nameof!InterfaceT,
        create: factory,
    );
}