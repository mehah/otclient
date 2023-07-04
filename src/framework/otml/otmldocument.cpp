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

#include "otmldocument.h"
#include "otmlemitter.h"
#include "otmlparser.h"

#include <framework/core/resourcemanager.h>

OTMLDocumentPtr OTMLDocument::create()
{
    const auto& doc(OTMLDocumentPtr(new OTMLDocument));
    doc->setTag("doc");
    return doc;
}

OTMLDocumentPtr OTMLDocument::parse(const std::string& fileName)
{
    std::stringstream fin;
    const auto& source = g_resources.resolvePath(fileName);
    g_resources.readFileStream(source, fin);
    return parse(fin, source);
}

OTMLDocumentPtr OTMLDocument::parse(std::istream& in, const std::string_view source)
{
    const auto& doc(OTMLDocumentPtr(new OTMLDocument));
    doc->setSource(source);
    OTMLParser parser(doc, in);
    parser.parse();
    return doc;
}

std::string OTMLDocument::emit() { return OTMLEmitter::emitNode(asOTMLNode()) + "\n"; }

bool OTMLDocument::save(const std::string_view fileName)
{
    return g_resources.writeFileContents((m_source = fileName).data(), emit());
}