/**
    NuPlugin Host Interface

    Copyright:
        Copyright © 2025, Kitsunebi Games
        Copyright © 2025, Inochi2D Project
    
    License:   $(LINK2 http://www.boost.org/LICENSE_1_0.txt, Boost License 1.0)
    Authors:   Luna Nielsen
*/
module nuplugin.host.host;
import nuplugin.host.iface;
import nuplugin.tables;
import nuplugin.object;
import nulib.collections.vector;
import nulib.system.mod;
import nulib.string;
import numem;

version(IsHost):

/**
    A host for plugins, keeping track of which plugins are and aren't loaded.
*/
final
class PluginHost : NuRefCounted, IHost {
private:
@nogc:
    vector!Plugin loaded;

    // Helper that removes a plugin from the loaded list.
    void remove(Plugin plugin) {
        loaded.remove(plugin);
    }

public:
    
    /**
        Gets the plugins in the host.
    */
    @property Plugin[] plugins() {
        return loaded[];
    }

    /**
        Finds an object within the plugins, searched by namespace and name.
        Eg. `com.test.MyPlugin.SomeObject`.

        Params:
            name = Full name of the object to find.
        
        Returns:
            A reference to the PluginObject matching the given name,
            otherwise $(D null);
    */
    PluginObject* findObject(string name) {
        string nsName;
        string objName;
        foreach_reverse(i; 0..name.length) {
            if(name[i] == '.') {
                nsName = name[0..i];
                objName = name[i+1..$];
                break;
            }
        }

        // Invalid namespace or object.
        if (!nsName || !objName)
            return null;
        
        foreach(plugin; plugins) {
            if (plugin.namespace == nsName)
                return plugin.findObject(objName);
        }
        return null;
    }
    
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
    extern(C)
    INuObject createObject(string name) {
        if (auto pobjdesc = this.findObject(name)) {
            if (auto pobj = pobjdesc.create()) {
                return cast(INuObject)pobj;
            }
        }
        return null;
    }
    
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
    extern(C)
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

    /**
        Loads a plugin into the plugin host.

        Params:
            pathOrName = The path, bundle name or namespace of the plugin.
        
        Returns:
            A Plugin instance matching the given name, if the plugin is
            already loaded, that plugin, with its reference count increased
            by one will be returned, otherwise $(D null)
    */
    Plugin loadPlugin(string pathOrName) {
        foreach(plugin; plugins) {

            // Avoid creating multiple plugin instances.
            if (plugin.pathOrName == pathOrName)
                return plugin.retained;
            
            // We can search by namespace too.
            if (plugin.namespace == pathOrName)
                return plugin.retained;
        }

        if (Plugin plugin = Plugin.load(pathOrName)) {
            loaded ~= plugin;
            plugin.host = this;
            return plugin;
        }
        return null;
    }
}

/**
    A plugin implementing the NuPlugin specification.
*/
class Plugin : NuRefCounted {
private:
@nogc:
    PluginHost host;
    string pathOrName_;
    Module module_;
    nuplugin_info_t info_;
    PluginObject[] objects_;
    string[] authors_;
    
public:
    
    /**
        The path or bundle name of the plugin.
    */
    final
    @property string pathOrName() {
        return pathOrName_;
    }

    /**
        Namespace of the plugin, in reverse domain notation.
    */
    final
    @property string namespace() {
        return cast(string)info_.namespace[0..nu_strlen(info_.namespace)];
    }
    
    /**
        ABI version of the plugin.
    */
    final
    @property uint abi() {
        return info_.abi;
    }
    
    /**
        The name to display to the end user.
    */
    final
    @property string name() {
        return info_.name ? cast(string)info_.name[0..nu_strlen(info_.name)] : namespace;
    }
    
    /**
        The name to display to the end user.
    */
    final
    @property string copyright() {
        return info_.copyright ? cast(string)info_.copyright[0..nu_strlen(info_.copyright)] : null;
    }
        
    /**
        The version string to display to the end user.
    */
    @property string version_() { 
        return info_.version_ ? cast(string)info_.version_[0..nu_strlen(info_.version_)] : null;
    }
    
    /**
        The author list to display to end user.
    */
    @property string[] authors() { 
        return authors_;
    }

    /**
        The instantiable objects within the plugin.
    */
    final
    @property PluginObject[] objects() {
        return objects_;
    }

    /**
        Finds an object within the plugin.

        Params:
            name = The name of the object.
    */
    final
    PluginObject* findObject(string name) {
        foreach(ref object; objects_) {
            if (object.name == name)
                return &object;
        }

        return null;
    }

    /**
        Loads a plugin from a given path or bundle name.

        Params:
            pathOrName = The path and/or name of the library/bundle to load.
        
        Returns:
            A plugin if loading succeded and the prerequsite data was found, 
            $(D null) otherwise.
    */
    static Plugin load(string pathOrName) {
        if (Module mod = Module.load(pathOrName)) {
            SectionInfo* infSection = mod.findSection(MAKE_SECTION!NU_PLUGIN_INF_SECT);
            SectionInfo* objSection = mod.findSection(MAKE_SECTION!NU_PLUGIN_OBJ_SECT);

            // No inf section == not a plugin.
            // No obj section == not a plugin.
            if (!infSection || !objSection) {
                mod.release();
                return null;
            }

            // Get object listing.
            size_t objectSectionLength = (cast(size_t)objSection.end - cast(size_t)objSection.start);
            size_t objectCount = objectSectionLength/nuplugin_object_t.sizeof;
            nuplugin_object_t[] objects = (cast(nuplugin_object_t*)objSection.start)[0..objectCount];

            // Fill out plugin info
            Plugin plugin = nogc_new!Plugin;
            plugin.pathOrName_ = pathOrName.nu_dup();
            plugin.info_ = *cast(nuplugin_info_t*)infSection.start;
            plugin.objects_ = plugin.objects_.nu_resize(objects.length);
            foreach(i, ref object; plugin.objects_) {
                object = PluginObject(&objects[i]);
            }
            plugin.authors_ = plugin.authors_.nu_resize(plugin.info_.authors.length);
            foreach(i, ref author; plugin.authors_) {
                const(char)* authorRef = plugin.info_.authors[i];
                author = cast(string)authorRef[0..nu_strlen(authorRef)];
            }
            return plugin;
        }
        return null;
    }

    /*
        Destructor
    */
    ~this() {
        this.module_.release();
        this.objects_ = objects_.nu_resize(0);
        this.pathOrName_ = pathOrName_.nu_resize(0);
        this.authors_ = authors_.nu_resize(0);

        // Ask parent to remove us.
        if (host)
            host.remove(this);
    }
}

/**
    An object within a plugin.
*/
struct PluginObject {
private:
@nogc:
    nuplugin_object_t* object;

public:

    /**
        Instantiates the higher level plugin object type.
    */
    this(nuplugin_object_t* object) {
        this.object = object;
        this.name = cast(string)(
            object && object.name ? 
                object.name[0..nu_strlen(object.name)] :
                "Unknown"
        );
        this.protocol = cast(string)(
            object && object.protocol ? 
                object.protocol[0..nu_strlen(object.protocol)] :
                "IUnknown"
        );
    }

    /**
        Name of the plugin object
    */
    string name;

    /**
        Name of the plugin object
    */
    string protocol;

    /**
        Creates an instance of this object.
    */
    void* create() {
        return object ? object.create() : null;
    }
}