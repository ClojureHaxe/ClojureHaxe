package lang;

import lang.*;

class Init {

    // https://github.com/HaxeFoundation/haxe/issues/10902
    // Initialization order
    // To initialize all static fields in class it is enough to make access to some static field
    // of that class

    public static function init():Bool {
        // trace("Static field initialization");
        PersistentHashMap.BitmapIndexedNode.EMPTY;
        PersistentHashMap.EMPTY;
        //trace("PersistentHashMap.EMPTY", PersistentHashMap.EMPTY);
        PersistentList.EMPTY;
        return true;
    }
}
