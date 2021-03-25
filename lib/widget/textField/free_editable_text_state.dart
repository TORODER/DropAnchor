import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'dart:ui' as ui hide TextStyle;
import 'dart:math' as math;

const int _kObscureShowLatestCharCursorTicks = 3;
const Duration _kCursorBlinkHalfPeriod = Duration(milliseconds: 500);
const Duration _kCursorBlinkWaitForStart = Duration(milliseconds: 150);

class FreeEditableTextState extends EditableTextState {
  Timer? _cursorTimer;
  bool _targetCursorVisibility = false;
  final ValueNotifier<bool> _cursorVisibilityNotifier =
      ValueNotifier<bool>(true);
  final GlobalKey _editableKey = GlobalKey();
  final ClipboardStatusNotifier? _clipboardStatus =
      kIsWeb ? null : ClipboardStatusNotifier();

  TextInputConnection? _textInputConnection;
  TextSelectionOverlay? _selectionOverlay;

  ScrollController? _scrollController;

  late AnimationController _cursorBlinkOpacityController;

  final LayerLink _toolbarLayerLink = LayerLink();
  final LayerLink _startHandleLayerLink = LayerLink();
  final LayerLink _endHandleLayerLink = LayerLink();

  bool _didAutoFocus = false;
  FocusAttachment? _focusAttachment;

  AutofillGroupState? _currentAutofillScope;

  @override
  AutofillScope? get currentAutofillScope => _currentAutofillScope;

  bool _isInAutofillContext = false;

  bool get _shouldCreateInputConnection => kIsWeb || !widget.readOnly;

  static const Duration _fadeDuration = Duration(milliseconds: 250);

  static const Duration _floatingCursorResetTime = Duration(milliseconds: 125);

  late AnimationController _floatingCursorResetController;

  @override
  bool get wantKeepAlive => widget.focusNode.hasFocus;

  Color get _cursorColor =>
      widget.cursorColor.withOpacity(_cursorBlinkOpacityController.value);

  @override
  bool get cutEnabled => widget.toolbarOptions.cut && !widget.readOnly;

  @override
  bool get copyEnabled => widget.toolbarOptions.copy;

  @override
  bool get pasteEnabled => widget.toolbarOptions.paste && !widget.readOnly;

  @override
  bool get selectAllEnabled => widget.toolbarOptions.selectAll;

  void _onChangedClipboardStatus() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _clipboardStatus?.addListener(_onChangedClipboardStatus);
    widget.controller.addListener(_didChangeTextEditingValue);
    _focusAttachment = widget.focusNode.attach(context);
    widget.focusNode.addListener(_handleFocusChanged);
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController!.addListener(() {
      _selectionOverlay?.updateForScroll();
    });
    _cursorBlinkOpacityController =
        AnimationController(vsync: this, duration: _fadeDuration);
    _cursorBlinkOpacityController.addListener(_onCursorColorTick);
    _floatingCursorResetController = AnimationController(vsync: this);
    _floatingCursorResetController.addListener(_onFloatingCursorResetTick);
    _cursorVisibilityNotifier.value = widget.showCursor;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final AutofillGroupState? newAutofillGroup = AutofillGroup.of(context);
    if (currentAutofillScope != newAutofillGroup) {
      _currentAutofillScope?.unregister(autofillId);
      _currentAutofillScope = newAutofillGroup;
      newAutofillGroup?.register(this);
      _isInAutofillContext = _isInAutofillContext || _shouldBeInAutofillContext;
    }

    if (!_didAutoFocus && widget.autofocus) {
      _didAutoFocus = true;
      SchedulerBinding.instance!.addPostFrameCallback((_) {
        if (mounted) {
          FocusScope.of(context).autofocus(widget.focusNode);
        }
      });
    }
  }

  @override
  void didUpdateWidget(EditableText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_didChangeTextEditingValue);
      widget.controller.addListener(_didChangeTextEditingValue);
      _updateRemoteEditingValueIfNeeded();
    }
    if (widget.controller.selection != oldWidget.controller.selection) {
      _selectionOverlay?.update(_value);
    }
    _selectionOverlay?.handlesVisible = widget.showSelectionHandles;
    _isInAutofillContext = _isInAutofillContext || _shouldBeInAutofillContext;

    if (widget.focusNode != oldWidget.focusNode) {
      oldWidget.focusNode.removeListener(_handleFocusChanged);
      _focusAttachment?.detach();
      _focusAttachment = widget.focusNode.attach(context);
      widget.focusNode.addListener(_handleFocusChanged);
      updateKeepAlive();
    }
    if (!_shouldCreateInputConnection) {
      _closeInputConnectionIfNeeded();
    } else {
      if (oldWidget.readOnly && _hasFocus) {
        _openInputConnection();
      }
    }

    if (kIsWeb && _hasInputConnection) {
      if (oldWidget.readOnly != widget.readOnly) {
        _textInputConnection!.updateConfig(textInputConfiguration);
      }
    }

    if (widget.style != oldWidget.style) {
      final TextStyle style = widget.style;

      if (_hasInputConnection) {
        _textInputConnection!.setStyle(
          fontFamily: style.fontFamily,
          fontSize: style.fontSize,
          fontWeight: style.fontWeight,
          textDirection: _textDirection,
          textAlign: widget.textAlign,
        );
      }
    }
    if (widget.selectionEnabled &&
        pasteEnabled &&
        widget.selectionControls?.canPaste(this) == true) {
      _clipboardStatus?.update();
    }
  }

  @override
  void dispose() {
    _currentAutofillScope?.unregister(autofillId);
    widget.controller.removeListener(_didChangeTextEditingValue);
    _cursorBlinkOpacityController.removeListener(_onCursorColorTick);
    _floatingCursorResetController.removeListener(_onFloatingCursorResetTick);
    _closeInputConnectionIfNeeded();
    assert(!_hasInputConnection);
    _stopCursorTimer();
    assert(_cursorTimer == null);
    _selectionOverlay?.dispose();
    _selectionOverlay = null;
    _focusAttachment!.detach();
    widget.focusNode.removeListener(_handleFocusChanged);
    WidgetsBinding.instance!.removeObserver(this);
    _clipboardStatus?.removeListener(_onChangedClipboardStatus);
    _clipboardStatus?.dispose();
    super.dispose();
    assert(_batchEditDepth <= 0, 'unfinished batch edits: $_batchEditDepth');
  }

  TextEditingValue? _lastKnownRemoteTextEditingValue;

  @override
  TextEditingValue get currentTextEditingValue => _value;

  @override
  void updateEditingValue(TextEditingValue value) {
    if (!_shouldCreateInputConnection) {
      return;
    }

    if (widget.readOnly) {
      value = _value.copyWith(selection: value.selection);
    }
    _lastKnownRemoteTextEditingValue = value;

    if (value == _value) {
      return;
    }

    if (value.text == _value.text && value.composing == _value.composing) {
      _handleSelectionChanged(value.selection, SelectionChangedCause.keyboard);
    } else {
      hideToolbar();
      _currentPromptRectRange = null;

      if (_hasInputConnection) {
        if (widget.obscureText && value.text.length == _value.text.length + 1) {
          _obscureShowCharTicksPending = _kObscureShowLatestCharCursorTicks;
          _obscureLatestCharIndex = _value.selection.baseOffset;
        }
      }

      _formatAndSetValue(value, SelectionChangedCause.keyboard);
    }

    _scheduleShowCaretOnScreen();
    if (_hasInputConnection) {
      _stopCursorTimer(resetCharTicks: false);
      _startCursorTimer();
    }
  }

  @override
  void performAction(TextInputAction action) {
    switch (action) {
      case TextInputAction.newline:
        if (!_isMultiline) _finalizeEditing(action, shouldUnfocus: true);
        break;
      case TextInputAction.done:
      case TextInputAction.go:
      case TextInputAction.next:
      case TextInputAction.previous:
      case TextInputAction.search:
      case TextInputAction.send:
        _finalizeEditing(action, shouldUnfocus: true);
        break;
      case TextInputAction.continueAction:
      case TextInputAction.emergencyCall:
      case TextInputAction.join:
      case TextInputAction.none:
      case TextInputAction.route:
      case TextInputAction.unspecified:
        _finalizeEditing(action, shouldUnfocus: false);
        break;
    }
  }

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {
    widget.onAppPrivateCommand!(action, data);
  }

  Rect? _startCaretRect;

  TextPosition? _lastTextPosition;

  Offset? _pointOffsetOrigin;

  Offset? _lastBoundedOffset;

  Offset get _floatingCursorOffset =>
      Offset(0, renderEditable.preferredLineHeight / 2);

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {
    switch (point.state) {
      case FloatingCursorDragState.Start:
        if (_floatingCursorResetController.isAnimating) {
          _floatingCursorResetController.stop();
          _onFloatingCursorResetTick();
        }

        _pointOffsetOrigin = point.offset;

        final TextPosition currentTextPosition =
            TextPosition(offset: renderEditable.selection!.baseOffset);
        _startCaretRect =
            renderEditable.getLocalRectForCaret(currentTextPosition);

        _lastBoundedOffset = _startCaretRect!.center - _floatingCursorOffset;
        _lastTextPosition = currentTextPosition;
        renderEditable.setFloatingCursor(
            point.state, _lastBoundedOffset!, _lastTextPosition!);
        break;
      case FloatingCursorDragState.Update:
        final Offset centeredPoint = point.offset! - _pointOffsetOrigin!;
        final Offset rawCursorOffset =
            _startCaretRect!.center + centeredPoint - _floatingCursorOffset;

        _lastBoundedOffset = renderEditable
            .calculateBoundedFloatingCursorOffset(rawCursorOffset);
        _lastTextPosition = renderEditable.getPositionForPoint(renderEditable
            .localToGlobal(_lastBoundedOffset! + _floatingCursorOffset));
        renderEditable.setFloatingCursor(
            point.state, _lastBoundedOffset!, _lastTextPosition!);
        break;
      case FloatingCursorDragState.End:
        if (_lastTextPosition != null && _lastBoundedOffset != null) {
          _floatingCursorResetController.value = 0.0;
          _floatingCursorResetController.animateTo(1.0,
              duration: _floatingCursorResetTime, curve: Curves.decelerate);
        }
        break;
    }
  }

  void _onFloatingCursorResetTick() {
    final Offset finalPosition =
        renderEditable.getLocalRectForCaret(_lastTextPosition!).centerLeft -
            _floatingCursorOffset;
    if (_floatingCursorResetController.isCompleted) {
      renderEditable.setFloatingCursor(
          FloatingCursorDragState.End, finalPosition, _lastTextPosition!);
      if (_lastTextPosition!.offset != renderEditable.selection!.baseOffset)
        _handleSelectionChanged(
            TextSelection.collapsed(offset: _lastTextPosition!.offset),
            SelectionChangedCause.forcePress);
      _startCaretRect = null;
      _lastTextPosition = null;
      _pointOffsetOrigin = null;
      _lastBoundedOffset = null;
    } else {
      final double lerpValue = _floatingCursorResetController.value;
      final double lerpX =
          ui.lerpDouble(_lastBoundedOffset!.dx, finalPosition.dx, lerpValue)!;
      final double lerpY =
          ui.lerpDouble(_lastBoundedOffset!.dy, finalPosition.dy, lerpValue)!;

      renderEditable.setFloatingCursor(FloatingCursorDragState.Update,
          Offset(lerpX, lerpY), _lastTextPosition!,
          resetLerpValue: lerpValue);
    }
  }

  void _finalizeEditing(TextInputAction action, {required bool shouldUnfocus}) {
    if (widget.onEditingComplete != null) {
      try {
        widget.onEditingComplete!();
      } catch (exception, stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'widgets',
          context:
              ErrorDescription('while calling onEditingComplete for $action'),
        ));
      }
    } else {
      widget.controller.clearComposing();
      if (shouldUnfocus) {
        switch (action) {
          case TextInputAction.none:
          case TextInputAction.unspecified:
          case TextInputAction.done:
          case TextInputAction.go:
          case TextInputAction.search:
          case TextInputAction.send:
          case TextInputAction.continueAction:
          case TextInputAction.join:
          case TextInputAction.route:
          case TextInputAction.emergencyCall:
          case TextInputAction.newline:
            widget.focusNode.unfocus();
            break;
          case TextInputAction.next:
            widget.focusNode.nextFocus();
            break;
          case TextInputAction.previous:
            widget.focusNode.previousFocus();
            break;
        }
      }
    }

    try {
      widget.onSubmitted?.call(_value.text);
    } catch (exception, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: exception,
        stack: stack,
        library: 'widgets',
        context: ErrorDescription('while calling onSubmitted for $action'),
      ));
    }
  }

  int _batchEditDepth = 0;

  void beginBatchEdit() {
    _batchEditDepth += 1;
  }

  void endBatchEdit() {
    _batchEditDepth -= 1;
    assert(
      _batchEditDepth >= 0,
      'Unbalanced call to endBatchEdit: beginBatchEdit must be called first.',
    );
    _updateRemoteEditingValueIfNeeded();
  }

  void _updateRemoteEditingValueIfNeeded() {
    if (_batchEditDepth > 0 || !_hasInputConnection) return;
    final TextEditingValue localValue = _value;
    if (localValue == _lastKnownRemoteTextEditingValue) return;
    _textInputConnection!.setEditingState(localValue);
    _lastKnownRemoteTextEditingValue = localValue;
  }

  TextEditingValue get _value => widget.controller.value;

  set _value(TextEditingValue value) {
    widget.controller.value = value;
  }

  bool get _hasFocus => widget.focusNode.hasFocus;

  bool get _isMultiline => widget.maxLines != 1;

  RevealedOffset _getOffsetToRevealCaret(Rect rect) {
    if (!_scrollController!.position.allowImplicitScrolling)
      return RevealedOffset(offset: _scrollController!.offset, rect: rect);

    final Size editableSize = renderEditable.size;
    final double additionalOffset;
    final Offset unitOffset;

    if (!_isMultiline) {
      additionalOffset = rect.width >= editableSize.width
          ? editableSize.width / 2 - rect.center.dx
          : 0.0.clamp(rect.right - editableSize.width, rect.left);
      unitOffset = const Offset(1, 0);
    } else {
      final Rect expandedRect = Rect.fromCenter(
        center: rect.center,
        width: rect.width,
        height: math.max(rect.height, renderEditable.preferredLineHeight),
      );

      additionalOffset = expandedRect.height >= editableSize.height
          ? editableSize.height / 2 - expandedRect.center.dy
          : 0.0.clamp(
              expandedRect.bottom - editableSize.height, expandedRect.top);
      unitOffset = const Offset(0, 1);
    }

    final double targetOffset =
        (additionalOffset + _scrollController!.offset).clamp(
      _scrollController!.position.minScrollExtent,
      _scrollController!.position.maxScrollExtent,
    );

    final double offsetDelta = _scrollController!.offset - targetOffset;
    return RevealedOffset(
        rect: rect.shift(unitOffset * offsetDelta), offset: targetOffset);
  }

  bool get _hasInputConnection => _textInputConnection?.attached ?? false;

  bool get _needsAutofill => widget.autofillHints?.isNotEmpty ?? false;

  bool get _shouldBeInAutofillContext =>
      _needsAutofill && currentAutofillScope != null;

  void _openInputConnection() {
    if (!_shouldCreateInputConnection) {
      return;
    }
    if (!_hasInputConnection) {
      final TextEditingValue localValue = _value;

      _textInputConnection = _needsAutofill && currentAutofillScope != null
          ? currentAutofillScope!.attach(this, textInputConfiguration)
          : TextInput.attach(
              this,
              _createTextInputConfiguration(
                  _isInAutofillContext || _needsAutofill));
      _textInputConnection!.show();
      _updateSizeAndTransform();
      _updateComposingRectIfNeeded();
      if (_needsAutofill) {
        _textInputConnection!.requestAutofill();
      }

      final TextStyle style = widget.style;
      _textInputConnection!
        ..setStyle(
          fontFamily: style.fontFamily,
          fontSize: style.fontSize,
          fontWeight: style.fontWeight,
          textDirection: _textDirection,
          textAlign: widget.textAlign,
        )
        ..setEditingState(localValue);
    } else {
      _textInputConnection!.show();
    }
  }

  void _closeInputConnectionIfNeeded() {
    if (_hasInputConnection) {
      _textInputConnection!.close();
      _textInputConnection = null;
      _lastKnownRemoteTextEditingValue = null;
    }
  }

  void _openOrCloseInputConnectionIfNeeded() {
    if (_hasFocus && widget.focusNode.consumeKeyboardToken()) {
      _openInputConnection();
    } else if (!_hasFocus) {
      _closeInputConnectionIfNeeded();
      widget.controller.clearComposing();
    }
  }

  @override
  void connectionClosed() {
    if (_hasInputConnection) {
      _textInputConnection!.connectionClosedReceived();
      _textInputConnection = null;
      _lastKnownRemoteTextEditingValue = null;
      _finalizeEditing(TextInputAction.done, shouldUnfocus: true);
    }
  }

  void requestKeyboard() {
    if (_hasFocus) {
      _openInputConnection();
    } else {
      widget.focusNode.requestFocus();
    }
  }

  void _updateOrDisposeSelectionOverlayIfNeeded() {
    if (_selectionOverlay != null) {
      if (_hasFocus) {
        _selectionOverlay!.update(_value);
      } else {
        _selectionOverlay!.dispose();
        _selectionOverlay = null;
      }
    }
  }

  void _handleSelectionChanged(
      TextSelection selection, SelectionChangedCause? cause) {
    if (!widget.controller.isSelectionWithinTextBounds(selection)) return;

    widget.controller.selection = selection;

    requestKeyboard();
    if (widget.selectionControls == null) {
      _selectionOverlay?.hide();
      _selectionOverlay = null;
    } else {
      if (_selectionOverlay == null) {
        _selectionOverlay = TextSelectionOverlay(
          clipboardStatus: _clipboardStatus,
          context: context,
          value: _value,
          debugRequiredFor: widget,
          toolbarLayerLink: _toolbarLayerLink,
          startHandleLayerLink: _startHandleLayerLink,
          endHandleLayerLink: _endHandleLayerLink,
          renderObject: renderEditable,
          selectionControls: widget.selectionControls,
          selectionDelegate: this,
          dragStartBehavior: widget.dragStartBehavior,
          onSelectionHandleTapped: widget.onSelectionHandleTapped,
        );
      } else {
        _selectionOverlay!.update(_value);
      }
      _selectionOverlay!.handlesVisible = widget.showSelectionHandles;
      _selectionOverlay!.showHandles();
    }

    try {
      widget.onSelectionChanged?.call(selection, cause);
    } catch (exception, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: exception,
        stack: stack,
        library: 'widgets',
        context:
            ErrorDescription('while calling onSelectionChanged for $cause'),
      ));
    }

    if (_cursorTimer != null) {
      _stopCursorTimer(resetCharTicks: false);
      _startCursorTimer();
    }
  }

  Rect? _currentCaretRect;

  void _handleCaretChanged(Rect caretRect) {
    _currentCaretRect = caretRect;
  }

  static const Duration _caretAnimationDuration = Duration(milliseconds: 100);
  static const Curve _caretAnimationCurve = Curves.fastOutSlowIn;

  bool _showCaretOnScreenScheduled = false;

  void _scheduleShowCaretOnScreen() {
    if (_showCaretOnScreenScheduled) {
      return;
    }
    _showCaretOnScreenScheduled = true;
    SchedulerBinding.instance!.addPostFrameCallback((_) {
      _showCaretOnScreenScheduled = false;
      if (_currentCaretRect == null || !_scrollController!.hasClients) {
        return;
      }

      final double lineHeight = renderEditable.preferredLineHeight;

      double bottomSpacing = widget.scrollPadding.bottom;
      if (_selectionOverlay?.selectionControls != null) {
        final double handleHeight = _selectionOverlay!.selectionControls!
            .getHandleSize(lineHeight)
            .height;
        final double interactiveHandleHeight = math.max(
          handleHeight,
          kMinInteractiveDimension,
        );
        final Offset anchor =
            _selectionOverlay!.selectionControls!.getHandleAnchor(
          TextSelectionHandleType.collapsed,
          lineHeight,
        );
        final double handleCenter = handleHeight / 2 - anchor.dy;
        bottomSpacing = math.max(
          handleCenter + interactiveHandleHeight / 2,
          bottomSpacing,
        );
      }

      final EdgeInsets caretPadding =
          widget.scrollPadding.copyWith(bottom: bottomSpacing);

      final RevealedOffset targetOffset =
          _getOffsetToRevealCaret(_currentCaretRect!);

      _scrollController!.animateTo(
        targetOffset.offset,
        duration: _caretAnimationDuration,
        curve: _caretAnimationCurve,
      );

      renderEditable.showOnScreen(
        rect: caretPadding.inflateRect(targetOffset.rect),
        duration: _caretAnimationDuration,
        curve: _caretAnimationCurve,
      );
    });
  }

  late double _lastBottomViewInset;

  @override
  void didChangeMetrics() {
    if (_lastBottomViewInset <
        WidgetsBinding.instance!.window.viewInsets.bottom) {
      _scheduleShowCaretOnScreen();
    }
    _lastBottomViewInset = WidgetsBinding.instance!.window.viewInsets.bottom;
  }

  late final _WhitespaceDirectionalityFormatter _whitespaceFormatter =
      _WhitespaceDirectionalityFormatter(textDirection: _textDirection);

  void _formatAndSetValue(TextEditingValue value, SelectionChangedCause? cause,
      {bool userInteraction = false}) {
    final bool textChanged = _value.text != value.text ||
        (!_value.composing.isCollapsed && value.composing.isCollapsed);
    final bool selectionChanged = _value.selection != value.selection;

    if (textChanged) {
      value = widget.inputFormatters?.fold<TextEditingValue>(
            value,
            (newValue, formatter) =>
                formatter.formatEditUpdate(_value, newValue),
          ) ??
          value;

      if (widget.inputFormatters?.isNotEmpty ?? false)
        value = _whitespaceFormatter.formatEditUpdate(_value, value);
    }

    beginBatchEdit();
    _value = value;

    if (selectionChanged ||
        (userInteraction &&
            (cause == SelectionChangedCause.longPress ||
                cause == SelectionChangedCause.keyboard))) {
      _handleSelectionChanged(value.selection, cause);
    }
    if (textChanged) {
      try {
        widget.onChanged?.call(value.text);
      } catch (exception, stack) {
        FlutterError.reportError(FlutterErrorDetails(
          exception: exception,
          stack: stack,
          library: 'widgets',
          context: ErrorDescription('while calling onChanged'),
        ));
      }
    }

    endBatchEdit();
  }

  void _onCursorColorTick() {
    renderEditable.cursorColor =
        widget.cursorColor.withOpacity(_cursorBlinkOpacityController.value);
    _cursorVisibilityNotifier.value =
        widget.showCursor && _cursorBlinkOpacityController.value > 0;
  }

  @visibleForTesting
  bool get cursorCurrentlyVisible => _cursorBlinkOpacityController.value > 0;

  @visibleForTesting
  Duration get cursorBlinkInterval => _kCursorBlinkHalfPeriod;

  @visibleForTesting
  TextSelectionOverlay? get selectionOverlay => _selectionOverlay;

  int _obscureShowCharTicksPending = 0;
  int? _obscureLatestCharIndex;

  void _cursorTick(Timer timer) {
    _targetCursorVisibility = !_targetCursorVisibility;
    final double targetOpacity = _targetCursorVisibility ? 1.0 : 0.0;
    if (widget.cursorOpacityAnimates) {
      _cursorBlinkOpacityController.animateTo(targetOpacity,
          curve: Curves.easeOut);
    } else {
      _cursorBlinkOpacityController.value = targetOpacity;
    }

    if (_obscureShowCharTicksPending > 0) {
      setState(() {
        _obscureShowCharTicksPending--;
      });
    }
  }

  void _cursorWaitForStart(Timer timer) {
    assert(_kCursorBlinkHalfPeriod > _fadeDuration);
    _cursorTimer?.cancel();
    _cursorTimer = Timer.periodic(_kCursorBlinkHalfPeriod, _cursorTick);
  }

  void _startCursorTimer() {
    _targetCursorVisibility = true;
    _cursorBlinkOpacityController.value = 1.0;
    if (EditableText.debugDeterministicCursor) return;
    if (widget.cursorOpacityAnimates) {
      _cursorTimer =
          Timer.periodic(_kCursorBlinkWaitForStart, _cursorWaitForStart);
    } else {
      _cursorTimer = Timer.periodic(_kCursorBlinkHalfPeriod, _cursorTick);
    }
  }

  void _stopCursorTimer({bool resetCharTicks = true}) {
    _cursorTimer?.cancel();
    _cursorTimer = null;
    _targetCursorVisibility = false;
    _cursorBlinkOpacityController.value = 0.0;
    if (EditableText.debugDeterministicCursor) return;
    if (resetCharTicks) _obscureShowCharTicksPending = 0;
    if (widget.cursorOpacityAnimates) {
      _cursorBlinkOpacityController.stop();
      _cursorBlinkOpacityController.value = 0.0;
    }
  }

  void _startOrStopCursorTimerIfNeeded() {
    if (_cursorTimer == null && _hasFocus && _value.selection.isCollapsed)
      _startCursorTimer();
    else if (_cursorTimer != null &&
        (!_hasFocus || !_value.selection.isCollapsed)) _stopCursorTimer();
  }

  void _didChangeTextEditingValue() {
    _updateRemoteEditingValueIfNeeded();
    _startOrStopCursorTimerIfNeeded();
    _updateOrDisposeSelectionOverlayIfNeeded();

    setState(() {
      /* We use widget.controller.value in build(). */
    });
  }

  void _handleFocusChanged() {
    _openOrCloseInputConnectionIfNeeded();
    _startOrStopCursorTimerIfNeeded();
    _updateOrDisposeSelectionOverlayIfNeeded();
    if (_hasFocus) {
      WidgetsBinding.instance!.addObserver(this);
      _lastBottomViewInset = WidgetsBinding.instance!.window.viewInsets.bottom;
      if (!widget.readOnly) {
        _scheduleShowCaretOnScreen();
      }
      if (!_value.selection.isValid) {
        _handleSelectionChanged(
            TextSelection.collapsed(offset: _value.text.length), null);
      }
    } else {
      WidgetsBinding.instance!.removeObserver(this);

      _value = TextEditingValue(text: _value.text);
      _currentPromptRectRange = null;
    }
    updateKeepAlive();
  }

  void _updateSizeAndTransform() {
    if (_hasInputConnection) {
      final Size size = renderEditable.size;
      final Matrix4 transform = renderEditable.getTransformTo(null);
      _textInputConnection!.setEditableSizeAndTransform(size, transform);
      SchedulerBinding.instance!
          .addPostFrameCallback((Duration _) => _updateSizeAndTransform());
    }
  }

  void _updateComposingRectIfNeeded() {
    final TextRange composingRange = _value.composing;
    if (_hasInputConnection) {
      assert(mounted);
      Rect? composingRect =
          renderEditable.getRectForComposingRange(composingRange);

      if (composingRect == null) {
        assert(!composingRange.isValid || composingRange.isCollapsed);
        final int offset = composingRange.isValid ? composingRange.start : 0;
        composingRect =
            renderEditable.getLocalRectForCaret(TextPosition(offset: offset));
      }
      assert(composingRect != null);
      _textInputConnection!.setComposingRect(composingRect);
      SchedulerBinding.instance!
          .addPostFrameCallback((Duration _) => _updateComposingRectIfNeeded());
    }
  }

  TextDirection get _textDirection {
    final TextDirection result =
        widget.textDirection ?? Directionality.of(context);
    assert(result != null,
        '$runtimeType created without a textDirection and with no ambient Directionality.');
    return result;
  }

  RenderEditable get renderEditable =>
      _editableKey.currentContext!.findRenderObject()! as RenderEditable;

  @override
  TextEditingValue get textEditingValue => _value;

  double get _devicePixelRatio => MediaQuery.of(context).devicePixelRatio;

  @override
  void userUpdateTextEditingValue(
      TextEditingValue value, SelectionChangedCause? cause) {
    final bool shouldShowCaret =
        widget.readOnly ? _value.selection != value.selection : _value != value;
    if (shouldShowCaret) {
      _scheduleShowCaretOnScreen();
    }
    _formatAndSetValue(value, cause, userInteraction: true);
  }

  @override
  void bringIntoView(TextPosition position) {
    final Rect localRect = renderEditable.getLocalRectForCaret(position);
    final RevealedOffset targetOffset = _getOffsetToRevealCaret(localRect);

    _scrollController!.jumpTo(targetOffset.offset);
    renderEditable.showOnScreen(rect: targetOffset.rect);
  }

  bool showToolbar() {
    if (kIsWeb) {
      return false;
    }

    if (_selectionOverlay == null || _selectionOverlay!.toolbarIsVisible) {
      return false;
    }

    _selectionOverlay!.showToolbar();
    return true;
  }

  @override
  void hideToolbar([bool hideHandles = true]) {
    if (hideHandles) {
      _selectionOverlay?.hide();
    } else {
      _selectionOverlay?.hideToolbar();
    }
  }

  void toggleToolbar() {
    assert(_selectionOverlay != null);
    if (_selectionOverlay!.toolbarIsVisible) {
      hideToolbar();
    } else {
      showToolbar();
    }
  }

  @override
  String get autofillId => 'EditableText-$hashCode';

  TextInputConfiguration _createTextInputConfiguration(
      bool needsAutofillConfiguration) {
    assert(needsAutofillConfiguration != null);

    return TextInputConfiguration(
      inputType: widget.keyboardType,
      readOnly: widget.readOnly,
      obscureText: widget.obscureText,
      autocorrect: widget.autocorrect,
      smartDashesType: widget.smartDashesType,
      smartQuotesType: widget.smartQuotesType,
      enableSuggestions: widget.enableSuggestions,
      inputAction: widget.textInputAction ??
          (widget.keyboardType == TextInputType.multiline
              ? TextInputAction.newline
              : TextInputAction.done),
      textCapitalization: widget.textCapitalization,
      keyboardAppearance: widget.keyboardAppearance,
      autofillConfiguration: !needsAutofillConfiguration
          ? null
          : AutofillConfiguration(
              uniqueIdentifier: autofillId,
              autofillHints:
                  widget.autofillHints?.toList(growable: false) ?? <String>[],
              currentEditingValue: currentTextEditingValue,
            ),
    );
  }

  @override
  TextInputConfiguration get textInputConfiguration {
    return _createTextInputConfiguration(_needsAutofill);
  }

  TextRange? _currentPromptRectRange;

  @override
  void showAutocorrectionPromptRect(int start, int end) {
    setState(() {
      _currentPromptRectRange = TextRange(start: start, end: end);
    });
  }

  VoidCallback? _semanticsOnCopy(TextSelectionControls? controls) {
    return widget.selectionEnabled &&
            copyEnabled &&
            _hasFocus &&
            controls?.canCopy(this) == true
        ? () => controls!.handleCopy(this, _clipboardStatus)
        : null;
  }

  VoidCallback? _semanticsOnCut(TextSelectionControls? controls) {
    return widget.selectionEnabled &&
            cutEnabled &&
            _hasFocus &&
            controls?.canCut(this) == true
        ? () => controls!.handleCut(this)
        : null;
  }

  VoidCallback? _semanticsOnPaste(TextSelectionControls? controls) {
    return widget.selectionEnabled &&
            pasteEnabled &&
            _hasFocus &&
            controls?.canPaste(this) == true &&
            (_clipboardStatus == null ||
                _clipboardStatus!.value == ClipboardStatus.pasteable)
        ? () => controls!.handlePaste(this)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMediaQuery(context));
    _focusAttachment!.reparent();
    super.build(context);

    final TextSelectionControls? controls = widget.selectionControls;
    int buildListIndex = 1;
    return MouseRegion(
      cursor: widget.mouseCursor ?? SystemMouseCursors.text,
      child: Scrollable(
        excludeFromSemantics: true,
        axisDirection: _isMultiline ? AxisDirection.down : AxisDirection.right,
        controller: _scrollController,
        physics: widget.scrollPhysics,
        dragStartBehavior: widget.dragStartBehavior,
        restorationId: widget.restorationId,
        viewportBuilder: (context, offset) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: _value.text
                    .split("\n")
                    .map(
                      (e) => Container(
                        child: Text(
                          "${buildListIndex++}",
                          style: TextStyle(
                            fontSize: this.widget.style.fontSize,
                            color: Colors.black45,
                          ),
                        ),
                        padding: const EdgeInsets.fromLTRB(
                          0,
                          0,
                          6,
                          0,
                        ),
                      ),
                    )
                    .toList(),
              ),
              Expanded(
                  child: Row(
                children: [
                  Expanded(
                      child: Column(
                    children: [
                      CompositedTransformTarget(
                        link: _toolbarLayerLink,
                        child: Semantics(
                          onCopy: _semanticsOnCopy(controls),
                          onCut: _semanticsOnCut(controls),
                          onPaste: _semanticsOnPaste(controls),
                          child: _Editable(
                            key: _editableKey,
                            startHandleLayerLink: _startHandleLayerLink,
                            endHandleLayerLink: _endHandleLayerLink,
                            textSpan: buildTextSpan(),
                            value: _value,
                            cursorColor: _cursorColor,
                            backgroundCursorColor: widget.backgroundCursorColor,
                            showCursor: EditableText.debugDeterministicCursor
                                ? ValueNotifier<bool>(widget.showCursor)
                                : _cursorVisibilityNotifier,
                            forceLine: widget.forceLine,
                            readOnly: widget.readOnly,
                            hasFocus: _hasFocus,
                            maxLines: widget.maxLines,
                            minLines: widget.minLines,
                            expands: widget.expands,
                            strutStyle: widget.strutStyle,
                            selectionColor: widget.selectionColor,
                            textScaleFactor: widget.textScaleFactor ??
                                MediaQuery.textScaleFactorOf(context),
                            textAlign: widget.textAlign,
                            textDirection: _textDirection,
                            locale: widget.locale,
                            textHeightBehavior: widget.textHeightBehavior ??
                                DefaultTextHeightBehavior.of(context),
                            textWidthBasis: widget.textWidthBasis,
                            obscuringCharacter: widget.obscuringCharacter,
                            obscureText: widget.obscureText,
                            autocorrect: widget.autocorrect,
                            smartDashesType: widget.smartDashesType,
                            smartQuotesType: widget.smartQuotesType,
                            enableSuggestions: widget.enableSuggestions,
                            offset: offset,
                            onCaretChanged: _handleCaretChanged,
                            rendererIgnoresPointer:
                                widget.rendererIgnoresPointer,
                            cursorWidth: widget.cursorWidth,
                            cursorHeight: widget.cursorHeight,
                            cursorRadius: widget.cursorRadius,
                            cursorOffset: widget.cursorOffset ?? Offset.zero,
                            selectionHeightStyle: widget.selectionHeightStyle,
                            selectionWidthStyle: widget.selectionWidthStyle,
                            paintCursorAboveText: widget.paintCursorAboveText,
                            enableInteractiveSelection:
                                widget.enableInteractiveSelection,
                            textSelectionDelegate: this,
                            devicePixelRatio: _devicePixelRatio,
                            promptRectRange: _currentPromptRectRange,
                            promptRectColor: widget.autocorrectionTextRectColor,
                            clipBehavior: widget.clipBehavior,
                          ),
                        ),
                      )
                    ],
                  ))
                ],
              ))
            ],
          );
        },
      ),
    );
  }

  TextSpan buildTextSpan() {
    if (widget.obscureText) {
      String text = _value.text;
      text = widget.obscuringCharacter * text.length;

      if ((defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS ||
              defaultTargetPlatform == TargetPlatform.fuchsia) &&
          !kIsWeb) {
        final int? o =
            _obscureShowCharTicksPending > 0 ? _obscureLatestCharIndex : null;
        if (o != null && o >= 0 && o < text.length)
          text = text.replaceRange(o, o + 1, _value.text.substring(o, o + 1));
      }
      return TextSpan(style: widget.style, text: text);
    }

    return widget.controller.buildTextSpan(
      context: context,
      style: widget.style,
      withComposing: !widget.readOnly,
    );
  }
}

class _WhitespaceDirectionalityFormatter extends TextInputFormatter {
  _WhitespaceDirectionalityFormatter({TextDirection? textDirection})
      : _baseDirection = textDirection,
        _previousNonWhitespaceDirection = textDirection;

  final RegExp _ltrRegExp = RegExp(
      r'[A-Za-z\u00C0-\u00D6\u00D8-\u00F6\u00F8-\u02B8\u0300-\u0590\u0800-\u1FFF\u2C00-\uFB1C\uFDFE-\uFE6F\uFEFD-\uFFFF]');

  final RegExp _rtlRegExp =
      RegExp(r'[\u0591-\u07FF\uFB1D-\uFDFD\uFE70-\uFEFC]');

  final RegExp _whitespaceRegExp = RegExp(r'\s');

  final TextDirection? _baseDirection;

  TextDirection? _previousNonWhitespaceDirection;

  bool _hasOpposingDirection = false;

  static const int _rlm = 0x200F;
  static const int _lrm = 0x200E;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (!_hasOpposingDirection) {
      _hasOpposingDirection = _baseDirection == TextDirection.ltr
          ? _rtlRegExp.hasMatch(newValue.text)
          : _ltrRegExp.hasMatch(newValue.text);
    }

    if (_hasOpposingDirection) {
      _previousNonWhitespaceDirection = _baseDirection;

      final List<int> outputCodepoints = <int>[];

      int selectionBase = newValue.selection.baseOffset;
      int selectionExtent = newValue.selection.extentOffset;
      int composingStart = newValue.composing.start;
      int composingEnd = newValue.composing.end;

      void addToLength() {
        selectionBase += outputCodepoints.length <= selectionBase ? 1 : 0;
        selectionExtent += outputCodepoints.length <= selectionExtent ? 1 : 0;

        composingStart += outputCodepoints.length <= composingStart ? 1 : 0;
        composingEnd += outputCodepoints.length <= composingEnd ? 1 : 0;
      }

      void subtractFromLength() {
        selectionBase -= outputCodepoints.length < selectionBase ? 1 : 0;
        selectionExtent -= outputCodepoints.length < selectionExtent ? 1 : 0;

        composingStart -= outputCodepoints.length < composingStart ? 1 : 0;
        composingEnd -= outputCodepoints.length < composingEnd ? 1 : 0;
      }

      final bool isBackspace =
          oldValue.text.runes.length - newValue.text.runes.length == 1 &&
              isDirectionalityMarker(oldValue.text.runes.last) &&
              oldValue.text.substring(0, oldValue.text.length - 1) ==
                  newValue.text;

      bool previousWasWhitespace = false;
      bool previousWasDirectionalityMarker = false;
      int? previousNonWhitespaceCodepoint;
      int index = 0;
      for (final int codepoint in newValue.text.runes) {
        if (isWhitespace(codepoint)) {
          if (!previousWasWhitespace &&
              previousNonWhitespaceCodepoint != null) {
            _previousNonWhitespaceDirection =
                getDirection(previousNonWhitespaceCodepoint);
          }

          if (previousWasWhitespace) {
            subtractFromLength();
            outputCodepoints.removeLast();
          }

          if (isBackspace && index == newValue.text.runes.length - 1) {
            subtractFromLength();
          } else {
            outputCodepoints.add(codepoint);
            addToLength();
            outputCodepoints.add(
                _previousNonWhitespaceDirection == TextDirection.rtl
                    ? _rlm
                    : _lrm);
          }

          previousWasWhitespace = true;
          previousWasDirectionalityMarker = false;
        } else if (isDirectionalityMarker(codepoint)) {
          if (previousWasWhitespace) {
            subtractFromLength();
            outputCodepoints.removeLast();
          }
          outputCodepoints.add(codepoint);

          previousWasWhitespace = false;
          previousWasDirectionalityMarker = true;
        } else {
          if (!previousWasDirectionalityMarker &&
              previousWasWhitespace &&
              getDirection(codepoint) == _previousNonWhitespaceDirection) {
            subtractFromLength();
            outputCodepoints.removeLast();
          }

          previousNonWhitespaceCodepoint = codepoint;
          outputCodepoints.add(codepoint);

          previousWasWhitespace = false;
          previousWasDirectionalityMarker = false;
        }
        index++;
      }
      final String formatted = String.fromCharCodes(outputCodepoints);
      return TextEditingValue(
        text: formatted,
        selection: TextSelection(
            baseOffset: selectionBase,
            extentOffset: selectionExtent,
            affinity: newValue.selection.affinity,
            isDirectional: newValue.selection.isDirectional),
        composing: TextRange(start: composingStart, end: composingEnd),
      );
    }
    return newValue;
  }

  bool isWhitespace(int value) {
    return _whitespaceRegExp.hasMatch(String.fromCharCode(value));
  }

  bool isDirectionalityMarker(int value) {
    return value == _rlm || value == _lrm;
  }

  TextDirection getDirection(int value) {
    return _ltrRegExp.hasMatch(String.fromCharCode(value))
        ? TextDirection.ltr
        : TextDirection.rtl;
  }
}

class _Editable extends LeafRenderObjectWidget {
  const _Editable({
    Key? key,
    required this.textSpan,
    required this.value,
    required this.startHandleLayerLink,
    required this.endHandleLayerLink,
    this.cursorColor,
    this.backgroundCursorColor,
    required this.showCursor,
    required this.forceLine,
    required this.readOnly,
    this.textHeightBehavior,
    required this.textWidthBasis,
    required this.hasFocus,
    required this.maxLines,
    this.minLines,
    required this.expands,
    this.strutStyle,
    this.selectionColor,
    required this.textScaleFactor,
    required this.textAlign,
    required this.textDirection,
    this.locale,
    required this.obscuringCharacter,
    required this.obscureText,
    required this.autocorrect,
    required this.smartDashesType,
    required this.smartQuotesType,
    required this.enableSuggestions,
    required this.offset,
    this.onCaretChanged,
    this.rendererIgnoresPointer = false,
    required this.cursorWidth,
    this.cursorHeight,
    this.cursorRadius,
    required this.cursorOffset,
    required this.paintCursorAboveText,
    this.selectionHeightStyle = ui.BoxHeightStyle.tight,
    this.selectionWidthStyle = ui.BoxWidthStyle.tight,
    this.enableInteractiveSelection = true,
    required this.textSelectionDelegate,
    required this.devicePixelRatio,
    this.promptRectRange,
    this.promptRectColor,
    required this.clipBehavior,
  })   : assert(textDirection != null),
        assert(rendererIgnoresPointer != null),
        super(key: key);

  final TextSpan textSpan;
  final TextEditingValue value;
  final Color? cursorColor;
  final LayerLink startHandleLayerLink;
  final LayerLink endHandleLayerLink;
  final Color? backgroundCursorColor;
  final ValueNotifier<bool> showCursor;
  final bool forceLine;
  final bool readOnly;
  final bool hasFocus;
  final int? maxLines;
  final int? minLines;
  final bool expands;
  final StrutStyle? strutStyle;
  final Color? selectionColor;
  final double textScaleFactor;
  final TextAlign textAlign;
  final TextDirection textDirection;
  final Locale? locale;
  final String obscuringCharacter;
  final bool obscureText;
  final TextHeightBehavior? textHeightBehavior;
  final TextWidthBasis textWidthBasis;
  final bool autocorrect;
  final SmartDashesType smartDashesType;
  final SmartQuotesType smartQuotesType;
  final bool enableSuggestions;
  final ViewportOffset offset;
  final CaretChangedHandler? onCaretChanged;
  final bool rendererIgnoresPointer;
  final double cursorWidth;
  final double? cursorHeight;
  final Radius? cursorRadius;
  final Offset cursorOffset;
  final bool paintCursorAboveText;
  final ui.BoxHeightStyle selectionHeightStyle;
  final ui.BoxWidthStyle selectionWidthStyle;
  final bool enableInteractiveSelection;
  final TextSelectionDelegate textSelectionDelegate;
  final double devicePixelRatio;
  final TextRange? promptRectRange;
  final Color? promptRectColor;
  final Clip clipBehavior;

  @override
  RenderEditable createRenderObject(BuildContext context) {
    return RenderEditable(
      text: textSpan,
      cursorColor: cursorColor,
      startHandleLayerLink: startHandleLayerLink,
      endHandleLayerLink: endHandleLayerLink,
      backgroundCursorColor: backgroundCursorColor,
      showCursor: showCursor,
      forceLine: forceLine,
      readOnly: readOnly,
      hasFocus: hasFocus,
      maxLines: maxLines,
      minLines: minLines,
      expands: expands,
      strutStyle: strutStyle,
      selectionColor: selectionColor,
      textScaleFactor: textScaleFactor,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale ?? Localizations.maybeLocaleOf(context),
      selection: value.selection,
      offset: offset,
      onCaretChanged: onCaretChanged,
      ignorePointer: rendererIgnoresPointer,
      obscuringCharacter: obscuringCharacter,
      obscureText: obscureText,
      textHeightBehavior: textHeightBehavior,
      textWidthBasis: textWidthBasis,
      cursorWidth: cursorWidth,
      cursorHeight: cursorHeight,
      cursorRadius: cursorRadius,
      cursorOffset: cursorOffset,
      paintCursorAboveText: paintCursorAboveText,
      selectionHeightStyle: selectionHeightStyle,
      selectionWidthStyle: selectionWidthStyle,
      enableInteractiveSelection: enableInteractiveSelection,
      textSelectionDelegate: textSelectionDelegate,
      devicePixelRatio: devicePixelRatio,
      promptRectRange: promptRectRange,
      promptRectColor: promptRectColor,
      clipBehavior: clipBehavior,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderEditable renderObject) {
    renderObject
      ..text = textSpan
      ..cursorColor = cursorColor
      ..startHandleLayerLink = startHandleLayerLink
      ..endHandleLayerLink = endHandleLayerLink
      ..showCursor = showCursor
      ..forceLine = forceLine
      ..readOnly = readOnly
      ..hasFocus = hasFocus
      ..maxLines = maxLines
      ..minLines = minLines
      ..expands = expands
      ..strutStyle = strutStyle
      ..selectionColor = selectionColor
      ..textScaleFactor = textScaleFactor
      ..textAlign = textAlign
      ..textDirection = textDirection
      ..locale = locale ?? Localizations.maybeLocaleOf(context)
      ..selection = value.selection
      ..offset = offset
      ..onCaretChanged = onCaretChanged
      ..ignorePointer = rendererIgnoresPointer
      ..textHeightBehavior = textHeightBehavior
      ..textWidthBasis = textWidthBasis
      ..obscuringCharacter = obscuringCharacter
      ..obscureText = obscureText
      ..cursorWidth = cursorWidth
      ..cursorHeight = cursorHeight
      ..cursorRadius = cursorRadius
      ..cursorOffset = cursorOffset
      ..selectionHeightStyle = selectionHeightStyle
      ..selectionWidthStyle = selectionWidthStyle
      ..textSelectionDelegate = textSelectionDelegate
      ..devicePixelRatio = devicePixelRatio
      ..paintCursorAboveText = paintCursorAboveText
      ..promptRectColor = promptRectColor
      ..clipBehavior = clipBehavior
      ..setPromptRectRange(promptRectRange);
  }
}
