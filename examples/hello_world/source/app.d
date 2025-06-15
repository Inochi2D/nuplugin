module app;
import plugin;
import nuplugin;
import std.stdio;
import std.array : join;

version(IsHost)

void main() {
    PluginHost host = new PluginHost();
    if (!host.loadPlugin("hello_world.dll")) {
        writeln("Could not load plugin!");
        return;
    }
    
    foreach(i, plugin; host.plugins) {
        writefln("Plugin %s: %s (%s) by %s", i, plugin.name, plugin.version_, plugin.authors.join(", "));
        foreach(j, object; plugin.objects) {
            writefln("    - %s: %s.%s (implements %s)", j, plugin.namespace, object.name, object.protocol);
        }
    }

    if (IGreeter greeter = host.createObject!IGreeter("com.inochi2d.greeter.Greeter")) {
        writeln(greeter.greet());
        greeter.release();
    }
}