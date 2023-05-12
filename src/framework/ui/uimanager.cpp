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

#include "uimanager.h"
#include "ui.h"

#include <framework/core/application.h>
#include <framework/core/eventdispatcher.h>
#include <framework/core/resourcemanager.h>
#include <framework/graphics/drawpoolmanager.h>
#include <framework/otml/otml.h>
#include <framework/platform/platformwindow.h>

UIManager g_ui;

void UIManager::init()
{
    // creates root widget
    m_rootWidget = std::make_shared<UIWidget>();
    m_rootWidget->setId("root");
    m_mouseReceiver = m_rootWidget;
    m_keyboardReceiver = m_rootWidget;
}

void UIManager::terminate()
{
    // destroy root widget and its children
    m_rootWidget->destroy();
    m_mouseReceiver = nullptr;
    m_keyboardReceiver = nullptr;
    m_rootWidget = nullptr;
    m_draggingWidget = nullptr;
    m_hoveredWidget = nullptr;
    m_pressedWidget = nullptr;
    m_styles.clear();
    m_destroyedWidgets.clear();
    m_checkEvent = nullptr;
}

void UIManager::render(DrawPoolType drawPane) const
{
    if (drawPane == DrawPoolType::FOREGROUND)
        g_drawPool.use(DrawPoolType::FOREGROUND, { 0,0, g_graphics.getViewportSize() }, {});

    m_rootWidget->draw(m_rootWidget->getRect(), drawPane);
}

void UIManager::resize(const Size& size) const { m_rootWidget->setSize(size); }

void UIManager::inputEvent(const InputEvent& event)
{
    UIWidgetList widgetList;
    switch (event.type) {
        case Fw::KeyTextInputEvent:
            m_keyboardReceiver->propagateOnKeyText(event.keyText);
            break;
        case Fw::KeyDownInputEvent:
            m_keyboardReceiver->propagateOnKeyDown(event.keyCode, event.keyboardModifiers);
            break;
        case Fw::KeyPressInputEvent:
            m_keyboardReceiver->propagateOnKeyPress(event.keyCode, event.keyboardModifiers, event.autoRepeatTicks);
            break;
        case Fw::KeyUpInputEvent:
            m_keyboardReceiver->propagateOnKeyUp(event.keyCode, event.keyboardModifiers);
            break;
        case Fw::MousePressInputEvent:
            if (event.mouseButton == Fw::MouseLeftButton && m_mouseReceiver->isVisible()) {
                auto pressedWidget = m_mouseReceiver->recursiveGetChildByPos(event.mousePos, false);
                if (pressedWidget && !pressedWidget->isEnabled())
                    pressedWidget = nullptr;

                updatePressedWidget(pressedWidget, event.mousePos);
            }

            m_mouseReceiver->propagateOnMouseEvent(event.mousePos, widgetList);
            for (const auto& widget : widgetList) {
                widget->recursiveFocus(Fw::MouseFocusReason);
                if (widget->onMousePress(event.mousePos, event.mouseButton))
                    break;
            }

            break;
        case Fw::MouseReleaseInputEvent:
        {
            // release dragging widget
            bool accepted = false;
            if (m_draggingWidget && event.mouseButton == Fw::MouseLeftButton)
                accepted = updateDraggingWidget(nullptr, event.mousePos);

            if (!accepted) {
                m_mouseReceiver->propagateOnMouseEvent(event.mousePos, widgetList);

                // mouse release is always fired first on the pressed widget
                if (m_pressedWidget) {
                    const auto it = std::find(widgetList.begin(), widgetList.end(), m_pressedWidget);
                    if (it != widgetList.end())
                        widgetList.erase(it);
                    widgetList.emplace_front(m_pressedWidget);
                }

                for (const auto& widget : widgetList) {
                    if (widget->onMouseRelease(event.mousePos, event.mouseButton))
                        break;
                }
            }

            if (m_pressedWidget && event.mouseButton == Fw::MouseLeftButton)
                updatePressedWidget(nullptr, event.mousePos, !accepted);
            break;
        }
        case Fw::MouseMoveInputEvent:
        {
            // start dragging when moving a pressed widget
            if (m_pressedWidget && m_pressedWidget->isDraggable() && m_draggingWidget != m_pressedWidget) {
                // only drags when moving more than 4 pixels
                if ((event.mousePos - m_pressedWidget->getLastClickPosition()).length() >= 4)
                    updateDraggingWidget(m_pressedWidget, event.mousePos - event.mouseMoved);
            }

            // mouse move can change hovered widgets
            updateHoveredWidget(true);

            // first fire dragging move
            if (m_draggingWidget) {
                if (m_draggingWidget->onDragMove(event.mousePos, event.mouseMoved))
                    break;
            }

            if (m_pressedWidget) {
                if (m_pressedWidget->onMouseMove(event.mousePos, event.mouseMoved)) {
                    break;
                }
            }

            m_mouseReceiver->propagateOnMouseMove(event.mousePos, event.mouseMoved, widgetList);
            for (const auto& widget : widgetList) {
                if (widget->onMouseMove(event.mousePos, event.mouseMoved))
                    break;
            }
            break;
        }
        case Fw::MouseWheelInputEvent:
            m_rootWidget->propagateOnMouseEvent(event.mousePos, widgetList);
            for (const auto& widget : widgetList) {
                if (widget->onMouseWheel(event.mousePos, event.wheelDirection))
                    break;
            }
            break;
        default:
            break;
    }
}

void UIManager::updatePressedWidget(const UIWidgetPtr& newPressedWidget, const Point& clickedPos, bool fireClicks)
{
    const UIWidgetPtr oldPressedWidget = m_pressedWidget;
    m_pressedWidget = newPressedWidget;

    // when releasing mouse inside pressed widget area send onClick event
    if (fireClicks && oldPressedWidget && oldPressedWidget->isEnabled() && oldPressedWidget->containsPoint(clickedPos))
        oldPressedWidget->onClick(clickedPos);

    if (newPressedWidget)
        newPressedWidget->updateState(Fw::PressedState);

    if (oldPressedWidget)
        oldPressedWidget->updateState(Fw::PressedState);
}

bool UIManager::updateDraggingWidget(const UIWidgetPtr& draggingWidget, const Point& clickedPos)
{
    bool accepted = false;

    const auto oldDraggingWidget = m_draggingWidget;
    m_draggingWidget = nullptr;

    if (oldDraggingWidget) {
        UIWidgetPtr droppedWidget;
        if (!clickedPos.isNull()) {
            const auto clickedChildren = m_rootWidget->recursiveGetChildrenByPos(clickedPos);
            for (const auto& child : clickedChildren) {
                if (child->onDrop(oldDraggingWidget, clickedPos)) {
                    droppedWidget = child;
                    break;
                }
            }
        }

        accepted = oldDraggingWidget->onDragLeave(droppedWidget, clickedPos);
        oldDraggingWidget->updateState(Fw::DraggingState);
    }

    if (draggingWidget) {
        if (draggingWidget->onDragEnter(clickedPos)) {
            m_draggingWidget = draggingWidget;
            draggingWidget->updateState(Fw::DraggingState);
            accepted = true;
        }
    }

    return accepted;
}

void UIManager::updateHoveredWidget(bool now)
{
    if (m_hoverUpdateScheduled && !now)
        return;

    auto func = [this] {
        if (!m_rootWidget)
            return;

        m_hoverUpdateScheduled = false;
        //if(!g_window.isMouseButtonPressed(Fw::MouseLeftButton) && !g_window.isMouseButtonPressed(Fw::MouseRightButton)) {
        auto hoveredWidget = m_rootWidget->recursiveGetChildByPos(g_window.getMousePosition(), false);
        if (hoveredWidget && !hoveredWidget->isEnabled())
            hoveredWidget = nullptr;
        //}

        if (hoveredWidget != m_hoveredWidget) {
            const UIWidgetPtr oldHovered = m_hoveredWidget;
            m_hoveredWidget = hoveredWidget;
            if (oldHovered) {
                oldHovered->updateState(Fw::HoverState);
                oldHovered->onHoverChange(false);
            }
            if (hoveredWidget) {
                hoveredWidget->updateState(Fw::HoverState);
                hoveredWidget->onHoverChange(true);
            }
        }
    };

    if (now)
        func();
    else {
        m_hoverUpdateScheduled = true;
        g_dispatcher.addEvent(func);
    }
}

void UIManager::onWidgetAppear(const UIWidgetPtr& widget)
{
    if (widget->containsPoint(g_window.getMousePosition()))
        updateHoveredWidget();
}

void UIManager::onWidgetDisappear(const UIWidgetPtr& widget)
{
    if (widget->containsPoint(g_window.getMousePosition()))
        updateHoveredWidget();
}

void UIManager::onWidgetDestroy(const UIWidgetPtr& widget)
{
    // release input grabs
    if (m_keyboardReceiver == widget)
        resetKeyboardReceiver();

    if (m_mouseReceiver == widget)
        resetMouseReceiver();

    if (m_hoveredWidget == widget)
        updateHoveredWidget();

    if (m_pressedWidget == widget)
        updatePressedWidget(nullptr);

    if (m_draggingWidget == widget)
        updateDraggingWidget(nullptr);

    if (widget == m_rootWidget || !m_rootWidget)
        return;

    m_destroyedWidgets.emplace_back(widget);

    if (m_checkEvent && !m_checkEvent->isExecuted())
        return;

    m_checkEvent = g_dispatcher.scheduleEvent([this] {
        g_lua.collectGarbage();
        UIWidgetList backupList = m_destroyedWidgets;
        m_destroyedWidgets.clear();
        g_dispatcher.scheduleEvent([backupList] {
            g_lua.collectGarbage();
            for (const auto& widget : backupList) {
                if (widget.use_count() != 1)
                    g_logger.warning(stdext::format("widget '%s' destroyed but still have %d reference(s) left", widget->getId(), widget.use_count() - 1));
            }
        }, 1);
    }, 1000);
}

void UIManager::clearStyles()
{
    m_styles.clear();
}

bool UIManager::importStyle(const std::string& fl, bool checkDeviceStyles)
{
    const std::string file{ g_resources.guessFilePath(fl, "otui") };
    try {
        const auto& doc = OTMLDocument::parse(file);

        for (const auto& styleNode : doc->children())
            importStyleFromOTML(styleNode);
    } catch (stdext::exception& e) {
        g_logger.error(stdext::format("Failed to import UI styles from '%s': %s", file, e.what()));
        return false;
    }

    if (checkDeviceStyles) {
        // check for device styles
        auto fileName = fl.substr(0, fl.find("."));

        auto deviceName = g_platform.getDeviceShortName();
        if (!deviceName.empty())
            importStyle(deviceName + "." + fileName, false);

        auto osName = g_platform.getOsShortName();
        if (!osName.empty())
            importStyle(osName + "." + fileName, false);
    }

    return true;
}

void UIManager::importStyleFromOTML(const OTMLNodePtr& styleNode)
{
    const std::string tag = styleNode->tag();
    const std::vector<std::string> split = stdext::split(tag, "<");
    if (split.size() != 2)
        throw OTMLException(styleNode, "not a valid style declaration");

    std::string name = split[0];
    std::string base = split[1];
    bool unique = false;

    stdext::trim(name);
    stdext::trim(base);

    if (name[0] == '#') {
        name = name.substr(1);
        unique = true;

        styleNode->setTag(name);
        styleNode->writeAt("__unique", true);
    }

    const auto oldStyle = m_styles[name];

    // Warn about redefined styles
    /*
    if(!g_app.isRunning() && (oldStyle && !oldStyle->valueAt("__unique", false))) {
        auto it = m_styles.find(name);
        if(it != m_styles.end())
            g_logger.warning(stdext::format("style '%s' is being redefined", name));
    }
    */

    if (!oldStyle || !oldStyle->valueAt("__unique", false) || unique) {
        const auto& originalStyle = getStyle(base);
        if (!originalStyle)
            throw Exception("base style '%s', is not defined", base);

        const auto& style = originalStyle->clone();
        style->merge(styleNode);
        style->setTag(name);
        m_styles[name] = style;
    }
}

void UIManager::importStyleFromOTML(const OTMLDocumentPtr& doc)
{
    for (const auto& node : doc->children()) {
        std::string tag = node->tag();

        // import styles in these files too
        if (tag.find('<') != std::string::npos)
            importStyleFromOTML(node);
    }
}

OTMLNodePtr UIManager::getStyle(const std::string_view sn)
{
    const auto* styleName = sn.data();
    const auto it = m_styles.find(styleName);
    if (it != m_styles.end())
        return m_styles[styleName];

    // styles starting with UI are automatically defined
    if (sn.starts_with("UI")) {
        const auto& node = OTMLNode::create(styleName);
        node->writeAt("__class", styleName);
        m_styles[styleName] = node;

        return node;
    }

    return nullptr;
}

std::string UIManager::getStyleClass(const std::string_view styleName)
{
    if (const auto& style = getStyle(styleName)) {
        if (style->get("__class"))
            return style->valueAt("__class");
    }
    return "";
}

OTMLNodePtr UIManager::findMainWidgetNode(const OTMLDocumentPtr& doc)
{
    OTMLNodePtr mainNode = nullptr;
    for (const auto& node : doc->children()) {
        std::string tag = node->tag();

        if (tag.find('<') == std::string::npos) {
            if (mainNode)
                throw Exception("cannot have multiple main widgets in otui files");
            mainNode = node;
        }
    }
    return mainNode;
}

OTMLNodePtr UIManager::loadDeviceUI(const std::string& file, Platform::OperatingSystem os)
{
    auto rawName = file.substr(0, file.find("."));
    auto osName = g_platform.getOsShortName(os);

    const auto& doc = OTMLDocument::parse(g_resources.guessFilePath(rawName + "." + osName, "otui"));
    if (doc) {
        g_logger.info(stdext::format("found os style '%s' for '%s'", osName, rawName));
        importStyleFromOTML(doc);
        return findMainWidgetNode(doc);
    }
    return nullptr;
}

OTMLNodePtr UIManager::loadDeviceUI(const std::string& file, Platform::DeviceType deviceType)
{
    auto rawName = file.substr(0, file.find("."));
    auto deviceName = g_platform.getDeviceShortName(deviceType);

    const auto& doc = OTMLDocument::parse(g_resources.guessFilePath(rawName + "." + deviceName, "otui"));
    if (doc) {
        g_logger.info(stdext::format("found device style '%s' for '%s'", deviceName, rawName));
        importStyleFromOTML(doc);
        return findMainWidgetNode(doc);
    }
    return nullptr;
}

UIWidgetPtr UIManager::loadUI(const std::string& file, const UIWidgetPtr& parent)
{
    try {
        OTMLNodePtr widgetNode = nullptr;
        const auto& doc = OTMLDocument::parse(g_resources.guessFilePath(file, "otui"));

        for (const auto& node : doc->children()) {
            std::string tag = node->tag();

            // import styles in these files too
            if (tag.find('<') != std::string::npos)
                importStyleFromOTML(node);
            else {
                if (widgetNode)
                    throw Exception("cannot have multiple main widgets in otui files");
                widgetNode = node;
            }
        }

        // load device styles and widget
        auto device = g_platform.getDevice();
        try {
            const auto& deviceWidgetNode = loadDeviceUI(file, device.type);
            if (deviceWidgetNode)
                widgetNode = deviceWidgetNode;
        } catch (stdext::exception& e) {
            g_logger.fine(stdext::format("no device ui found for '%s', reason: '%s'", file, e.what()));
        }
        try {
            auto osWidgetNode = loadDeviceUI(file, device.os);
            if (osWidgetNode)
                widgetNode = osWidgetNode;
        } catch (stdext::exception& e) {
            g_logger.fine(stdext::format("no os ui found for '%s', reason: '%s'", file, e.what()));
        }

        if (!widgetNode) {
            g_logger.debug(stdext::format("failed to load a widget from '%s'", file));
            return nullptr;
        }

        return createWidgetFromOTML(widgetNode, parent);
    } catch (stdext::exception& e) {
        g_logger.error(stdext::format("failed to load UI from '%s': %s", file, e.what()));
        return nullptr;
    }
}

UIWidgetPtr UIManager::createWidget(const std::string_view styleName, const UIWidgetPtr& parent)
{
    const auto& node = OTMLNode::create(styleName);
    try {
        return createWidgetFromOTML(node, parent);
    } catch (stdext::exception& e) {
        g_logger.error(stdext::format("failed to create widget from style '%s': %s", styleName, e.what()));
        return nullptr;
    }
}

UIWidgetPtr UIManager::createWidgetFromOTML(const OTMLNodePtr& widgetNode, const UIWidgetPtr& parent)
{
    const auto& originalStyleNode = getStyle(widgetNode->tag());
    if (!originalStyleNode)
        throw Exception("'%s' is not a defined style", widgetNode->tag());

    const auto& styleNode = originalStyleNode->clone();
    styleNode->merge(widgetNode);

    const std::string widgetType = styleNode->valueAt("__class");

    // call widget creation from lua
    const auto& widget = g_lua.callGlobalField<UIWidgetPtr>(widgetType, "create");
    if (!widget)
        throw Exception("unable to create widget of type '%s'", widgetType);

    if (parent)
        parent->addChild(widget);

    widget->callLuaField("onCreate");

    widget->setStyleFromNode(styleNode);

    for (const auto& childNode : styleNode->children()) {
        if (!childNode->isUnique()) {
            createWidgetFromOTML(childNode, widget);
            styleNode->removeChild(childNode);
        }
    }

    widget->callLuaField("onSetup");
    return widget;
}