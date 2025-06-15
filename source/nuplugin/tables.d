/**
    NuPlugin Runtime Tables

    Copyright:
        Copyright © 2025, Kitsunebi Games
        Copyright © 2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nuplugin.tables;
import nuplugin.object;

/**
    The NuPlugin ABI version.

    This will be monotonically increased when the ABI changes.
*/
enum NU_PLUGIN_ABI = 1;

/**
    Section in which object descriptors are placed.
*/
enum NU_PLUGIN_OBJ_SECT = "nuobj";

/**
    Section in which the plugin descriptor is placed.
*/
enum NU_PLUGIN_INF_SECT = "nuinf";

/**
    Helper template which gets the platform specific section name
    for the given string.
*/
template MAKE_SECTION(string name) {

    // Apple OSes
    version (OSX)
        version = Darwin;
    else version (iOS)
        version = Darwin;
    else version (TVOS)
        version = Darwin;
    else version (WatchOS)
        version = Darwin;
    else version (VisionOS)
        version = Darwin;

    version(Darwin)
        enum MAKE_SECTION = ".__"~name;
    else version(Windows)
        enum MAKE_SECTION = "."~name;
    else version(Posix)
        enum MAKE_SECTION = "."~name;
    else static assert(false, "Support not yet added!");
}

/**
    Helper template which constructs a full segment-section string.
*/
template MAKE_SECTION_SEG(string name) {

    // Apple OSes
    version (OSX)
        version = Darwin;
    else version (iOS)
        version = Darwin;
    else version (TVOS)
        version = Darwin;
    else version (WatchOS)
        version = Darwin;
    else version (VisionOS)
        version = Darwin;

    version(Darwin)
        enum MAKE_SECTION_SEG = ".__DATA"~MAKE_SECTION!name~",no_strip_dead";
    else version(Windows)
        enum MAKE_SECTION_SEG = MAKE_SECTION!name;
    else version(Posix)
        enum MAKE_SECTION_SEG = MAKE_SECTION!name;
    else static assert(false, "Support not yet added!");
}

/**
    A description of a nuplugin object.
*/
extern(C)
struct nuplugin_object_t { // @suppress(dscanner.style.phobos_naming_convention)
extern(C) @nogc nothrow:
    
    /**
        Name of the object, padded with zeros.
    */
    const(char)* name;

    /**
        Name of the most derived protocol the object implements.
    */
    const(char)* protocol;

    /**
        Reference to a factory function which instantates the object.
    */
    void* function() create;
}


/**
    A description of a plugin, must exist for a plugin to be recognized
    as a valid NuPlugin plugin.
*/
extern(C)
struct nuplugin_info_t { // @suppress(dscanner.style.phobos_naming_convention)
    
    /**
        The namespace of the plugin.
    */
    const(char)* namespace;

    /**
        The ABI version in use.
    */
    uint abi;

    /**
        The name to display to the end user.
    */
    const(char)* name;

    /**
        The name to display to the end user.
    */
    const(char)* copyright;
        
    /**
        The version string to display to the end user.
    */
    const(char)* version_;
    
    /**
        The author list to display to end user.
    */
    const(char)*[] authors;
}