#include <gtest/gtest.h>

#include <string>

#include <framework/stdext/string.h>

namespace {

    TEST(StringEncoding, Utf8Validation)
    {
        EXPECT_TRUE(stdext::is_valid_utf8("Hello World"));
        EXPECT_TRUE(stdext::is_valid_utf8(""));
        EXPECT_TRUE(stdext::is_valid_utf8("ASCII 123"));
        EXPECT_TRUE(stdext::is_valid_utf8(reinterpret_cast<const char*>(u8"Café")));
        EXPECT_TRUE(stdext::is_valid_utf8(reinterpret_cast<const char*>(u8"日本語")));
        EXPECT_TRUE(stdext::is_valid_utf8(reinterpret_cast<const char*>(u8"🎉🎊")));

        EXPECT_FALSE(stdext::is_valid_utf8("\x80"));
        EXPECT_FALSE(stdext::is_valid_utf8("\xFF"));
        EXPECT_FALSE(stdext::is_valid_utf8("\xC0\x80"));
        EXPECT_FALSE(stdext::is_valid_utf8("\xF5\x80\x80\x80"));
        EXPECT_FALSE(stdext::is_valid_utf8("\xC2"));
        EXPECT_FALSE(stdext::is_valid_utf8("\xED\xA0\x80"));
    }

    TEST(StringEncoding, Utf8ToLatin1)
    {
        EXPECT_EQ(stdext::utf8_to_latin1("Hello"), "Hello");
        EXPECT_EQ(stdext::utf8_to_latin1("123"), "123");
        EXPECT_EQ(stdext::utf8_to_latin1("\t\r\n"), "\t\r\n");

        EXPECT_EQ(stdext::utf8_to_latin1(reinterpret_cast<const char*>(u8"Café")), "Caf\xe9");
        EXPECT_EQ(stdext::utf8_to_latin1(reinterpret_cast<const char*>(u8"Über")), "\xDC" "ber");
        EXPECT_EQ(stdext::utf8_to_latin1(reinterpret_cast<const char*>(u8"naïve")), "na\xefve");

        EXPECT_EQ(stdext::utf8_to_latin1(reinterpret_cast<const char*>(u8"Hello 世界")), "Hello ");
        EXPECT_EQ(stdext::utf8_to_latin1(reinterpret_cast<const char*>(u8"🎉")), "");

        EXPECT_EQ(stdext::utf8_to_latin1("\xFF\xFE"), "");
        EXPECT_EQ(stdext::utf8_to_latin1("\xC0\x80"), "");

        EXPECT_EQ(stdext::utf8_to_latin1("\x01\x02\x03"), "");
        EXPECT_EQ(stdext::utf8_to_latin1("\x1F"), "");
        EXPECT_EQ(stdext::utf8_to_latin1(reinterpret_cast<const char*>(u8"\u0080\u0090\u009F")), "");
    }

    TEST(StringEncoding, Latin1ToUtf8)
    {
        EXPECT_EQ(stdext::latin1_to_utf8("Hello"), "Hello");
        EXPECT_EQ(stdext::latin1_to_utf8("123"), "123");
        EXPECT_EQ(stdext::latin1_to_utf8("\t\r\n"), "\t\r\n");

        EXPECT_EQ(stdext::latin1_to_utf8("Caf\xe9"), reinterpret_cast<const char*>(u8"Café"));
        EXPECT_EQ(stdext::latin1_to_utf8("\xDC" "ber"), reinterpret_cast<const char*>(u8"Über"));
        EXPECT_EQ(stdext::latin1_to_utf8("na\xefve"), reinterpret_cast<const char*>(u8"naïve"));

        std::string latin1All;
        latin1All.reserve(256);
        for(int i = 0; i < 256; ++i) {
            latin1All += static_cast<char>(i);
        }

        const auto utf8Result = stdext::latin1_to_utf8(latin1All);
        EXPECT_FALSE(utf8Result.empty());
        EXPECT_TRUE(stdext::is_valid_utf8(utf8Result));
    }

    TEST(StringEncoding, Roundtrip)
    {
        const std::string ascii = "Hello World 123!";
        EXPECT_EQ(stdext::latin1_to_utf8(stdext::utf8_to_latin1(ascii)), ascii);

        const std::string latin1 = "Caf\xe9 na\xefve";
        EXPECT_EQ(stdext::utf8_to_latin1(stdext::latin1_to_utf8(latin1)), latin1);
    }

#ifdef WIN32
    TEST(StringEncoding, Utf16Conversions)
    {
        EXPECT_EQ(stdext::utf8_to_utf16("Hello"), L"Hello");
        EXPECT_EQ(stdext::utf16_to_utf8(L"Hello"), "Hello");

        EXPECT_EQ(stdext::utf8_to_utf16(reinterpret_cast<const char*>(u8"Café")), L"Café");
        EXPECT_EQ(stdext::utf16_to_utf8(L"Café"), reinterpret_cast<const char*>(u8"Café"));

        EXPECT_EQ(stdext::utf8_to_utf16(reinterpret_cast<const char*>(u8"🎉")), L"🎉");
        EXPECT_EQ(stdext::utf16_to_utf8(L"🎉"), reinterpret_cast<const char*>(u8"🎉"));

        EXPECT_TRUE(stdext::utf8_to_utf16("\xFF\xFE").empty());

        const std::wstring invalidSurrogate = L"\xD800";
        EXPECT_TRUE(stdext::utf16_to_utf8(invalidSurrogate).empty());

        EXPECT_EQ(stdext::latin1_to_utf16("Caf\xe9"), L"Café");
        EXPECT_EQ(stdext::utf16_to_latin1(L"Café"), "Caf\xe9");
    }
#endif

}
