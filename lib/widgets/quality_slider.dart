import 'package:flutter/material.dart';

class QualitySlider extends StatefulWidget {
  final double initial;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  const QualitySlider({
    Key? key,
    required this.initial,
    required this.onChanged,
    required this.onChangeEnd,
  }) : super(key: key);

  @override
  _QualitySliderState createState() => _QualitySliderState();
}

class _QualitySliderState extends State<QualitySlider> {
  late double _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Slider(
            value: _value,
            min: 10,
            max: 100,
            divisions: 18,
            label: _value.round().toString(),
            onChanged: (v) {
              setState(() {
                _value = v;
              });
              widget.onChanged(v);
            },
            onChangeEnd: widget.onChangeEnd,
          ),
        ),
        Text(
          _value.round().toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
