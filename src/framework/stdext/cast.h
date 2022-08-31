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

#pragma once

#include "demangle.h"
#include "exception.h"

#include <cstdlib>
#include <iostream>
#include <sstream>

namespace stdext
{
    // cast a type to another type
    template<typename T, typename R>
    bool cast(const T& in, R& out)
    {
        std::stringstream ss;
        ss << in;
        ss >> out;
        return !!ss && ss.eof();
    }

    // cast a type to string
    template<typename T>
    bool cast(const T& in, std::string& out)
    {
        std::stringstream ss;
        ss << in;
        out = ss.str();
        return true;
    }

    // cast string to string
    inline bool cast(const std::string& in, std::string& out)
    {
        out = in;
        return true;
    }

    // special cast from string to boolean
    inline bool cast(const std::string& in, bool& b)
    {
        if (in == "true")
            b = true;
        else if (in == "false")
            b = false;
        else
            return false;
        return true;
    }

    // special cast from string to char
    inline bool cast(const std::string& in, char& c)
    {
        if (in.length() != 1)
            return false;
        c = in[0];
        return true;
    }

    // special cast from string to long
    inline bool cast(const std::string& in, long& l)
    {
        if (in.find_first_not_of("-0123456789") != std::string::npos)
            return false;
        if (const std::size_t t = in.find_last_of('-'); t != std::string::npos && t != 0)
            return false;
        l = atol(in.data());
        return true;
    }

    // special cast from string to int
    inline bool cast(const std::string& in, int& i)
    {
        if (long l; cast(in, l)) {
            i = l;
            return true;
        }
        return false;
    }

    // special cast from string to double
    inline bool cast(const std::string& in, double& d)
    {
        if (in.find_first_not_of("-0123456789.") != std::string::npos)
            return false;
        std::size_t t = in.find_last_of('-');
        if (t != std::string::npos && t != 0)
            return false;
        t = in.find_first_of('.');
        if (t != std::string::npos && (t == 0 || t == in.length() - 1 || in.find_first_of('.', t + 1) != std::string::npos))
            return false;
        d = atof(in.data());
        return true;
    }

    // special cast from string to float
    inline bool cast(const std::string& in, float& f)
    {
        if (double d; cast(in, d)) {
            f = static_cast<float>(d);
            return true;
        }
        return false;
    }

    // special cast from boolean to string
    inline bool cast(const bool& in, std::string& out)
    {
        out = (in ? "true" : "false");
        return true;
    }

    // used by safe_cast
    class cast_exception : public exception
    {
    public:
        ~cast_exception() noexcept override = default;

        template<class T, class R>
        void update_what()
        {
            std::stringstream ss;
            ss << "failed to cast value of type '" << demangle_type<T>() << "' to type '" << demangle_type<R>() << "'";
            m_what = ss.str();
        }

        const char* what() const noexcept override { return m_what.c_str(); }
    private:
        std::string m_what;
    };

    // cast a type to another type, any error throws a cast_exception
    template<typename R, typename T>
    R safe_cast(const T& t)
    {
        R r;
        if (!cast(t, r)) {
            cast_exception e;
            e.update_what<T, R>();
            throw e;
        }
        return r;
    }

    // cast a type to another type, cast errors are ignored
    template<typename R, typename T>
    R unsafe_cast(const T& t, R def = R())
    {
        try {
            return safe_cast<R, T>(t);
        } catch (const cast_exception& e) {
            std::cerr << "CAST ERROR: " << e.what() << std::endl;
            return def;
        }
    }
}
