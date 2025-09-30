import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MaterialApp(home: Gugu()));
}

class Gugu extends StatefulWidget {
  const Gugu({super.key});

  @override
  State<Gugu> createState() => _GuguState();
}

class _GuguState extends State<Gugu> {
  final c = TextEditingController();
  List<String> r = const [];

  void gen() {
    final n = int.tryParse(c.text.trim());
    setState(() {
      r = n == null
          ? const['정수를 입력하세요!']
          : List.generate(9, (i) => '$n x ${i + 1} = ${n * (i + 1)}');
    });
  }

  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('구구단')),
    body: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: c,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: '단 입력 (예: 7)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: gen, child: const Text('구구단 출력')),
          const SizedBox(height: 16,),
          Expanded(
            child: ListView.builder(
              itemCount: r.length,
              itemBuilder: (_, i) => ListTile(title: Text(r[i])),
            ),
          ),
        ],
      )
    )
  );
}