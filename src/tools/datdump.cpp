/*
 * Copyright (c) 2010-2025 OTClient <https://github.com/edubart/otclient>
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

#include "tools/datdump.h"

#include "client/game.h"
#include "client/thingtype.h"
#include "client/thingtypemanager.h"
#include "framework/luaengine/luainterface.h"

#include <nlohmann/json.hpp>

#include <array>
#include <fstream>
#include <iostream>
#include <optional>
#include <string>
#include <string_view>
#include <stdexcept>
#include <limits>
namespace datdump {

using json = nlohmann::ordered_json;

namespace {

std::optional<std::string> readFlagValue(std::vector<std::string>& args, const size_t index, const std::string_view flag)
{
    const bool hasInlineValue = args[index].starts_with(flag) && args[index].size() > flag.size() && args[index][flag.size()] == '=';
    if (hasInlineValue)
        return args[index].substr(flag.size() + 1);

    if (args[index] == flag) {
        if (index + 1 >= args.size())
            return std::nullopt;
        std::string value = args[index + 1];
        args.erase(args.begin() + static_cast<long>(index + 1));
        return value;
    }

    return std::nullopt;
}

std::string categoryToString(const ThingCategory category)
{
    switch (category) {
        case ThingCategoryItem: return "items";
        case ThingCategoryCreature: return "creatures";
        case ThingCategoryEffect: return "effects";
        case ThingCategoryMissile: return "missiles";
        default: return "unknown (fixme bug in the source code!)";
    }
}

json thingTypeToJson(const ThingTypePtr& type, const ThingCategory category, const uint16_t id)
{
    json entry;
    entry["id"] = id;
    entry["category"] = categoryToString(category);
    entry["name"] = type->getName();
    if (const auto& description = type->getDescription(); !description.empty())
        entry["description"] = description;

    entry["size"] = {
        { "width", type->getWidth() },
        { "height", type->getHeight() },
        { "layers", type->getLayers() },
    };
    entry["patterns"] = {
        { "x", type->getNumPatternX() },
        { "y", type->getNumPatternY() },
        { "z", type->getNumPatternZ() },
    };
    entry["animationPhases"] = type->getAnimationPhases();
    entry["groundSpeed"] = type->getGroundSpeed();
    entry["elevation"] = type->getElevation();

    auto& flags = entry["flags"];
    flags["floorChange"] = type->hasAttr(ThingAttrFloorChange);
    flags["ground"] = type->isGround();
    flags["groundBorder"] = type->isGroundBorder();
    flags["onTop"] = type->isOnTop();
    flags["onBottom"] = type->isOnBottom();
    flags["fullGround"] = type->isFullGround();
    flags["notWalkable"] = type->isNotWalkable();
    flags["notPathable"] = type->isNotPathable();
    flags["blockProjectile"] = type->blockProjectile();
    flags["hasElevation"] = type->hasAttr(ThingAttrElevation);
    flags["hasDisplacement"] = type->hasAttr(ThingAttrDisplacement);
    flags["hasLight"] = type->hasAttr(ThingAttrLight);

    return entry;
}

} // namespace

std::optional<Request> parseRequest(std::vector<std::string>& args)
{
    for (size_t i = 1; i < args.size(); ++i) {
        if (!args[i].starts_with("--dump-dat-to-json"))
            continue;

        Request request;
        if (auto datValue = readFlagValue(args, i, "--dump-dat-to-json"); datValue) {
            request.datPath = *datValue;
        } else {
            throw std::runtime_error("--dump-dat-to-json requires an argument (e.g. --dump-dat-to-json=data/Tibia.dat)");
        }

        args.erase(args.begin() + static_cast<long>(i));

        for (size_t j = 1; j < args.size();) {
            if (auto value = readFlagValue(args, j, "--dump-dat-output"); value) {
                request.outputPath = *value;
                args.erase(args.begin() + static_cast<long>(j));
                continue;
            }

            if (auto value = readFlagValue(args, j, "--dump-dat-client-version"); value) {
                try {
                    request.clientVersion = std::stoi(*value);
                } catch (const std::exception&) {
                    std::throw_with_nested(
                        std::invalid_argument("invalid --dump-dat-client-version value")
                    );
                }
                args.erase(args.begin() + static_cast<long>(j));
                continue;
            }

            if (args[j] == "--dump-dat-compact") {
                request.compactOutput = true;
                args.erase(args.begin() + static_cast<long>(j));
                continue;
            }
            throw std::runtime_error("unknown datdump argument: " + args[j]);
            //++j;
        }

        return request;
    }

    return std::nullopt;
}

bool run(const Request& request)
{
    if (request.datPath.empty()) {
        throw std::invalid_argument("--dump-dat-to-json requires a DAT file path (e.g. --dump-dat-to-json=data/Tibia.dat)");
    }

    g_lua.init();
    g_things.init();

    if (request.clientVersion > 0)
        g_game.setClientVersion(static_cast<uint16_t>(request.clientVersion));

    if (!g_things.loadDat(request.datPath)) {
        throw std::runtime_error("unable to load DAT file: " + request.datPath);
    }

    json root;
    root["datSignature"] = g_things.getDatSignature();
    root["contentRevision"] = g_things.getContentRevision();
    root["clientVersion"] = g_game.getClientVersion();

    const std::array<ThingCategory, 4> categories{ ThingCategoryItem, ThingCategoryCreature, ThingCategoryEffect, ThingCategoryMissile };
    json categoriesJson;
    for (const auto category : categories) {
        const auto& list = g_things.getThingTypes(category);
        if (list.size() > std::numeric_limits<uint16_t>::max() + 1ULL) {
            throw std::runtime_error("thing list for category " + categoryToString(category) + " exceeds uint16_t range (" + std::to_string(list.size() - 1) + " entries)");
        }

        json entries = json::array();
        for (size_t idx = 1; idx < list.size(); ++idx) {
            const auto& type = list[idx];
            if (!type || type->isNull())
                continue;
            entries.emplace_back(thingTypeToJson(type, category, static_cast<uint16_t>(idx)));
        }
        categoriesJson[categoryToString(category)] = std::move(entries);
    }
    root["categories"] = std::move(categoriesJson);

    const int indent = request.compactOutput ? -1 : 2;
    const auto payload = indent > 0 ? root.dump(indent) : root.dump();

    bool success = true;
    if (request.outputPath.empty()) {
        std::cout << payload << std::endl;
    } else {
        std::ofstream out(request.outputPath, std::ios::out | std::ios::trunc);
        if (!out) {
            throw std::runtime_error("unable to open output file: " + request.outputPath);
        } else {
            out << payload << '\n';
        }
    }

    g_things.terminate();
    g_lua.terminate();
    return success;
}

} // namespace datdump
