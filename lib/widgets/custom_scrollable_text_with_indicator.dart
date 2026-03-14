import 'package:flutter/material.dart';

class CustomScrollableTextWithIndicator extends StatefulWidget {
  final String textValue;
  final bool isDarkMode; // Assuming you pass this for text color
  final double width; // Add width parameter for the container
  final double height; // Add height parameter for the container

  const CustomScrollableTextWithIndicator({
    Key? key,
    required this.textValue,
    required this.isDarkMode,
    this.width = 250, // Default width for the container
    this.height = 60, // Default height for the container
  }) : super(key: key);

  @override
  _CustomScrollableTextWithIndicatorState createState() => _CustomScrollableTextWithIndicatorState();
}

class _CustomScrollableTextWithIndicatorState extends State<CustomScrollableTextWithIndicator> {
  late ScrollController _scrollController;
  double _scrollTopOffset = 0.0;
  bool _showCustomScrollbar = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_updateScrollOffset);

    // Initial check after the layout has been built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScrollOffset();
    });
  }

  void _updateScrollOffset() {
    // Only update if the controller is attached to a scrollable
    if (!_scrollController.hasClients) {
      // If no clients, hide the scrollbar and reset offset
      if (_showCustomScrollbar) {
        setState(() {
          _showCustomScrollbar = false;
          _scrollTopOffset = 0.0;
        });
      }
      return;
    }

    final currentScroll = _scrollController.position.pixels;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final viewportHeight = _scrollController.position.viewportDimension; // Height of the visible content area

    bool newShowCustomScrollbar = maxScroll > 0; // Is content scrollable at all?

    double newOffset = 0.0;
    if (newShowCustomScrollbar) {
      const double thumbHeight = 30.0; // Adjusted for a slightly taller thumb to look more cylindrical
      // The track height is the actual height of the scrollable area
      final double scrollbarTrackHeight = viewportHeight;
      final double movableRange = scrollbarTrackHeight - thumbHeight;

      if (maxScroll > 0) {
        newOffset = (currentScroll / maxScroll) * movableRange;
        newOffset = newOffset.clamp(0.0, movableRange); // Ensure it stays within bounds
      } else {
        newOffset = 0.0; // No scroll, so thumb is at the top
      }
    }

    // Only call setState if there's an actual change to avoid unnecessary rebuilds
    if (_showCustomScrollbar != newShowCustomScrollbar || _scrollTopOffset != newOffset) {
      setState(() {
        _showCustomScrollbar = newShowCustomScrollbar;
        _scrollTopOffset = newOffset;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollOffset); // Important: Remove listener
    _scrollController.dispose(); // Important: Dispose the controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container( // This Container provides the attractive cell styling
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8), // Slightly more rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2), // Subtle shadow
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2), // changes position of shadow
          ),
        ],
        border: Border.all(color: const Color(0xFFF0F0F0)), // Lighter, almost invisible border
      ),
      child: IntrinsicHeight( // Ensure children align their heights
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch, // Make children stretch vertically
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController, // Assign the controller
                scrollDirection: Axis.vertical,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0), // Inner padding for the text
                  child: Text(
                    widget.textValue.isEmpty || widget.textValue == "-" ? "N/A" : widget.textValue,
                    style: TextStyle(
                      fontSize: 13, // Slightly larger font
                      color: widget.isDarkMode ? Colors.black : Colors.black87, // Use black87 for better contrast
                      height: 1.4, // Improve line spacing for readability
                    ),
                  ),
                ),
              ),
            ),
            if (_showCustomScrollbar) // Only show the scrollbar if content is scrollable
              const SizedBox(width: 8.0), // Spacer between Text and scrollbar
            if (_showCustomScrollbar)
              SizedBox(
                width: 10.0, // <-- Wider scrollbar track (increased from 6.0 to 10.0)
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double scrollbarTrackHeight = constraints.maxHeight;
                    const double thumbHeight = 20.0; // <-- Slightly taller thumb for cylindrical look
                    final double movableRange = scrollbarTrackHeight - thumbHeight;

                    double calculatedTopOffset = 0.0;
                    if (_scrollController.hasClients && _scrollController.position.maxScrollExtent > 0) {
                        calculatedTopOffset = (_scrollController.position.pixels / _scrollController.position.maxScrollExtent) * movableRange;
                        calculatedTopOffset = calculatedTopOffset.clamp(0.0, movableRange);
                    }

                    return Stack(
                      alignment: Alignment.topCenter,
                      children: [
                        Container(
                          width: 4.0, // <-- Thicker vertical line for the track (increased from 2.0 to 4.0)
                          decoration: BoxDecoration(
                            color: Colors.grey[300], // Lighter grey for the track
                            borderRadius: BorderRadius.circular(2.0), // Rounded track line
                          ),
                        ),
                        Positioned(
                          top: calculatedTopOffset,
                          left: 0.0,
                          right: 0.0,
                          height: thumbHeight,
                          child: Center( // Center the cylindrical thumb on the track
                            child: Container(
                              width: 8.0, // <-- Width of the cylindrical thumb
                              height: thumbHeight,
                              decoration: BoxDecoration(
                                color: Colors.blueGrey, // Distinct thumb color
                                borderRadius: BorderRadius.circular(thumbHeight / 2), // <-- Makes it cylindrical/capsule shape
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}