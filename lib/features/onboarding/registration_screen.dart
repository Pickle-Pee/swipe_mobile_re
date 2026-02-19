import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/routes.dart';
import '../../shared/theme/tokens.dart';
import '../../shared/ui/liquid_ui.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  int step = 0;
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _city = TextEditingController();
  String _selected = '';
  final Set<String> _interests = {};

  final interestPool = const [
    'Art', 'Music', 'Travel', 'Food', 'Sports', 'Reading', 'Nature', 'Technology', 'Dancing', 'Gaming'
  ];

  bool get canGoNext {
    switch (step) {
      case 0:
        return _name.text.trim().isNotEmpty;
      case 1:
        return int.tryParse(_age.text) != null;
      case 2:
        return _selected.isNotEmpty;
      case 3:
        return _city.text.trim().isNotEmpty;
      case 4:
        return _interests.isNotEmpty;
      default:
        return true;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppGradientScaffold(
        child: Padding(
          padding: AppTokens.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                if (step > 0)
                  IconButton(
                    onPressed: () => setState(() => step--),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                Text('Registration', style: Theme.of(context).textTheme.titleLarge),
              ]),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (step + 1) / 5,
                color: AppTokens.blueSoft,
                backgroundColor: AppTokens.surface,
                minHeight: 6,
                borderRadius: BorderRadius.circular(99),
              ),
              const SizedBox(height: 24),
              Expanded(child: _content()),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  label: step == 4 ? 'Continue to discovery' : 'Next',
                  onPressed: !canGoNext
                      ? () {}
                      : () {
                          if (step == 4) {
                            context.go(Routes.discover);
                          } else {
                            setState(() => step++);
                          }
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _content() {
    switch (step) {
      case 0:
        return GlassSurface(
          child: TextField(
            controller: _name,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'Your name', prefixIcon: Icon(Icons.person_outline)),
          ),
        );
      case 1:
        return GlassSurface(
          child: TextField(
            controller: _age,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'Your age', prefixIcon: Icon(Icons.cake_outlined)),
          ),
        );
      case 2:
        return GlassSurface(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: ['Woman', 'Man', 'Non-binary']
                .map((e) => ChoiceChip(
                      label: Text(e),
                      selected: _selected == e,
                      onSelected: (_) => setState(() => _selected = e),
                    ))
                .toList(),
          ),
        );
      case 3:
        return GlassSurface(
          child: TextField(
            controller: _city,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(hintText: 'City', prefixIcon: Icon(Icons.location_on_outlined)),
          ),
        );
      default:
        return GlassSurface(
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: interestPool
                  .map((i) => FilterChip(
                        label: Text(i),
                        selected: _interests.contains(i),
                        onSelected: (_) => setState(() {
                          _interests.contains(i) ? _interests.remove(i) : _interests.add(i);
                        }),
                      ))
                  .toList(),
            ),
          ),
        );
    }
  }
}
