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

#pragma once

#include "declarations.h"
#include "uilayout.h"

#include <framework/core/timer.h>
#include <framework/graphics/bitmapfont.h>
#include <framework/graphics/declarations.h>
#include <framework/luaengine/luaobject.h>
#include <framework/otml/otmlnode.h>

#include "framework/graphics/drawpool.h"
#include "framework/graphics/texture.h"

template<typename T = int>
struct EdgeGroup
{
    EdgeGroup() { top = right = bottom = left = T(0); }
    void set(T value) { top = right = bottom = left = value; }
    T top;
    T right;
    T bottom;
    T left;
};

enum FlagProp : uint32_t
{
    PropTextWrap = 1 << 0,
    PropTextVerticalAutoResize = 1 << 1,
    PropTextHorizontalAutoResize = 1 << 2,
    PropTextOnlyUpperCase = 1 << 3,
    PropEnabled = 1 << 4,
    PropVisible = 1 << 5,
    PropFocusable = 1 << 6,
    PropFixedSize = 1 << 7,
    PropPhantom = 1 << 8,
    PropDraggable = 1 << 9,
    PropDestroyed = 1 << 10,
    PropClipping = 1 << 11,
    PropCustomId = 1 << 12,
    PropUpdateEventScheduled = 1 << 13,
    PropUpdatingMove = 1 << 14,
    PropLoadingStyle = 1 << 15,
    PropUpdateStyleScheduled = 1 << 16,
    PropFirstOnStyle = 1 << 17,
    PropImageBordered = 1 << 18,
    PropImageFixedRatio = 1 << 19,
    PropImageRepeated = 1 << 20,
    PropImageSmooth = 1 << 21,
    PropImageAutoResize = 1 << 22,
    PropImageIndividualAnimation = 1 << 23,
    PropUpdateChildrenIndexStates = 1 << 24,
    PropDisableUpdateTemporarily = 1 << 25,
    PropOnHTML = 1 << 26
};

// @bindclass
class UIWidget : public LuaObject
{
    // widget core
public:
    UIWidget();
    ~UIWidget() override;
    virtual void drawSelf(DrawPoolType drawPane);
    virtual void draw(const Rect& visibleRect, DrawPoolType drawPane);
protected:
    virtual void drawChildren(const Rect& visibleRect, DrawPoolType drawPane);

    friend class UIManager;

    std::string m_id;
    std::string m_source;
    int16_t m_childIndex{ -1 };

    Rect m_rect;
    Point m_virtualOffset;
    Size m_minSize;
    Size m_maxSize;

    UILayoutPtr m_layout;
    UIWidgetPtr m_parent;
    UIWidgetList m_children;
    UIWidgetList m_lockedChildren;
    UIWidgetPtr m_focusedChild;
    OTMLNodePtr m_style;

    stdext::map<std::string, UIWidgetPtr> m_childrenById;
    std::unordered_map<std::string, std::function<void()>> m_onDestroyCallbacks;

    Timer m_clickTimer;
    Fw::FocusReason m_lastFocusReason{ Fw::ActiveFocusReason };
    Fw::AutoFocusPolicy m_autoFocusPolicy{ Fw::AutoFocusLast };

    friend class UIGridLayout;
    friend class UIHorizontalLayout;
    friend class UIVerticalLayout;

public:
    void addChild(const UIWidgetPtr& child);
    void insertChild(int32_t index, const UIWidgetPtr& child);
    void removeChild(const UIWidgetPtr& child);
    void focusChild(const UIWidgetPtr& child, Fw::FocusReason reason);
    void focusNextChild(Fw::FocusReason reason, bool rotate = false);
    void focusPreviousChild(Fw::FocusReason reason, bool rotate = false);
    void lowerChild(const UIWidgetPtr& child);
    void raiseChild(const UIWidgetPtr& child);
    void moveChildToIndex(const UIWidgetPtr& child, int index);
    void reorderChildren(const std::vector<UIWidgetPtr>& childrens);
    void lockChild(const UIWidgetPtr& child);
    void unlockChild(const UIWidgetPtr& child);
    void mergeStyle(const OTMLNodePtr& styleNode);
    void applyStyle(const OTMLNodePtr& styleNode);
    void addAnchor(Fw::AnchorEdge anchoredEdge, std::string_view hookedWidgetId, Fw::AnchorEdge hookedEdge);
    void removeAnchor(Fw::AnchorEdge anchoredEdge);
    void fill(std::string_view hookedWidgetId);
    void centerIn(std::string_view hookedWidgetId);
    void breakAnchors();
    void updateParentLayout();
    void updateLayout();
    void lock();
    void unlock();
    void focus();
    void recursiveFocus(Fw::FocusReason reason);
    void lower();
    void raise();
    void grabMouse();
    void ungrabMouse();
    void grabKeyboard();
    void ungrabKeyboard();
    void bindRectToParent();
    void destroy();
    void destroyChildren();
    void removeChildren();
    void hideChildren();
    void showChildren();

    void setId(std::string_view id);
    void setParent(const UIWidgetPtr& parent);
    void setLayout(const UILayoutPtr& layout);
    bool setRect(const Rect& rect);
    void setStyle(std::string_view styleName);
    void setStyleFromNode(const OTMLNodePtr& styleNode);
    void setEnabled(bool enabled);
    void setVisible(bool visible);
    void setOn(bool on);
    void setChecked(bool checked);
    void setFocusable(bool focusable);
    void setPhantom(bool phantom);
    void setDraggable(bool draggable);
    void setFixedSize(bool fixed);
    void setClipping(const bool clipping) { setProp(PropClipping, clipping); }
    void setLastFocusReason(Fw::FocusReason reason);
    void setAutoFocusPolicy(Fw::AutoFocusPolicy policy);
    void setAutoRepeatDelay(const int delay) { m_autoRepeatDelay = delay; }
    void setVirtualOffset(const Point& offset);

    void setOnHtml(const bool v) { setProp(PropOnHTML, v); }
    bool isOnHtml() { return hasProp(PropOnHTML); }

    bool isAnchored();
    bool isChildLocked(const UIWidgetPtr& child);
    bool hasChild(const UIWidgetPtr& child);
    int getChildIndex(const UIWidgetPtr& child = nullptr) { return child ? (child->getParent().get() == this ? child->m_childIndex : -1) : m_childIndex; }
    Rect getPaddingRect();
    Rect getMarginRect();
    Rect getChildrenRect();
    UIAnchorLayoutPtr getAnchoredLayout();
    UIAnchorList getAnchorsGroup();
    std::vector<Fw::AnchorEdge> getAnchors();
    Fw::AnchorEdge getAnchorType(Fw::AnchorEdge anchorType);
    bool hasAnchoredLayout() { return getAnchoredLayout() != nullptr; }
    UIWidgetPtr getRootParent();
    UIWidgetPtr getNextWidget() {
        const auto& parent = getParent();
        return parent && parent->getChildCount() > getChildIndex() ? parent->getChildByIndex(getChildIndex() + 1) : nullptr;
    }
    UIWidgetPtr getPrevWidget() {
        const auto& parent = getParent();
        return parent && getChildIndex() > 1 ? parent->getChildByIndex(getChildIndex() - 1) : nullptr;
    }

    UIWidgetPtr getChildAfter(const UIWidgetPtr& relativeChild);
    UIWidgetPtr getChildBefore(const UIWidgetPtr& relativeChild);
    UIWidgetPtr getChildById(std::string_view childId);
    UIWidgetPtr getChildByPos(const Point& childPos);
    UIWidgetPtr getChildByIndex(int index);
    UIWidgetPtr getChildByState(Fw::WidgetState state);
    UIWidgetPtr getChildByStyleName(std::string_view styleName);
    UIWidgetPtr recursiveGetChildById(std::string_view id);
    UIWidgetPtr recursiveGetChildByPos(const Point& childPos, bool wantsPhantom);
    UIWidgetPtr recursiveGetChildByState(Fw::WidgetState state, bool wantsPhantom);
    UIWidgetList recursiveGetChildren();
    UIWidgetList recursiveGetChildrenByPos(const Point& childPos);
    UIWidgetList recursiveGetChildrenByMarginPos(const Point& childPos);
    UIWidgetList recursiveGetChildrenByState(Fw::WidgetState state);
    UIWidgetList recursiveGetChildrenByStyleName(std::string_view styleName);
    UIWidgetPtr backwardsGetWidgetById(std::string_view id);

    void setShader(std::string_view name);
    bool hasShader() { return m_shader != nullptr; }

    void setProp(FlagProp prop, bool v, bool callEvent = false);
    bool hasProp(const FlagProp prop) { return (m_flagsProp & prop); }

    void disableUpdateTemporarily();
    void addOnDestroyCallback(const std::string& id, const std::function<void()>&& callback);
    void removeOnDestroyCallback(const std::string&);

    void setBackgroundDrawOrder(const uint8_t order) { m_backgroundDrawConductor.order = std::min<uint8_t>(order, LAST - 1); }
    void setImageDrawOrder(const uint8_t order) { m_imageDrawConductor.order = std::min<uint8_t>(order, LAST - 1); }
    void setIconDrawOrder(const uint8_t order) { m_iconDrawConductor.order = std::min<uint8_t>(order, LAST - 1); }
    void setTextDrawOrder(const uint8_t order) { m_textDrawConductor.order = std::min<uint8_t>(order, LAST - 1); }
    void setBorderDrawOrder(const uint8_t order) { m_borderDrawConductor.order = std::min<uint8_t>(order, LAST - 1); }

private:
    uint32_t m_flagsProp{ 0 };
    PainterShaderProgramPtr m_shader;

    DrawConductor m_backgroundDrawConductor;
    DrawConductor m_imageDrawConductor;
    DrawConductor m_iconDrawConductor;
    DrawConductor m_borderDrawConductor;

    // state managment
protected:
    void repaint();
    bool setState(Fw::WidgetState state, bool on);
    bool hasState(Fw::WidgetState state);

private:
    void internalDestroy();
    void updateState(Fw::WidgetState state);
    void updateStates();
    void updateChildrenIndexStates();
    void updateStyle();

    OTMLNodePtr m_stateStyle;
    int32_t m_states{ Fw::DefaultState };

    // event processing
protected:
    virtual void onStyleApply(std::string_view styleName, const OTMLNodePtr& styleNode);
    virtual void onGeometryChange(const Rect& oldRect, const Rect& newRect);
    virtual void onLayoutUpdate();
    virtual void onFocusChange(bool focused, Fw::FocusReason reason);
    virtual void onChildFocusChange(const UIWidgetPtr& focusedChild, const UIWidgetPtr& unfocusedChild, Fw::FocusReason reason);
    virtual void onHoverChange(bool hovered);
    virtual void onVisibilityChange(bool visible);
    virtual bool onDragEnter(const Point& mousePos);
    virtual bool onDragLeave(UIWidgetPtr droppedWidget, const Point& mousePos);
    virtual bool onDragMove(const Point& mousePos, const Point& mouseMoved);
    virtual bool onDrop(UIWidgetPtr draggedWidget, const Point& mousePos);
    virtual bool onKeyText(std::string_view keyText);
    virtual bool onKeyDown(uint8_t keyCode, int keyboardModifiers);
    virtual bool onKeyPress(uint8_t keyCode, int keyboardModifiers, int autoRepeatTicks);
    virtual bool onKeyUp(uint8_t keyCode, int keyboardModifiers);
    virtual bool onMousePress(const Point& mousePos, Fw::MouseButton button);
    virtual bool onMouseRelease(const Point& mousePos, Fw::MouseButton button);
    virtual bool onMouseMove(const Point& mousePos, const Point& mouseMoved);
    virtual bool onMouseWheel(const Point& mousePos, Fw::MouseWheelDirection direction);
    virtual bool onClick(const Point& mousePos);
    virtual bool onDoubleClick(const Point& mousePos);

    friend class UILayout;

    bool propagateOnKeyText(std::string_view keyText);
    bool propagateOnKeyDown(uint8_t keyCode, int keyboardModifiers);
    bool propagateOnKeyPress(uint8_t keyCode, int keyboardModifiers, int autoRepeatTicks);
    bool propagateOnKeyUp(uint8_t keyCode, int keyboardModifiers);
    bool propagateOnMouseEvent(const Point& mousePos, UIWidgetList& widgetList);
    bool propagateOnMouseMove(const Point& mousePos, const Point& mouseMoved, UIWidgetList& widgetList);

    // function shortcuts
public:
    void resize(const int width, const int height) { setRect(Rect(getPosition(), Size(width, height))); }
    void move(int x, int y);
    void rotate(const float degrees) { setRotation(degrees); }
    void hide() { setVisible(false); }
    void show() { setVisible(true); }
    void disable() { setEnabled(false); }
    void enable() { setEnabled(true); }

    bool isActive() { return hasState(Fw::ActiveState); }
    bool isEnabled() { return !hasState(Fw::DisabledState); }
    bool isDisabled() { return hasState(Fw::DisabledState); }
    bool isFocused() { return hasState(Fw::FocusState); }
    bool isHovered(const bool orChild = false) { return hasState(Fw::HoverState) || (orChild && isChildHovered()); }
    bool isChildHovered() { return getHoveredChild() != nullptr; }
    bool isPressed() { return hasState(Fw::PressedState); }
    bool isFirst() { return hasState(Fw::FirstState); }
    bool isMiddle() { return hasState(Fw::MiddleState); }
    bool isLast() { return hasState(Fw::LastState); }
    bool isAlternate() { return hasState(Fw::AlternateState); }
    bool isChecked() { return hasState(Fw::CheckedState); }
    bool isOn() { return hasState(Fw::OnState); }
    bool isDragging() { return hasState(Fw::DraggingState); }
    bool isVisible() { return !hasState(Fw::HiddenState); }
    bool isHidden() { return hasState(Fw::HiddenState); }
    bool isExplicitlyEnabled() { return hasProp(PropEnabled); }
    bool isExplicitlyVisible() { return hasProp(PropVisible); }
    bool isFocusable() { return hasProp(PropFocusable); }
    bool isPhantom() { return hasProp(PropPhantom); }
    bool isDraggable() { return hasProp(PropDraggable); }
    bool isFixedSize() { return hasProp(PropFixedSize); }
    bool isClipping() { return hasProp(PropClipping); }
    bool isDestroyed() { return hasProp(PropDestroyed); }
    bool isFirstOnStyle() { return hasProp(PropFirstOnStyle); }

    bool isFirstChild() { return m_parent && m_childIndex == 1; }
    bool isLastChild() { return m_parent && m_childIndex == static_cast<int32_t>(m_parent->m_children.size()); }
    bool isMiddleChild() { return !isFirstChild() && !isLastChild(); }

    bool hasChildren() { return !m_children.empty(); }
    bool containsMarginPoint(const Point& point) { return getMarginRect().contains(point); }
    bool containsPaddingPoint(const Point& point) { return getPaddingRect().contains(point); }
    bool containsPoint(const Point& point) { return m_rect.contains(point); }
    bool intersects(const Rect rect) { return m_rect.intersects(rect); }
    bool intersectsMargin(const Rect rect) { return getMarginRect().intersects(rect); }
    bool intersectsPadding(const Rect rect) { return getPaddingRect().intersects(rect); }

    std::string getId() { return m_id; }
    std::string getSource() { return m_source; }
    UIWidgetPtr getParent() { return m_parent; }
    UIWidgetPtr getFocusedChild() { return m_focusedChild; }
    UIWidgetPtr getHoveredChild();
    UIWidgetList getChildren() { return m_children; }
    UIWidgetPtr getFirstChild() { return getChildByIndex(1); }
    UIWidgetPtr getLastChild() { return getChildByIndex(-1); }
    UILayoutPtr getLayout() { return m_layout; }
    OTMLNodePtr getStyle() { return m_style; }
    int getChildCount() { return m_children.size(); }
    Fw::FocusReason getLastFocusReason() { return m_lastFocusReason; }
    Fw::AutoFocusPolicy getAutoFocusPolicy() { return m_autoFocusPolicy; }
    int getAutoRepeatDelay() { return m_autoRepeatDelay; }
    Point getVirtualOffset() { return m_virtualOffset; }
    std::string getStyleName() { return m_style->tag(); }
    Point getLastClickPosition() { return m_lastClickPosition; }

    // base style
private:
    void initBaseStyle();
    void parseBaseStyle(const OTMLNodePtr& styleNode);

protected:
    void drawBackground(const Rect& screenCoords) const;
    void drawBorder(const Rect& screenCoords) const;
    void drawIcon(const Rect& screenCoords) const;

    Color m_color{ Color::white };
    Color m_backgroundColor{ Color::alpha };
    Rect m_backgroundRect;
    TexturePtr m_icon;
    Color m_iconColor{ Color::white };
    Rect m_iconRect;
    Rect m_iconClipRect;
    Fw::AlignmentFlag m_iconAlign{ Fw::AlignNone };
    EdgeGroup<Color> m_borderColor;
    EdgeGroup<> m_borderWidth;
    EdgeGroup<> m_margin;
    EdgeGroup<> m_padding;
    float m_opacity{ 1.f };
    float m_rotation{ 0.f };
    uint16_t m_autoRepeatDelay{ 500 };
    Point m_lastClickPosition;

    DrawConductor m_textDrawConductor;

public:
    void setX(const int x) { move(x, getY()); }
    void setY(const int y) { move(getX(), y); }
    void setWidth(const int width) { resize(width, getHeight()); }
    void setHeight(const int height) { resize(getWidth(), height); }
    void setSize(const Size& size) { resize(size.width(), size.height()); }
    void setMinWidth(const int minWidth) { m_minSize.setWidth(minWidth); setRect(m_rect); }
    void setMaxWidth(const int maxWidth) { m_maxSize.setWidth(maxWidth); setRect(m_rect); }
    void setMinHeight(const int minHeight) { m_minSize.setHeight(minHeight); setRect(m_rect); }
    void setMaxHeight(const int maxHeight) { m_maxSize.setHeight(maxHeight); setRect(m_rect); }
    void setMinSize(const Size& minSize) { m_minSize = minSize; setRect(m_rect); }
    void setMaxSize(const Size& maxSize) { m_maxSize = maxSize; setRect(m_rect); }
    void setPosition(const Point& pos) { move(pos.x, pos.y); }
    void setColor(const Color& color) { m_color = color; repaint(); }
    void setBackgroundColor(const Color& color) { m_backgroundColor = color; repaint(); }
    void setBackgroundOffsetX(const int x) { m_backgroundRect.setX(x); repaint(); }
    void setBackgroundOffsetY(const int y) { m_backgroundRect.setX(y); repaint(); }
    void setBackgroundOffset(const Point& pos) { m_backgroundRect.move(pos); repaint(); }
    void setBackgroundWidth(const int width) { m_backgroundRect.setWidth(width); repaint(); }
    void setBackgroundHeight(const int height) { m_backgroundRect.setHeight(height); repaint(); }
    void setBackgroundSize(const Size& size) { m_backgroundRect.resize(size); repaint(); }
    void setBackgroundRect(const Rect& rect) { m_backgroundRect = rect; repaint(); }
    void setIcon(const std::string& iconFile);
    void setIconColor(const Color& color) { m_iconColor = color; repaint(); }
    void setIconOffsetX(const int x) { m_iconOffset.x = x; repaint(); }
    void setIconOffsetY(const int y) { m_iconOffset.y = y; repaint(); }
    void setIconOffset(const Point& pos) { m_iconOffset = pos; repaint(); }
    void setIconWidth(const int width) { m_iconRect.setWidth(width); repaint(); }
    void setIconHeight(const int height) { m_iconRect.setHeight(height); repaint(); }
    void setIconSize(const Size& size) { m_iconRect.resize(size); repaint(); }
    void setIconRect(const Rect& rect) { m_iconRect = rect; repaint(); }
    void setIconClip(const Rect& rect) { m_iconClipRect = rect; repaint(); }
    void setIconAlign(const Fw::AlignmentFlag align) { m_iconAlign = align; repaint(); }
    void setBorderWidth(const int width) { m_borderWidth.set(width); updateLayout(); }
    void setBorderWidthTop(const int width) { m_borderWidth.top = width; repaint(); }
    void setBorderWidthRight(const int width) { m_borderWidth.right = width; repaint(); }
    void setBorderWidthBottom(const int width) { m_borderWidth.bottom = width; repaint(); }
    void setBorderWidthLeft(const int width) { m_borderWidth.left = width; repaint(); }
    void setBorderColor(const Color& color) { m_borderColor.set(color); updateLayout(); }
    void setBorderColorTop(const Color& color) { m_borderColor.top = color; repaint(); }
    void setBorderColorRight(const Color& color) { m_borderColor.right = color; repaint(); }
    void setBorderColorBottom(const Color& color) { m_borderColor.bottom = color; repaint(); }
    void setBorderColorLeft(const Color& color) { m_borderColor.left = color; repaint(); }
    void setMargin(const int margin) { m_margin.set(margin); updateParentLayout(); }
    void setMarginHorizontal(const int margin) { m_margin.right = m_margin.left = margin; updateParentLayout(); }
    void setMarginVertical(const int margin) { m_margin.bottom = m_margin.top = margin; updateParentLayout(); }
    void setMarginTop(const int margin) { m_margin.top = margin; updateParentLayout(); }
    void setMarginRight(const int margin) { m_margin.right = margin; updateParentLayout(); }
    void setMarginBottom(const int margin) { m_margin.bottom = margin; updateParentLayout(); }
    void setMarginLeft(const int margin) { m_margin.left = margin; updateParentLayout(); }
    void setPadding(const int padding) { m_padding.top = m_padding.right = m_padding.bottom = m_padding.left = padding; updateLayout(); }
    void setPaddingHorizontal(const int padding) { m_padding.right = m_padding.left = padding; updateLayout(); }
    void setPaddingVertical(const int padding) { m_padding.bottom = m_padding.top = padding; updateLayout(); }
    void setPaddingTop(const int padding) { m_padding.top = padding; updateLayout(); }
    void setPaddingRight(const int padding) { m_padding.right = padding; updateLayout(); }
    void setPaddingBottom(const int padding) { m_padding.bottom = padding; updateLayout(); }
    void setPaddingLeft(const int padding) { m_padding.left = padding; updateLayout(); }
    void setOpacity(const float opacity) { m_opacity = std::clamp<float>(opacity, 0.0f, 1.0f); repaint(); }
    void setRotation(const float degrees) { m_rotation = degrees; repaint(); }

    int getX() { return m_rect.x(); }
    int getY() { return m_rect.y(); }
    Point getPosition() { return m_rect.topLeft(); }
    Point getCenter() { return m_rect.center(); }
    int getWidth() { return m_rect.width(); }
    int getHeight() { return m_rect.height(); }
    Size getSize() { return m_rect.size(); }
    int getMinWidth() { return m_minSize.width(); }
    int getMaxWidth() { return m_maxSize.width(); }
    int getMinHeight() { return m_minSize.height(); }
    int getMaxHeight() { return m_maxSize.height(); }
    Size getMinSize() { return m_minSize; }
    Size getMaxSize() { return m_maxSize; }
    Rect getRect() { return m_rect; }
    Color getColor() { return m_color; }
    Color getBackgroundColor() { return m_backgroundColor; }
    int getBackgroundOffsetX() { return m_backgroundRect.x(); }
    int getBackgroundOffsetY() { return m_backgroundRect.y(); }
    Point getBackgroundOffset() { return m_backgroundRect.topLeft(); }
    int getBackgroundWidth() { return m_backgroundRect.width(); }
    int getBackgroundHeight() { return m_backgroundRect.height(); }
    Size getBackgroundSize() { return m_backgroundRect.size(); }
    Rect getBackgroundRect() { return m_backgroundRect; }
    Color getIconColor() { return m_iconColor; }
    int getIconOffsetX() { return m_iconRect.x(); }
    int getIconOffsetY() { return m_iconRect.y(); }
    Point getIconOffset() { return m_iconRect.topLeft(); }
    int getIconWidth() { return m_iconRect.width(); }
    int getIconHeight() { return m_iconRect.height(); }
    Size getIconSize() { return m_iconRect.size(); }
    Rect getIconRect() { return m_iconRect; }
    Rect getIconClip() { return m_iconClipRect; }
    Fw::AlignmentFlag getIconAlign() { return m_iconAlign; }
    Color getBorderTopColor() { return m_borderColor.top; }
    Color getBorderRightColor() { return m_borderColor.right; }
    Color getBorderBottomColor() { return m_borderColor.bottom; }
    Color getBorderLeftColor() { return m_borderColor.left; }
    int getBorderTopWidth() { return m_borderWidth.top; }
    int getBorderRightWidth() { return m_borderWidth.right; }
    int getBorderBottomWidth() { return m_borderWidth.bottom; }
    int getBorderLeftWidth() { return m_borderWidth.left; }
    int getMarginTop() { return m_margin.top; }
    int getMarginRight() { return m_margin.right; }
    int getMarginBottom() { return m_margin.bottom; }
    int getMarginLeft() { return m_margin.left; }
    int getPaddingTop() { return m_padding.top; }
    int getPaddingRight() { return m_padding.right; }
    int getPaddingBottom() { return m_padding.bottom; }
    int getPaddingLeft() { return m_padding.left; }
    Size getPaddingSize() { return { m_padding.left + m_padding.right, m_padding.top + m_padding.bottom }; }
    float getOpacity() { return m_opacity; }
    float getRotation() { return m_rotation; }

    // image
private:
    void initImage();
    void parseImageStyle(const OTMLNodePtr& styleNode);

    void updateImageCache() { if (!m_imageCachedScreenCoords.isNull()) m_imageCachedScreenCoords = {}; }
    void configureBorderImage() { setProp(PropImageBordered, true); updateImageCache(); }

    std::vector<std::pair<Rect, Rect>> m_imageCoordsCache;

    Rect m_imageCachedScreenCoords;

protected:
    void drawImage(const Rect& screenCoords);
    std::string m_imageSource;

    TexturePtr m_imageTexture;
    Rect m_imageClipRect;
    Rect m_imageRect;
    Color m_imageColor{ Color::white };
    Point m_iconOffset;
    Timer m_imageAnimatorTimer;
    uint32_t m_currentFrame{ 0 };

    EdgeGroup<> m_imageBorder;

public:
    void setImageSource(std::string_view source, bool base64);
    void setImageClip(const Rect& clipRect) { m_imageClipRect = clipRect; updateImageCache(); }
    void setImageOffsetX(const int x) { m_imageRect.setX(x); updateImageCache(); }
    void setImageOffsetY(const int y) { m_imageRect.setY(y); updateImageCache(); }
    void setImageOffset(const Point& pos) { m_imageRect.move(pos); updateImageCache(); }
    void setImageWidth(const int width) { m_imageRect.setWidth(width); updateImageCache(); }
    void setImageHeight(const int height) { m_imageRect.setHeight(height); updateImageCache(); }
    void setImageSize(const Size& size) { m_imageRect.resize(size); updateImageCache(); }
    void setImageRect(const Rect& rect) { m_imageRect = rect; updateImageCache(); }
    void setImageColor(const Color& color) { m_imageColor = color; updateImageCache(); }
    void setImageFixedRatio(const bool fixedRatio) { setProp(PropImageFixedRatio, fixedRatio); updateImageCache(); }
    void setImageRepeated(const bool repeated) { setProp(PropImageRepeated, repeated); updateImageCache(); }
    void setImageSmooth(const bool smooth) { setProp(PropImageSmooth, smooth); }
    void setImageAutoResize(const bool autoResize) { setProp(PropImageAutoResize, autoResize); }
    void setImageIndividualAnimation(const bool v) { setProp(PropImageIndividualAnimation, v); }
    void setImageBorderTop(const int border) { m_imageBorder.top = border; configureBorderImage(); }
    void setImageBorderRight(const int border) { m_imageBorder.right = border; configureBorderImage(); }
    void setImageBorderBottom(const int border) { m_imageBorder.bottom = border; configureBorderImage(); }
    void setImageBorderLeft(const int border) { m_imageBorder.left = border; configureBorderImage(); }
    void setImageBorder(const int border) { m_imageBorder.set(border); configureBorderImage(); }

    std::string getImageSource() { return m_imageSource; }
    Rect getImageClip() { return m_imageClipRect; }
    int getImageOffsetX() { return m_imageRect.x(); }
    int getImageOffsetY() { return m_imageRect.y(); }
    Point getImageOffset() { return m_imageRect.topLeft(); }
    int getImageWidth() { return m_imageRect.width(); }
    int getImageHeight() { return m_imageRect.height(); }
    Size getImageSize() { return m_imageRect.size(); }
    Rect getImageRect() { return m_imageRect; }
    Color getImageColor() { return m_imageColor; }
    bool isImageFixedRatio() { return hasProp(PropImageFixedRatio); }
    bool isImageSmooth() { return hasProp(PropImageSmooth); }
    bool isImageAutoResize() { return hasProp(PropImageAutoResize); }
    bool isImageIndividualAnimation() { return hasProp(PropImageIndividualAnimation); }
    int getImageBorderTop() { return m_imageBorder.top; }
    int getImageBorderRight() { return m_imageBorder.right; }
    int getImageBorderBottom() { return m_imageBorder.bottom; }
    int getImageBorderLeft() { return m_imageBorder.left; }
    int getImageTextureWidth() { return m_imageTexture ? m_imageTexture->getWidth() : 0; }
    int getImageTextureHeight() { return m_imageTexture ? m_imageTexture->getHeight() : 0; }

    // text related
private:
    void initText();
    void parseTextStyle(const OTMLNodePtr& styleNode);

    Rect m_textCachedScreenCoords;
    std::vector<Point> m_glyphsPositionsCache;
    Size m_textSize;

protected:
    virtual void updateText();
    void drawText(const Rect& screenCoords);

    virtual void onTextChange(std::string_view text, std::string_view oldText);
    virtual void onFontChange(std::string_view font);

    std::string m_text;
    std::string m_drawText;
    Fw::AlignmentFlag m_textAlign;
    Point m_textOffset;

    BitmapFontPtr m_font;
    std::vector<std::pair<int, Color>> m_textColors;
    std::vector<std::pair<int, Color>> m_drawTextColors;

    CoordsBufferPtr m_coordsBuffer;
    std::vector<std::pair<Color, CoordsBufferPtr>> m_colorCoordsBuffer;

    float m_fontScale{ 1.f };

public:
    void resizeToText();
    void clearText() { setText(""); }

    void setText(std::string_view text, bool dontFireLuaCall = false);
    void setColoredText(std::string_view coloredText, bool dontFireLuaCall = false);
    void setTextAlign(const Fw::AlignmentFlag align) { m_textAlign = align; updateText(); }
    void setTextOffset(const Point& offset) { m_textOffset = offset; updateText(); }
    void setTextWrap(const bool textWrap) { setProp(PropTextWrap, textWrap); updateText(); }
    void setTextAutoResize(const bool textAutoResize) { setProp(PropTextHorizontalAutoResize, textAutoResize); setProp(PropTextVerticalAutoResize, textAutoResize); updateText(); }
    void setTextHorizontalAutoResize(const bool textAutoResize) { setProp(PropTextHorizontalAutoResize, textAutoResize); updateText(); }
    void setTextVerticalAutoResize(const bool textAutoResize) { setProp(PropTextVerticalAutoResize, textAutoResize); updateText(); }
    void setTextOnlyUpperCase(const bool textOnlyUpperCase) { setProp(PropTextOnlyUpperCase, textOnlyUpperCase); setText(m_text); }
    void setFont(std::string_view fontName);
    void setFontScale(const float scale) { m_fontScale = scale; m_textCachedScreenCoords = {}; updateText(); }

    std::string getText() { return m_text; }
    std::string getDrawText() { return m_drawText; }
    Fw::AlignmentFlag getTextAlign() { return m_textAlign; }
    Point getTextOffset() { return m_textOffset; }
    bool isTextWrap() { return hasProp(PropTextWrap); }
    std::string getFont() { return m_font->getName(); }
    Size getTextSize() { return m_textSize; }

    // custom style
protected:
    virtual void parseCustomStyle(const OTMLNodePtr& /*styleNode*/) {};
};