# UIWidget

The `UIWidget` is the base class for all UI elements in OTClient. It provides the core functionality for creating and managing UI elements, including:

* **Layout:** Positioning and sizing of widgets.
* **Properties:** Common properties like visibility, color, and opacity.
* **Events:** Handling user input like mouse clicks and key presses.
* **Styling:** Applying styles using a CSS-like syntax.

This document provides a comprehensive overview of the `UIWidget` class and its functionality.

## C++ API (`src/framework/ui/uiwidget.h`)

The C++ API provides the core implementation of the `UIWidget` class. It is defined in the `src/framework/ui/uiwidget.h` header file.

### Public Methods

#### Widget Core

This section describes the core methods for managing the widget's lifecycle, hierarchy, and layout.

* `addChild(const UIWidgetPtr& child)`: Adds a child widget.
* `insertChild(int32_t index, const UIWidgetPtr& child)`: Inserts a child widget at a specific index.
* `removeChild(const UIWidgetPtr& child)`: Removes a child widget.
* `focusChild(const UIWidgetPtr& child, Fw::FocusReason reason)`: Focuses a child widget.
* `focusNextChild(Fw::FocusReason reason, bool rotate = false)`: Focuses the next child widget.
* `focusPreviousChild(Fw::FocusReason reason, bool rotate = false)`: Focuses the previous child widget.
* `lowerChild(const UIWidgetPtr& child)`: Lowers a child widget to the bottom of the z-order.
* `raiseChild(const UIWidgetPtr& child)`: Raises a child widget to the top of the z-order.
* `moveChildToIndex(const UIWidgetPtr& child, int index)`: Moves a child widget to a specific index.
* `reorderChildren(const std::vector<UIWidgetPtr>& childrens)`: Reorders the children based on a provided list.
* `lockChild(const UIWidgetPtr& child)`: Locks a child widget, preventing it from being moved or resized.
* `unlockChild(const UIWidgetPtr& child)`: Unlocks a child widget.
* `mergeStyle(const OTMLNodePtr& styleNode)`: Merges a style node with the widget's current style.
* `applyStyle(const OTMLNodePtr& styleNode)`: Applies a style node to the widget.
* `addAnchor(Fw::AnchorEdge anchoredEdge, std::string_view hookedWidgetId, Fw::AnchorEdge hookedEdge)`: Adds an anchor to the widget.
* `removeAnchor(Fw::AnchorEdge anchoredEdge)`: Removes an anchor from the widget.
* `fill(std::string_view hookedWidgetId)`: Makes the widget fill the specified widget.
* `centerIn(std::string_view hookedWidgetId)`: Centers the widget in the specified widget.
* `breakAnchors()`: Breaks all anchors of the widget.
* `updateParentLayout()`: Updates the parent's layout.
* `updateLayout()`: Updates the widget's layout.
* `lock()`: Locks the widget.
* `unlock()`: Unlocks the widget.
* `focus()`: Focuses the widget.
* `recursiveFocus(Fw::FocusReason reason)`: Recursively focuses the widget.
* `lower()`: Lowers the widget.
* `raise()`: Raises the widget.
* `grabMouse()`: Grabs the mouse input.
* `ungrabMouse()`: Ungrabs the mouse input.
* `grabKeyboard()`: Grabs the keyboard input.
* `ungrabKeyboard()`: Ungrabs the keyboard input.
* `bindRectToParent()`: Binds the widget's rect to its parent.
* `destroy()`: Destroys the widget.
* `destroyChildren()`: Destroys all children of the widget.
* `removeChildren()`: Removes all children of the widget.
* `hideChildren()`: Hides all children of the widget.
* `showChildren()`: Shows all children of the widget.

#### Setters

This section describes the methods for setting the properties of the widget.
These methods allow you to customize the appearance and behavior of the widget.

* `setId(std::string_view id)`: Sets the widget's ID. This is useful for identifying the widget in scripts and styles.
* `setParent(const UIWidgetPtr& parent)`: Sets the widget's parent. The widget will be positioned relative to its parent.
* `setLayout(const UILayoutPtr& layout)`: Sets the widget's layout.
* `setRect(const Rect& rect)`: Sets the widget's rect.
* `setStyle(std::string_view styleName)`: Sets the widget's style.
* `setStyleFromNode(const OTMLNodePtr& styleNode)`: Sets the widget's style from a style node.
* `setEnabled(bool enabled)`: Sets whether the widget is enabled.
* `setVisible(bool visible)`: Sets whether the widget is visible.
* `setOn(bool on)`: Sets the widget's "on" state.
* `setChecked(bool checked)`: Sets whether the widget is checked.
* `setFocusable(bool focusable)`: Sets whether the widget is focusable.
* `setPhantom(bool phantom)`: Sets whether the widget is a phantom (i.e., doesn't interact with the mouse).
* `setDraggable(bool draggable)`: Sets whether the widget is draggable.
* `setFixedSize(bool fixed)`: Sets whether the widget has a fixed size.
* `setClipping(const bool clipping)`: Sets whether the widget clips its children.
* `setLastFocusReason(Fw::FocusReason reason)`: Sets the last focus reason.
* `setAutoFocusPolicy(Fw::AutoFocusPolicy policy)`: Sets the auto-focus policy.
* `setAutoRepeatDelay(const int delay)`: Sets the auto-repeat delay for key presses.
* `setVirtualOffset(const Point& offset)`: Sets the virtual offset of the widget.
* `setOnHtml(const bool v)`: Sets whether the widget is on an HTML page.

#### Getters

This section describes the methods for getting the properties of the widget.

* `isAnchored()`: Returns `true` if the widget is anchored to another widget.
* `isChildLocked(const UIWidgetPtr& child)`: Returns `true` if the specified child is locked.
* `hasChild(const UIWidgetPtr& child)`: Returns true if the widget has the specified child.
* `getChildIndex(const UIWidgetPtr& child = nullptr)`: Returns the index of the specified child.
* `getPaddingRect()`: Returns the padding rect of the widget.
* `getMarginRect()`: Returns the margin rect of the widget.
* `getChildrenRect()`: Returns the rect that contains all children.
* `getAnchoredLayout()`: Returns the anchored layout of the widget.
* `getAnchorsGroup()`: Returns the anchors group of the widget.
* `getAnchors()`: Returns the anchors of the widget.
* `getAnchorType(Fw::AnchorEdge anchorType)`: Returns the anchor type of the specified anchor.
* `hasAnchoredLayout()`: Returns true if the widget has an anchored layout.
* `getRootParent()`: Returns the root parent of the widget.
* `getNextWidget()`: Returns the next widget in the parent's children list.
* `getPrevWidget()`: Returns the previous widget in the parent's children list.
* `getChildAfter(const UIWidgetPtr& relativeChild)`: Returns the child after the specified child.
* `getChildBefore(const UIWidgetPtr& relativeChild)`: Returns the child before the specified child.
* `getChildById(std::string_view childId)`: Returns a child by its ID.
* `getChildByPos(const Point& childPos)`: Returns a child by its position.
* `getChildByIndex(int index)`: Returns a child by its index.
* `getChildByState(Fw::WidgetState state)`: Returns a child by its state.
* `getChildByStyleName(std::string_view styleName)`: Returns a child by its style name.
* `recursiveGetChildById(std::string_view id)`: Recursively gets a child by its ID.
* `recursiveGetChildByPos(const Point& childPos, bool wantsPhantom)`: Recursively gets a child by its position.
* `recursiveGetChildByState(Fw::WidgetState state, bool wantsPhantom)`: Recursively gets a child by its state.
* `recursiveGetChildren()`: Recursively gets all children.
* `recursiveGetChildrenByPos(const Point& childPos)`: Recursively gets all children at a specific position.
* `recursiveGetChildrenByMarginPos(const Point& childPos)`: Recursively gets all children at a specific position within the margin.
* `recursiveGetChildrenByState(Fw::WidgetState state)`: Recursively gets all children with a specific state.
* `recursiveGetChildrenByStyleName(std::string_view styleName)`: Recursively gets all children with a specific style name.
* `backwardsGetWidgetById(std::string_view id)`: Gets a widget by its ID by searching backwards.
* `getId()`: Returns the widget's ID.
* `getSource()`: Returns the widget's source file.
* `getParent()`: Returns the widget's parent.
* `getFocusedChild()`: Returns the focused child.
* `getHoveredChild()`: Returns the hovered child.
* `getChildren()`: Returns the list of children.
* `getFirstChild()`: Returns the first child.
* `getLastChild()`: Returns the last child.
* `getLayout()`: Returns the widget's layout.
* `getStyle()`: Returns the widget's style.
* `getChildCount()`: Returns the number of children.
* `getLastFocusReason()`: Returns the last focus reason.
* `getAutoFocusPolicy()`: Returns the auto-focus policy.
* `getAutoRepeatDelay()`: Returns the auto-repeat delay.
* `getVirtualOffset()`: Returns the virtual offset.
* `getStyleName()`: Returns the style name.
* `getLastClickPosition()`: Returns the last click position.

#### State

This section describes the methods for querying the state of the widget.

* `isActive()`: Returns `true` if the widget is active.
* `isEnabled()`: Returns `true` if the widget is enabled.
* `isDisabled()`: Returns true if the widget is disabled.
* `isFocused()`: Returns true if the widget is focused.
* `isHovered(const bool orChild = false)`: Returns true if the widget is hovered.
* `isChildHovered()`: Returns true if a child of the widget is hovered.
* `isPressed()`: Returns true if the widget is pressed.
* `isFirst()`: Returns true if the widget is the first child of its parent.
* `isMiddle()`: Returns true if the widget is a middle child of its parent.
* `isLast()`: Returns true if the widget is the last child of its parent.
* `isAlternate()`: Returns true if the widget has the alternate state.
* `isChecked()`: Returns true if the widget is checked.
* `isOn()`: Returns true if the widget has the "on" state.
* `isDragging()`: Returns true if the widget is being dragged.
* `isVisible()`: Returns true if the widget is visible.
* `isHidden()`: Returns true if the widget is hidden.
* `isExplicitlyEnabled()`: Returns true if the widget is explicitly enabled.
* `isExplicitlyVisible()`: Returns true if the widget is explicitly visible.
* `isFocusable()`: Returns true if the widget is focusable.
* `isPhantom()`: Returns true if the widget is a phantom.
* `isDraggable()`: Returns true if the widget is draggable.
* `isFixedSize()`: Returns true if the widget has a fixed size.
* `isClipping()`: Returns true if the widget clips its children.
* `isDestroyed()`: Returns true if the widget has been destroyed.
* `isFirstOnStyle()`: Returns true if the widget is the first to have its style applied.
* `isFirstChild()`: Returns true if the widget is the first child of its parent.
* `isLastChild()`: Returns true if the widget is the last child of its parent.
* `isMiddleChild()`: Returns true if the widget is a middle child of its parent.
* `hasChildren()`: Returns true if the widget has children.
* `containsMarginPoint(const Point& point)`: Returns true if the specified point is within the widget's margin.
* `containsPaddingPoint(const Point& point)`: Returns true if the specified point is within the widget's padding.
* `containsPoint(const Point& point)`: Returns true if the specified point is within the widget's rect.
* `intersects(const Rect rect)`: Returns true if the widget's rect intersects with the specified rect.
* `intersectsMargin(const Rect rect)`: Returns true if the widget's margin intersects with the specified rect.
* `intersectsPadding(const Rect rect)`: Returns true if the widget's padding intersects with the specified rect.

#### Base Style

This section describes the methods for styling the widget. These methods allow you to customize the appearance of the widget, such as its position, size, color, and border.

* `setX(const int x)`: Sets the x-coordinate of the widget.
* `setY(const int y)`: Sets the y-coordinate of the widget.
* `setWidth(const int width)`: Sets the width of the widget.
* `setHeight(const int height)`: Sets the height of the widget.
* `setSize(const Size& size)`: Sets the size of the widget.
* `setMinWidth(const int minWidth)`: Sets the minimum width of the widget.
* `setMaxWidth(const int maxWidth)`: Sets the maximum width of the widget.
* `setMinHeight(const int minHeight)`: Sets the minimum height of the widget.
* `setMaxHeight(const int maxHeight)`: Sets the maximum height of the widget.
* `setMinSize(const Size& minSize)`: Sets the minimum size of the widget.
* `setMaxSize(const Size& maxSize)`: Sets the maximum size of the widget.
* `setPosition(const Point& pos)`: Sets the position of the widget.
* `setColor(const Color& color)`: Sets the color of the widget.
* `setBackgroundColor(const Color& color)`: Sets the background color of the widget.
* `setBackgroundOffsetX(const int x)`: Sets the x-offset of the background.
* `setBackgroundOffsetY(const int y)`: Sets the y-offset of the background.
* `setBackgroundOffset(const Point& pos)`: Sets the offset of the background.
* `setBackgroundWidth(const int width)`: Sets the width of the background.
* `setBackgroundHeight(const int height)`: Sets the height of the background.
* `setBackgroundSize(const Size& size)`: Sets the size of the background.
* `setBackgroundRect(const Rect& rect)`: Sets the rect of the background.
* `setIcon(const std::string& iconFile)`: Sets the icon of the widget.
* `setIconColor(const Color& color)`: Sets the color of the icon.
* `setIconOffsetX(const int x)`: Sets the x-offset of the icon.
* `setIconOffsetY(const int y)`: Sets the y-offset of the icon.
* `setIconOffset(const Point& pos)`: Sets the offset of the icon.
* `setIconWidth(const int width)`: Sets the width of the icon.
* `setIconHeight(const int height)`: Sets the height of the icon.
* `setIconSize(const Size& size)`: Sets the size of the icon.
* `setIconRect(const Rect& rect)`: Sets the rect of the icon.
* `setIconClip(const Rect& rect)`: Sets the clip rect of the icon.
* `setIconAlign(const Fw::AlignmentFlag align)`: Sets the alignment of the icon.
* `setBorderWidth(const int width)`: Sets the border width of the widget.
* `setBorderWidthTop(const int width)`: Sets the top border width of the widget.
* `setBorderWidthRight(const int width)`: Sets the right border width of the widget.
* `setBorderWidthBottom(const int width)`: Sets the bottom border width of the widget.
* `setBorderWidthLeft(const int width)`: Sets the left border width of the widget.
* `setBorderColor(const Color& color)`: Sets the border color of the widget.
* `setBorderColorTop(const Color& color)`: Sets the top border color of the widget.
* `setBorderColorRight(const Color& color)`: Sets the right border color of the widget.
* `setBorderColorBottom(const Color& color)`: Sets the bottom border color of the widget.
* `setBorderColorLeft(const Color& color)`: Sets the left border color of the widget.
* `setMargin(const int margin)`: Sets the margin of the widget.
* `setMarginHorizontal(const int margin)`: Sets the horizontal margin of the widget.
* `setMarginVertical(const int margin)`: Sets the vertical margin of the widget.
* `setMarginTop(const int margin)`: Sets the top margin of the widget.
* `setMarginRight(const int margin)`: Sets the right margin of the widget.
* `setMarginBottom(const int margin)`: Sets the bottom margin of the widget.
* `setMarginLeft(const int margin)`: Sets the left margin of the widget.
* `setPadding(const int padding)`: Sets the padding of the widget.
* `setPaddingHorizontal(const int padding)`: Sets the horizontal padding of the widget.
* `setPaddingVertical(const int padding)`: Sets the vertical padding of the widget.
* `setPaddingTop(const int padding)`: Sets the top padding of the widget.
* `setPaddingRight(const int padding)`: Sets the right padding of the widget.
* `setPaddingBottom(const int padding)`: Sets the bottom padding of the widget.
* `setPaddingLeft(const int padding)`: Sets the left padding of the widget.
* `setOpacity(const float opacity)`: Sets the opacity of the widget.
* `setRotation(const float degrees)`: Sets the rotation of the widget.
* `getX()`: Returns the x-coordinate of the widget.
* `getY()`: Returns the y-coordinate of the widget.
* `getPosition()`: Returns the position of the widget.
* `getCenter()`: Returns the center of the widget.
* `getWidth()`: Returns the width of the widget.
* `getHeight()`: Returns the height of the widget.
* `getSize()`: Returns the size of the widget.
* `getMinWidth()`: Returns the minimum width of the widget.
* `getMaxWidth()`: Returns the maximum width of the widget.
* `getMinHeight()`: Returns the minimum height of the widget.
* `getMaxHeight()`: Returns the maximum height of the widget.
* `getMinSize()`: Returns the minimum size of the widget.
* `getMaxSize()`: Returns the maximum size of the widget.
* `getRect()`: Returns the rect of the widget.
* `getColor()`: Returns the color of the widget.
* `getBackgroundColor()`: Returns the background color of the widget.
* `getBackgroundOffsetX()`: Returns the x-offset of the background.
* `getBackgroundOffsetY()`: Returns the y-offset of the background.
* `getBackgroundOffset()`: Returns the offset of the background.
* `getBackgroundWidth()`: Returns the width of the background.
* `getBackgroundHeight()`: Returns the height of the background.
* `getBackgroundSize()`: Returns the size of the background.
* `getBackgroundRect()`: Returns the rect of the background.
* `getIconColor()`: Returns the color of the icon.
* `getIconOffsetX()`: Returns the x-offset of the icon.
* `getIconOffsetY()`: Returns the y-offset of the icon.
* `getIconOffset()`: Returns the offset of the icon.
* `getIconWidth()`: Returns the width of the icon.
* `getIconHeight()`: Returns the height of the icon.
* `getIconSize()`: Returns the size of the icon.
* `getIconRect()`: Returns the rect of the icon.
* `getIconClip()`: Returns the clip rect of the icon.
* `getIconAlign()`: Returns the alignment of the icon.
* `getBorderTopColor()`: Returns the top border color of the widget.
* `getBorderRightColor()`: Returns the right border color of the widget.
* `getBorderBottomColor()`: Returns the bottom border color of the widget.
* `getBorderLeftColor()`: Returns the left border color of the widget.
* `getBorderTopWidth()`: Returns the top border width of the widget.
* `getBorderRightWidth()`: Returns the right border width of the widget.
* `getBorderBottomWidth()`: Returns the bottom border width of the widget.
* `getBorderLeftWidth()`: Returns the left border width of the widget.
* `getMarginTop()`: Returns the top margin of the widget.
* `getMarginRight()`: Returns the right margin of the widget.
* `getMarginBottom()`: Returns the bottom margin of the widget.
* `getMarginLeft()`: Returns the left margin of the widget.
* `getPaddingTop()`: Returns the top padding of the widget.
* `getPaddingRight()`: Returns the right padding of the widget.
* `getPaddingBottom()`: Returns the bottom padding of the widget.
* `getPaddingLeft()`: Returns the left padding of the widget.
* `getPaddingSize()`: Returns the padding size of the widget.
* `getOpacity()`: Returns the opacity of the widget.
* `getRotation()`: Returns the rotation of the widget.

#### Image

This section describes the methods for controlling the widget's image.

* `setImageSource(std::string_view source, bool base64)`: Sets the image source of the widget. The `source` can be a file path or a base64 encoded string.
* `setImageClip(const Rect& clipRect)`: Sets the clip rect of the image.
* `setImageOffsetX(const int x)`: Sets the x-offset of the image.
* `setImageOffsetY(const int y)`: Sets the y-offset of the image.
* `setImageOffset(const Point& pos)`: Sets the offset of the image.
* `setImageWidth(const int width)`: Sets the width of the image.
* `setImageHeight(const int height)`: Sets the height of the image.
* `setImageSize(const Size& size)`: Sets the size of the image.
* `setImageRect(const Rect& rect)`: Sets the rect of the image.
* `setImageColor(const Color& color)`: Sets the color of the image.
* `setImageFixedRatio(const bool fixedRatio)`: Sets whether the image has a fixed ratio.
* `setImageRepeated(const bool repeated)`: Sets whether the image is repeated.
* `setImageSmooth(const bool smooth)`: Sets whether the image is smoothed.
* `setImageAutoResize(const bool autoResize)`: Sets whether the image is auto-resized.
* `setImageIndividualAnimation(const bool v)`: Sets whether the image has an individual animation.
* `setImageBorderTop(const int border)`: Sets the top border of the image.
* `setImageBorderRight(const int border)`: Sets the right border of the image.
* `setImageBorderBottom(const int border)`: Sets the bottom border of the image.
* `setImageBorderLeft(const int border)`: Sets the left border of the image.
* `setImageBorder(const int border)`: Sets the border of the image.
* `getImageSource()`: Returns the image source.
* `getImageClip()`: Returns the image clip rect.
* `getImageOffsetX()`: Returns the x-offset of the image.
* `getImageOffsetY()`: Returns the y-offset of the image.
* `getImageOffset()`: Returns the offset of the image.
* `getImageWidth()`: Returns the width of the image.
* `getImageHeight()`: Returns the height of the image.
* `getImageSize()`: Returns the size of the image.
* `getImageRect()`: Returns the rect of the image.
* `getImageColor()`: Returns the color of the image.
* `isImageFixedRatio()`: Returns true if the image has a fixed ratio.
* `isImageSmooth()`: Returns true if the image is smoothed.
* `isImageAutoResize()`: Returns true if the image is auto-resized.
* `isImageIndividualAnimation()`: Returns true if the image has an individual animation.
* `getImageBorderTop()`: Returns the top border of the image.
* `getImageBorderRight()`: Returns the right border of the image.
* `getImageBorderBottom()`: Returns the bottom border of the image.
* `getImageBorderLeft()`: Returns the left border of the image.
* `getImageTextureWidth()`: Returns the width of the image texture.
* `getImageTextureHeight()`: Returns the height of the image texture.

#### Text

This section describes the methods for controlling the widget's text.

* `resizeToText()`: Resizes the widget to fit its text.
* `clearText()`: Clears the widget's text.
* `setText(std::string_view text, bool dontFireLuaCall = false)`: Sets the widget's text.
* `setColoredText(std::string_view coloredText, bool dontFireLuaCall = false)`: Sets the widget's colored text.
* `setTextAlign(const Fw::AlignmentFlag align)`: Sets the text alignment.
* `setTextOffset(const Point& offset)`: Sets the text offset.
* `setTextWrap(const bool textWrap)`: Sets whether the text should wrap.
* `setTextAutoResize(const bool textAutoResize)`: Sets whether the widget should auto-resize to fit its text.
* `setTextHorizontalAutoResize(const bool textAutoResize)`: Sets whether the widget should auto-resize horizontally to fit its text.
* `setTextVerticalAutoResize(const bool textAutoResize)`: Sets whether the widget should auto-resize vertically to fit its text.
* `setTextOnlyUpperCase(const bool textOnlyUpperCase)`: Sets whether the text should be only uppercase.
* `setFont(std::string_view fontName)`: Sets the font of the text.
* `setFontScale(const float scale)`: Sets the scale of the font.
* `getText()`: Returns the widget's text.
* `getDrawText()`: Returns the text that is drawn.
* `getTextAlign()`: Returns the text alignment.
* `getTextOffset()`: Returns the text offset.
* `isTextWrap()`: Returns true if the text is wrapped.
* `getFont()`: Returns the font of the text.
* `getTextSize()`: Returns the size of the text.

### Enums and Structs

#### `EdgeGroup<T>`

A template struct that represents a group of four edges (top, right, bottom, left). This is used for properties like margin, padding, and border width.

#### `FlagProp`

An enum that defines a set of flags for widget properties. These flags are used to control the behavior and appearance of the widget.

## Lua API (`modules/corelib/ui/uiwidget.lua`)

The Lua API extends the C++ API with additional functionality.

### `setMargin(...)`

Sets the margin of the widget. This function can take one, two, or four arguments:

* **One argument:** Sets all margins to the same value.
* **Two arguments:** Sets the vertical and horizontal margins.
* **Four arguments:** Sets the top, right, bottom, and left margins individually.

**Example:**

```lua
-- Set all margins to 10
widget:setMargin(10)

-- Set vertical margin to 10 and horizontal margin to 20
widget:setMargin(10, 20)

-- Set top, right, bottom, and left margins
widget:setMargin(10, 20, 30, 40)
```

### `parseColoredText(text, default_color)`

Parses a string with colored text and applies it to the widget. The text should be formatted with color tags, e.g., `[color=#ff0000]Red text[/color]`.

**Example:**

```lua
widget:parseColoredText("This is [color=#ff0000]red[/color] and this is [color=#00ff00]green[/color].")
```
