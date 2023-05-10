/*
 * Copyright (c) 2010-2022 OTClient <https://github.com/edubart/otclient>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#include "luainterface.h"
#include "luaobject.h"

#include <framework/core/resourcemanager.h>

LuaInterface g_lua;

void LuaInterface::init()
{
    createLuaState();

    // store global environment reference
    pushThread();
    getEnv();
    m_globalEnv = ref();
    pop();

    // check if demangle_class is working as expected
    assert(stdext::demangle_class<LuaObject>() == "LuaObject");

    // register LuaObject, the base of all other objects
    registerClass<LuaObject>();
    bindClassMemberFunction<LuaObject>("getClassName", &LuaObject::getClassName);

    registerClassMemberFunction<LuaObject>("getFieldsTable", [](LuaInterface*) -> int {
        const auto& obj = g_lua.popObject();
        obj->luaGetFieldsTable();
        return 1;
    });
}

void LuaInterface::terminate()
{
    // close lua state, it will release all objects
    closeLuaState();
    assert(m_totalFuncRefs == 0);
    assert(m_totalObjRefs == 0);
}

void LuaInterface::registerSingletonClass(const std::string_view className)
{
    newTable();
    pushValue();
    setGlobal(className);
    pop();
}

void LuaInterface::registerClass(const std::string_view className, const std::string_view baseClass)
{
    const auto* __className = className.data();

    // creates the class table (that it's also the class methods table)
    newTable();
    pushValue();
    setGlobal(className);
    const int klass = getTop();

    // creates the class fieldmethods table
    newTable();
    pushValue();
    setGlobal(__className + "_fieldmethods"s);
    const int klass_fieldmethods = getTop();

    // creates the class metatable
    newTable();
    pushValue();
    setGlobal(__className + "_mt"s);
    const int klass_mt = getTop();

    // set metatable metamethods
    pushCppFunction(&LuaInterface::luaObjectGetEvent);
    setField("__index", klass_mt);
    pushCppFunction(&LuaInterface::luaObjectSetEvent);
    setField("__newindex", klass_mt);
    pushCppFunction(&LuaInterface::luaObjectEqualEvent);
    setField("__eq", klass_mt);
    pushCppFunction(&LuaInterface::luaObjectCollectEvent);
    setField("__gc", klass_mt);

    // set some fields that will be used later in metatable
    pushValue(klass);
    setField("methods", klass_mt);
    pushValue(klass_fieldmethods);
    setField("fieldmethods", klass_mt);

    // redirect methods and fieldmethods to the base class ones
    if (!className.empty() && className != "LuaObject") {
        // the following code is what create classes hierarchy for lua, by reproducing:
        // DerivedClass = { __index = BaseClass }
        // DerivedClass_fieldmethods = { __index = BaseClass_methods }

        // redirect the class methods to the base methods
        pushValue(klass);
        newTable();
        getGlobal(baseClass);
        setField("__index");
        setMetatable();
        pop();

        // redirect the class fieldmethods to the base fieldmethods
        pushValue(klass_fieldmethods);
        newTable();
        getGlobal(baseClass.data() + "_fieldmethods"s);
        setField("__index");
        setMetatable();
        pop();
    }

    // pops klass, klass_mt, klass_fieldmethods
    pop(3);
}

void LuaInterface::registerClassStaticFunction(const std::string_view className,
                                               const std::string_view functionName,
                                               const LuaCppFunction& function)
{
    registerClassMemberFunction(className, functionName, function);
}

void LuaInterface::registerClassMemberFunction(const std::string_view className,
                                               const std::string_view functionName,
                                               const LuaCppFunction& function)
{
    getGlobal(className);
    pushCppFunction(function);
    setField(functionName);
    pop();
}

void LuaInterface::registerClassMemberField(const std::string_view className,
                                            const std::string_view field,
                                            const LuaCppFunction& getFunction,
                                            const LuaCppFunction& setFunction)
{
    getGlobal(className.data() + "_fieldmethods"s);

    if (getFunction) {
        pushCppFunction(getFunction);
        setField(stdext::format("get_%s", field));
    }

    if (setFunction) {
        pushCppFunction(setFunction);
        setField(stdext::format("set_%s", field));
    }

    pop();
}

void LuaInterface::registerGlobalFunction(const std::string_view functionName, const LuaCppFunction& function)
{
    pushCppFunction(function);
    setGlobal(functionName);
}

int LuaInterface::luaObjectGetEvent(LuaInterface* lua)
{
    // stack: obj, key
    const auto& obj = lua->toObject(-2);
    const auto& key = lua->toString(-1);
    assert(obj);

    lua->remove(-1); // removes key

    // if a get method for this key exists, calls it
    lua->getMetatable(); // pushes obj metatable
    lua->getField("fieldmethods"); // push obj fieldmethods
    lua->remove(-2); // removes obj metatable
    lua->getField("get_" + key); // pushes get method
    lua->remove(-2); // remove obj fieldmethods
    if (!lua->isNil()) { // is the get method not nil?
        lua->insert(-2); // moves obj to the top
        lua->signalCall(1, 1); // calls get method, arguments: obj
        return 1;
    }
    lua->pop(); // pops the nil get method

    // if the field for this key exists, returns it
    obj->luaGetField(key);
    if (!lua->isNil()) {
        lua->remove(-2); // removes the obj
        // field value is on the stack
        return 1;
    }
    lua->pop(); // pops the nil field

    // pushes the method assigned by this key
    lua->getMetatable();  // pushes obj metatable
    lua->getField("methods"); // push obj methods
    lua->remove(-2); // removes obj metatable
    lua->getField(key); // pushes obj method
    lua->remove(-2); // remove obj methods
    lua->remove(-2); // removes obj

    // the result value is on the stack
    return 1;
}

int LuaInterface::luaObjectSetEvent(LuaInterface* lua)
{
    // stack: obj, key, value
    const auto& obj = lua->toObject(-3);
    const auto& key = lua->toString(-2);
    assert(obj);

    lua->remove(-2); // removes key
    lua->insert(-2); // moves obj to the top

    // check if a set method for this field exists and call it
    lua->getMetatable(); // pushes obj metatable
    lua->getField("fieldmethods"); // push obj fieldmethods
    lua->remove(-2); // removes obj metatable
    lua->getField("set_" + key); // pushes set method
    lua->remove(-2); // remove obj fieldmethods
    if (!lua->isNil()) { // is the set method not nil?
        lua->insert(-3); // moves func to -3
        lua->insert(-2); // moves obj to -2, and value to -1
        lua->signalCall(2, 0); // calls set method, arguments: obj, value
        return 0;
    }
    lua->pop(); // pops the nil set method

    // no set method exists, then treats as an field and set it
    lua->pop(); // pops the object
    obj->luaSetField(key); // sets the obj field
    return 0;
}

int LuaInterface::luaObjectEqualEvent(LuaInterface* lua)
{
    // stack: obj1, obj2
    bool ret = false;

    // check if obj1 == obj2
    if (lua->isUserdata(-1) && lua->isUserdata(-2)) {
        const auto* const objPtr2 = static_cast<LuaObjectPtr*>(lua->popUserdata());
        const auto* const objPtr1 = static_cast<LuaObjectPtr*>(lua->popUserdata());
        assert(objPtr1 && objPtr2);
        if (*objPtr1 == *objPtr2)
            ret = true;
    } else
        lua->pop(2);

    lua->pushBoolean(ret);
    return 1;
}

int LuaInterface::luaObjectCollectEvent(LuaInterface* lua)
{
    // gets object pointer
    auto* const objPtr = static_cast<LuaObjectPtr*>(lua->popUserdata());
    assert(objPtr);

    // resets pointer to decrease object use count
    objPtr->reset();
    --g_lua.m_totalObjRefs;
    return 0;
}

///////////////////////////////////////////////////////////////////////////////

bool LuaInterface::safeRunScript(const std::string& fileName)
{
    try {
        runScript(fileName);
        return true;
    } catch (stdext::exception& e) {
        g_logger.error(stdext::format("Failed to load script '%s': %s", fileName, e.what()));
        return false;
    }
}

void LuaInterface::runScript(const std::string& fileName)
{
    loadScript(fileName);
    safeCall(0, 0);
}

void LuaInterface::runBuffer(const std::string_view buffer, const std::string_view source)
{
    loadBuffer(buffer, source);
    safeCall(0, 0);
}

void LuaInterface::loadScript(const std::string& fileName)
{
    // resolve file full path
    std::string filePath{ fileName.data() };
    if (!fileName.starts_with("/"))
        filePath = getCurrentSourcePath() + "/" + filePath;

    filePath = g_resources.guessFilePath(filePath, "lua");

    const auto& buffer = g_resources.readFileContents(filePath);
    const auto& source = "@" + filePath;
    loadBuffer(buffer, source);
}

void LuaInterface::loadFunction(const std::string_view buffer, const std::string_view source)
{
    if (buffer.empty()) {
        pushNil();
        return;
    }

    std::string buf;
    if (buffer.starts_with("function"))
        buf = stdext::format("__func = %s", buffer);
    else
        buf = stdext::format("__func = function(self)\n%s\nend", buffer);

    loadBuffer(buf, source);
    safeCall();

    // get the function
    getGlobal("__func");

    // reset the global __func
    pushNil();
    setGlobal("__func");
}

void LuaInterface::evaluateExpression(const std::string_view expression, const std::string_view source)
{
    // evaluates the expression
    if (!expression.empty()) {
        const auto& buffer = stdext::format("__exp = (%s)", expression);
        loadBuffer(buffer, source);
        safeCall();

        // gets the expression result
        getGlobal("__exp");

        // resets global __exp
        pushNil();
        setGlobal("__exp");
    } else
        pushNil();
}

std::string LuaInterface::traceback(const std::string_view errorMessage, int level)
{
    // gets debug.traceback
    getGlobal("debug");
    getField("traceback");
    remove(-2); // remove debug

    // calls debug.traceback(errorMessage, level)
    pushString(errorMessage);
    pushInteger(level);
    call(2, 1);

    // returns the traceback message
    return popString();
}

void LuaInterface::throwError(const std::string_view message)
{
    if (isInCppCallback()) {
        pushString(message);
        error();
    } else
        throw stdext::exception(message);
}

std::string LuaInterface::getCurrentSourcePath(int level)
{
    std::string path;
    if (!L)
        return path;

    // check all stack functions for script source path
    while (true) {
        getStackFunction(level); // pushes stack function

        // only lua functions is wanted, because only them have a working directory
        if (isLuaFunction()) {
            path = functionSourcePath();
            break;
        }
        if (isNil()) {
            pop();
            break;
        }
        pop();

        // next level
        ++level;
    }

    return path;
}

int LuaInterface::safeCall(int numArgs, int numRets)
{
    assert(hasIndex(-numArgs - 1));

    // saves the current stack size for calculating the number of results later
    const int previousStackSize = stackSize();

    // pushes error function
    const int errorFuncIndex = previousStackSize - numArgs;
    pushCFunction(&LuaInterface::luaErrorHandler);
    insert(errorFuncIndex);

    // calls the function in protected mode (means errors will be caught)
    const int ret = pcall(numArgs, LUA_MULTRET, errorFuncIndex);

    remove(errorFuncIndex); // remove error func

    // if there was an error throw an exception
    if (ret != 0) {
        const std::string& error = popString();
        g_logger.error(stdext::format("Lua exception: %s", error));
        throw LuaException(error);
    }

    int rets = (stackSize() + numArgs + 1) - previousStackSize;
    while (numRets != -1 && rets != numRets) {
        if (rets < numRets) {
            pushNil();
            ++rets;
        } else {
            pop();
            --rets;
        }
    }

    // returns the number of results
    return rets;
}

int LuaInterface::signalCall(int numArgs, int numRets)
{
    int rets = 0;
    const int funcIndex = -numArgs - 1;

    try {
        // must be a function
        if (isFunction(funcIndex)) {
            rets = safeCall(numArgs);

            if (numRets != -1) {
                if (rets != numRets)
                    throw LuaException("function call didn't return the expected number of results", 0);
            }
        }
        // can also calls table of functions
        else if (isTable(funcIndex)) {
            // loop through table values
            pushNil();
            bool done = false;
            while (next(funcIndex - 1)) {
                if (isFunction()) {
                    // repush arguments
                    for (int i = 0; i < numArgs; ++i)
                        pushValue(-numArgs - 2);

                    rets = safeCall(numArgs);
                    if (rets == 1) {
                        done = popBoolean();
                        if (done) {
                            pop();
                            break;
                        }
                    } else if (rets != 0)
                        throw LuaException("function call didn't return the expected number of results", 0);
                } else {
                    throw LuaException("attempt to call a non function", 0);
                }
            }
            pop(numArgs + 1); // pops the table of function and arguments

            if (numRets == 1 || numRets == -1) {
                rets = 1;
                pushBoolean(done);
            }
        }
        // nil values are ignored
        else if (isNil(funcIndex)) {
            pop(numArgs + 1); // pops the function and arguments
        }
        // if not nil, warn
        else {
            throw LuaException("attempt to call a non function value", 0);
        }
    } catch (stdext::exception& e) {
        g_logger.error(stdext::format("protected lua call failed: %s", e.what()));
    }

    // pushes nil values if needed
    while (numRets != -1 && rets < numRets) {
        pushNil();
        ++rets;
    }

    // returns the number of results on the stack
    return rets;
}

int LuaInterface::newSandboxEnv()
{
    newTable(); // pushes the new environment table
    newTable(); // pushes the new environment metatable
    getRef(getGlobalEnvironment());  // pushes the global environment
    setField("__index"); // sets metatable __index to the global environment
    setMetatable(); // assigns environment metatable
    return ref(); // return a reference to the environment table
}

///////////////////////////////////////////////////////////////////////////////
// lua C functions

int LuaInterface::luaScriptLoader(lua_State*)
{
    // loads the script as a function
    const auto& fileName = g_lua.popString();

    try {
        g_lua.loadScript(fileName);
        return 1;
    } catch (stdext::exception& e) {
        g_lua.pushString("\n\t"s + e.what());
        return 1;
    }
}

int LuaInterface::lua_dofile(lua_State*)
{
    const auto& file = g_lua.popString();

    try {
        g_lua.loadScript(file);
        g_lua.call(0, LUA_MULTRET);
        return g_lua.stackSize();
    } catch (stdext::exception& e) {
        g_lua.pushString(e.what());
        g_lua.error();
        return 0;
    }
}

int LuaInterface::lua_dofiles(lua_State*)
{
    std::string contains;
    if (g_lua.getTop() > 2) {
        contains = g_lua.popString();
    }

    bool recursive = false;
    if (g_lua.getTop() > 1) {
        recursive = g_lua.popBoolean();
    }

    const auto& directory = g_lua.popString();
    g_lua.loadFiles(directory, recursive, contains);

    return 0;
}

int LuaInterface::lua_loadfile(lua_State*)
{
    const auto& fileName = g_lua.popString();

    try {
        g_lua.loadScript(fileName);
        return 1;
    } catch (stdext::exception& e) {
        g_lua.pushNil();
        g_lua.pushString(e.what());
        g_lua.error();
        return 2;
    }
}

int LuaInterface::luaErrorHandler(lua_State*)
{
    // pops the error message
    auto error = g_lua.popString();

    // prevents repeated tracebacks
    if (error.find("stack traceback:") == std::string::npos)
        error = g_lua.traceback(error, 1);

    // pushes the new error message with traceback information
    g_lua.pushString(error);
    return 1;
}

int LuaInterface::luaCppFunctionCallback(lua_State*)
{
    // retrieves function pointer from userdata
    const auto* const funcPtr = static_cast<LuaCppFunctionPtr*>(g_lua.popUpvalueUserdata());
    assert(funcPtr);

    int numRets = 0;

    // do the call
    try {
        ++g_lua.m_cppCallbackDepth;
        numRets = (*(funcPtr->get()))(&g_lua);
        --g_lua.m_cppCallbackDepth;
        assert(numRets == g_lua.stackSize());
    } catch (stdext::exception& e) {
        // cleanup stack
        while (g_lua.stackSize() > 0)
            g_lua.pop();
        numRets = 0;
        g_lua.pushString(stdext::format("C++ call failed: %s", g_lua.traceback(e.what())));
        g_lua.error();
    }

    return numRets;
}

int LuaInterface::luaCollectCppFunction(lua_State*)
{
    auto* const funcPtr = static_cast<LuaCppFunctionPtr*>(g_lua.popUserdata());
    assert(funcPtr);
    funcPtr->reset();
    --g_lua.m_totalFuncRefs;
    return 0;
}

void LuaInterface::registerTable(lua_State* L, const std::string& tableName)
{
    // _G[tableName] = {}
    lua_newtable(L);
    lua_setglobal(L, tableName.c_str());
}

void LuaInterface::registerMethod(lua_State* L, const std::string& globalName, const std::string& methodName, lua_CFunction func)
{
    // globalName.methodName = func
    lua_getglobal(L, globalName.c_str());
    lua_pushcfunction(L, func);
    lua_setfield(L, -2, methodName.c_str());

    // pop globalName
    lua_pop(L, 1);
}

#ifndef LUAJIT_VERSION
///////////////////////////////////////////////////////////////////////////////
// from here all next functions are interfaces for the Lua API
int LuaInterface::luaBitNot(lua_State* L)
{
    int32_t number = static_cast<int64_t>(lua_tonumber(L, -1));
    lua_pushnumber(L, ~number);
    return 1;
}

int LuaInterface::luaBitAnd(lua_State* L)
{
    int n = lua_gettop(L); \
        uint32_t number = static_cast<uint32_t>(lua_tonumber(L, -1));
    for (int i = 1; i < n; ++i)
        number &= static_cast<uint32_t>(lua_tonumber(L, i));
    lua_pushnumber(L, number);
    return 1;
}

int LuaInterface::luaBitOr(lua_State* L)
{
    int n = lua_gettop(L); \
        uint32_t number = static_cast<uint32_t>(lua_tonumber(L, -1));
    for (int i = 1; i < n; ++i)
        number |= static_cast<uint32_t>(lua_tonumber(L, i));
    lua_pushnumber(L, number);
    return 1;
}

int LuaInterface::luaBitXor(lua_State* L)
{
    int n = lua_gettop(L); \
        uint32_t number = static_cast<uint32_t>(lua_tonumber(L, -1));
    for (int i = 1; i < n; ++i)
        number ^= static_cast<uint32_t>(lua_tonumber(L, i));
    lua_pushnumber(L, number);
    return 1;
}

int LuaInterface::luaBitLeftShift(lua_State* L)
{
    uint32_t n1 = static_cast<uint32_t>(lua_tonumber(L, 1));
    uint32_t n2 = static_cast<uint32_t>(lua_tonumber(L, 2));
    lua_pushnumber(L, (n1 << n2));
    return 1;
}

int LuaInterface::luaBitRightShift(lua_State* L)
{
    uint32_t n1 = static_cast<uint32_t>(lua_tonumber(L, 1));
    uint32_t n2 = static_cast<uint32_t>(lua_tonumber(L, 2));
    lua_pushnumber(L, (n1 >> n2));
    return 1;
}
#endif

void LuaInterface::createLuaState()
{
    // creates lua state
    L = luaL_newstate();
    if (!L)
        g_logger.fatal("Unable to create lua state");

    // load lua standard libraries
    luaL_openlibs(L);

#ifndef LUAJIT_VERSION
    // load Bit lib for bitwise operations
    registerTable(L, "Bit");
    registerMethod(L, "Bit", "bnot", LuaInterface::luaBitNot);
    registerMethod(L, "Bit", "band", LuaInterface::luaBitAnd);
    registerMethod(L, "Bit", "bor", LuaInterface::luaBitOr);
    registerMethod(L, "Bit", "bxor", LuaInterface::luaBitXor);
    registerMethod(L, "Bit", "lshift", LuaInterface::luaBitLeftShift);
    registerMethod(L, "Bit", "rshift", LuaInterface::luaBitRightShift);
#endif

    // creates weak table
    newTable();
    newTable();
    pushString("v");
    setField("__mode");
    setMetatable();
    m_weakTableRef = ref();

    // installs script loader
    getGlobal("package");
    getField("loaders");
    pushCFunction(&LuaInterface::luaScriptLoader);
    rawSeti(5);
    pop(2);

    // replace dofile
    pushCFunction(&LuaInterface::lua_dofile);
    setGlobal("dofile");

    // dofiles
    pushCFunction(&LuaInterface::lua_dofiles);
    setGlobal("dofiles");

    // replace loadfile
    pushCFunction(&LuaInterface::lua_loadfile);
    setGlobal("loadfile");
}

void LuaInterface::closeLuaState()
{
    if (L) {
        // close lua, it also collects
        lua_close(L);
        L = nullptr;
    }
}

void LuaInterface::collectGarbage() const
{
    // prevents recursive collects
    static bool collecting = false;
    if (!collecting) {
        collecting = true;

        // we must collect two times because __gc metamethod
        // is called on uservalues only the second time
        for (int i = -1; ++i < 2;)
            lua_gc(L, LUA_GCCOLLECT, 0);

        collecting = false;
    }
}

void LuaInterface::loadBuffer(const std::string_view buffer, const std::string_view source)
{
    // loads lua buffer
    const int ret = luaL_loadbuffer(L, buffer.data(), buffer.length(), source.data());
    if (ret != 0)
        throw LuaException(popString(), 0);
}

int LuaInterface::pcall(int numArgs, int numRets, int errorFuncIndex)
{
    assert(hasIndex(-numArgs - 1));
    return lua_pcall(L, numArgs, numRets, errorFuncIndex);
}

void LuaInterface::call(int numArgs, int numRets)
{
    assert(hasIndex(-numArgs - 1));
    lua_call(L, numArgs, numRets);
}

void LuaInterface::error()
{
    assert(hasIndex(-1));
    lua_error(L);
}

int LuaInterface::ref() const
{
    const int ref = luaL_ref(L, LUA_REGISTRYINDEX);
    assert(ref != LUA_NOREF);
    assert(ref < 2147483647);
    return ref;
}

int LuaInterface::weakRef()
{
    static int id = 0;

    // generates a new id
    ++id;
    if (id == 2147483647)
        id = 0;

    // gets weak table
    getRef(m_weakTableRef);
    insert(-2);

    // sets weak_table[id] = v
    rawSeti(id);

    // pops weak table
    pop();

    return id;
}

void LuaInterface::unref(int ref) const
{
    if (ref >= 0 && L != nullptr)
        luaL_unref(L, LUA_REGISTRYINDEX, ref);
}

const char* LuaInterface::typeName(int index)
{
    assert(hasIndex(index));
    const int type = lua_type(L, index);
    return lua_typename(L, type);
}

std::string LuaInterface::functionSourcePath() const
{
    std::string path;

    // gets function source path
    lua_Debug ar;
    memset(&ar, 0, sizeof(ar));
    lua_getinfo(L, ">Sn", &ar);
    if (ar.source) {
        // scripts coming from files has source beginning with '@'
        if (ar.source[0] == '@') {
            path = ar.source;
            path = path.substr(1, path.find_last_of('/') - 1);
            path = path.substr(0, path.find_last_of(':'));
        }
    }

    return path;
}

void LuaInterface::insert(int index)
{
    assert(hasIndex(index));
    lua_insert(L, index);
}

void LuaInterface::remove(int index)
{
    assert(hasIndex(index));
    lua_remove(L, index);
}

bool LuaInterface::next(int index)
{
    assert(hasIndex(index));
    return lua_next(L, index);
}

void LuaInterface::getStackFunction(int level)
{
    lua_Debug ar;
    if (lua_getstack(L, level, &ar) == 1)
        lua_getinfo(L, "f", &ar);
    else
        pushNil();
}

void LuaInterface::getRef(int ref) const
{
    lua_rawgeti(L, LUA_REGISTRYINDEX, ref);
}

void LuaInterface::getWeakRef(int weakRef)
{
    // pushes weak_table[weakRef]
    getRef(m_weakTableRef);
    rawGeti(weakRef);
    remove(-2);
}

void LuaInterface::setGlobalEnvironment(int env)
{
    pushThread();
    getRef(env);
    assert(isTable());
    setEnv();
    pop();
}

void LuaInterface::setMetatable(int index)
{
    assert(hasIndex(index));
    lua_setmetatable(L, index);
}

void LuaInterface::getMetatable(int index)
{
    assert(hasIndex(index));
    lua_getmetatable(L, index);
}

void LuaInterface::getField(const std::string_view key, int index)
{
    assert(hasIndex(index));
    assert(isUserdata(index) || isTable(index));
    lua_getfield(L, index, key.data());
}

void LuaInterface::setField(const std::string_view key, int index)
{
    assert(hasIndex(index));
    assert(isUserdata(index) || isTable(index));
    lua_setfield(L, index, key.data());
}

void LuaInterface::getEnv(int index)
{
    assert(hasIndex(index));
#ifdef LUAJIT_VERSION
    lua_getfenv(L, index);
#else
    lua_getupvalue(L, index, 1);
#endif
}

void LuaInterface::setEnv(int index)
{
    assert(hasIndex(index));
#ifdef LUAJIT_VERSION
    lua_setfenv(L, index);
#else
    const char* name = lua_setupvalue(L, index, 1);
    assert(strcmp(name, "_ENV") == 0);
#endif
}

void LuaInterface::getTable(int index)
{
    assert(hasIndex(index));
    lua_gettable(L, index);
}

void LuaInterface::setTable(int index)
{
    assert(hasIndex(index));
    lua_settable(L, index);
}

void LuaInterface::clearTable(int index)
{
    assert(hasIndex(index) && isTable(index));

    pushNil(); // table, nil

    while (next(index - 1)) { // table, key, value
        pop(); // table, key
        pushValue(); // table, key, key
        if (next(index - 2)) { // table, key, nextkey, value
            pop(); // table, key, nextkey
            insert(-2); // table, nextkey, key
            pushNil(); // table, nextkey, key, nil
            rawSet(index - 3); // table, nextkey
        } else { // table, key
            pushNil(); // table, key, nil
            rawSet(index - 2); // table
            break;
        }
    }
}

void LuaInterface::getGlobal(const std::string_view key) const
{
    lua_getglobal(L, key.data());
}

void LuaInterface::getGlobalField(const std::string_view globalKey, const std::string_view fieldKey)
{
    getGlobal(globalKey);
    if (!isNil()) {
        assert(isTable() || isUserdata());
        getField(fieldKey);
        remove(-2);
    }
}

void LuaInterface::setGlobal(const std::string_view key)
{
    assert(hasIndex(-1));
    lua_setglobal(L, key.data());
}

void LuaInterface::rawGet(int index)
{
    assert(hasIndex(index));
    lua_rawget(L, index);
}

void LuaInterface::rawGeti(int n, int index)
{
    assert(hasIndex(index));
    lua_rawgeti(L, index, n);
}

void LuaInterface::rawSet(int index)
{
    assert(hasIndex(index));
    lua_rawset(L, index);
}

void LuaInterface::rawSeti(int n, int index)
{
    assert(hasIndex(index));
    lua_rawseti(L, index, n);
}

void LuaInterface::newTable() const
{
    lua_newtable(L);
}

void LuaInterface::createTable(int narr, int nrec) const
{
    lua_createtable(L, narr, nrec);
}

void* LuaInterface::newUserdata(int size) const
{
    return lua_newuserdata(L, size);
}

void LuaInterface::pop(int n)
{
    if (n > 0) {
        assert(hasIndex(-n));
        lua_pop(L, n);
    }
}

long LuaInterface::popInteger()
{
    assert(hasIndex(-1));
    const long v = toInteger(-1);
    pop();
    return v;
}

double LuaInterface::popNumber()
{
    assert(hasIndex(-1));
    const double v = toNumber(-1);
    pop();
    return v;
}

bool LuaInterface::popBoolean()
{
    assert(hasIndex(-1));
    const bool v = toBoolean(-1);
    pop();
    return v;
}

std::string LuaInterface::popString()
{
    assert(hasIndex(-1));
    std::string v = toString(-1);
    pop();
    return v;
}

void* LuaInterface::popUserdata()
{
    assert(hasIndex(-1));
    void* v = toUserdata(-1);
    pop();
    return v;
}

LuaObjectPtr LuaInterface::popObject()
{
    assert(hasIndex(-1));
    const auto& v = toObject(-1);
    pop();
    return v;
}

void* LuaInterface::popUpvalueUserdata() const
{
    return lua_touserdata(L, lua_upvalueindex(1));
}

void LuaInterface::pushNil()
{
    lua_pushnil(L);
    checkStack();
}

void LuaInterface::pushInteger(long v)
{
    lua_pushinteger(L, v);
    checkStack();
}

void LuaInterface::pushNumber(double v)
{
    lua_pushnumber(L, v);
    checkStack();
}

void LuaInterface::pushBoolean(bool v)
{
    lua_pushboolean(L, v);
    checkStack();
}

void LuaInterface::pushString(const std::string_view v)
{
    lua_pushlstring(L, v.data(), v.length());
    checkStack();
}

void LuaInterface::pushLightUserdata(void* p)
{
    lua_pushlightuserdata(L, p);
    checkStack();
}

void LuaInterface::pushThread()
{
    lua_pushthread(L);
    checkStack();
}

void LuaInterface::pushObject(const LuaObjectPtr& obj)
{
    // fills a new userdata with a new LuaObjectPtr pointer
    new(newUserdata(sizeof(LuaObjectPtr))) LuaObjectPtr(obj);
    ++m_totalObjRefs;

    obj->luaGetMetatable();
    if (isNil())
        g_logger.fatal(stdext::format("metatable for class '%s' not found, did you bind the C++ class?", obj->getClassName()));
    setMetatable();
}

void LuaInterface::pushCFunction(LuaCFunction func, int n)
{
    lua_pushcclosure(L, func, n);
    checkStack();
}

void LuaInterface::pushCppFunction(const LuaCppFunction& func)
{
    // create a pointer to func (this pointer will hold the function existence)
    new(newUserdata(sizeof(LuaCppFunctionPtr))) LuaCppFunctionPtr(new LuaCppFunction(func));
    ++m_totalFuncRefs;

    // sets the userdata __gc metamethod, needed to free the function pointer when it gets collected
    newTable();
    pushCFunction(&LuaInterface::luaCollectCppFunction);
    setField("__gc");
    setMetatable();

    // actually pushes a C function callback that will call the cpp function
    pushCFunction(&LuaInterface::luaCppFunctionCallback, 1);
}

void LuaInterface::pushValue(int index)
{
    assert(hasIndex(index));
    lua_pushvalue(L, index);
    checkStack();
}

bool LuaInterface::isNil(int index)
{
    assert(hasIndex(index));
    return lua_isnil(L, index);
}

bool LuaInterface::isBoolean(int index)
{
    assert(hasIndex(index));
    return lua_isboolean(L, index);
}

bool LuaInterface::isNumber(int index)
{
    assert(hasIndex(index));
    return lua_isnumber(L, index);
}

bool LuaInterface::isString(int index)
{
    assert(hasIndex(index));
    return lua_isstring(L, index);
}

bool LuaInterface::isTable(int index)
{
    assert(hasIndex(index));
    return lua_istable(L, index);
}

bool LuaInterface::isFunction(int index)
{
    assert(hasIndex(index));
    return lua_isfunction(L, index);
}

bool LuaInterface::isCFunction(int index)
{
    assert(hasIndex(index));
    return lua_iscfunction(L, index);
}

bool LuaInterface::isUserdata(int index)
{
    assert(hasIndex(index));
    return lua_isuserdata(L, index);
}

bool LuaInterface::toBoolean(int index)
{
    assert(hasIndex(index));
    return static_cast<bool>(lua_toboolean(L, index));
}

int LuaInterface::toInteger(int index)
{
    assert(hasIndex(index));
    return lua_tointeger(L, index);
}

double LuaInterface::toNumber(int index)
{
    assert(hasIndex(index));
    return lua_tonumber(L, index);
}

std::string_view LuaInterface::toVString(int index)
{
    assert(hasIndex(index));
    const char* value = lua_tostring(L, index);
    return value != nullptr ? value : ""sv;
}

std::string LuaInterface::toString(int index)
{
    assert(hasIndex(index));
    std::string str;
    size_t len;
    const char* data = lua_tolstring(L, index, &len);
    if (data && len > 0)
        str.assign(data, len);
    return str;
}

void* LuaInterface::toUserdata(int index)
{
    assert(hasIndex(index));
    return lua_touserdata(L, index);
}

LuaObjectPtr LuaInterface::toObject(int index)
{
    assert(hasIndex(index));
    if (isUserdata(index)) {
        auto* const objRef = static_cast<LuaObjectPtr*>(toUserdata(index));
        if (objRef && *objRef)
            return *objRef;
    }
    return nullptr;
}

int LuaInterface::getTop() const
{
    return lua_gettop(L);
}

void LuaInterface::loadFiles(const std::string& directory, bool recursive, const std::string& contains)
{
    for (const std::string& fileName : g_resources.listDirectoryFiles(directory)) {
        std::string fullPath = directory.data() + "/"s + fileName;

        if (recursive && g_resources.directoryExists(fullPath)) {
            loadFiles(fullPath, true, contains);
            continue;
        }

        if (!g_resources.isFileType(fileName, "lua"))
            continue;

        if (!contains.empty() && fileName.find(contains) == std::string::npos)
            continue;

        try {
            g_lua.loadScript(fullPath);
            g_lua.call(0, 0);
        } catch (stdext::exception& e) {
            g_lua.pushString(e.what());
            g_lua.error();
        }
    }
}