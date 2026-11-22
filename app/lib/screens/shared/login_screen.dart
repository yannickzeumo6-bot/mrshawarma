import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common.dart';
import '../../widgets/fx.dart';

/// Page de connexion partagée. role = 'client' (connexion + inscription) ou 'admin' (connexion seule).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.role});
  final String role;
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _register = false, _busy = false, _hide = true;
  String? _error;
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();

  bool get _isAdmin => widget.role != 'client'; // admin et livreur : connexion seule
  String get _roleLabel => widget.role == 'admin' ? 'ESPACE ADMINISTRATEUR' : 'ESPACE LIVREUR';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    if (_register && _name.text.trim().isEmpty) return setState(() => _error = 'Le nom est requis.');
    if (!_email.text.contains('@')) return setState(() => _error = 'Email invalide.');
    if (_pass.text.length < (_register ? 8 : 1)) return setState(() => _error = 'Mot de passe : 8 caractères minimum.');
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      _register ? await auth.register(_name.text, _email.text, _pass.text) : await auth.login(_email.text, _pass.text);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
    if (mounted) setState(() => _busy = false);
  }

  Widget _tab(String label, bool active, VoidCallback onTap) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: active ? Brand.goldGradient : null,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(label, style: TextStyle(fontWeight: FontWeight.w800, color: active ? Brand.ink : Brand.dim)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Brand.ink,
      body: SingleChildScrollView(
        child: Column(children: [
          // ---- En-tête : photo du shawarma + logo + logotype ----
          SizedBox(
            height: 330,
            child: Stack(fit: StackFit.expand, children: [
              KenBurns(child: Image.asset('assets/images/hero.jpg', fit: BoxFit.cover, alignment: Alignment.center)),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x66000000), Color(0x00000000), Color(0xCC0A0806), Brand.ink],
                    stops: [0, 0.35, 0.78, 1],
                  ),
                ),
              ),
              Positioned(top: 0, left: 0, right: 0, child: SafeArea(child: Padding(padding: const EdgeInsets.all(16), child: Align(alignment: Alignment.topLeft, child: Floating(child: Image.asset('assets/images/logo.png', width: 62)))))),
              Positioned(
                left: 0,
                right: 0,
                bottom: 4,
                child: FadeSlideIn(delay: const Duration(milliseconds: 150), offset: const Offset(0, 0.25), duration: const Duration(milliseconds: 800), child: Image.asset('assets/images/wordmark.png', height: 150, fit: BoxFit.contain)),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 28),
            child: FadeSlideIn(
              delay: const Duration(milliseconds: 380),
              child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (_isAdmin)
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 18),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(border: Border.all(color: Brand.gold.withOpacity(0.6)), borderRadius: BorderRadius.circular(20)),
                      child: Text(_roleLabel, style: Brand.display(13, color: Brand.gold, spacing: 1.6)),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(4),
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(color: Brand.card, borderRadius: BorderRadius.circular(26), border: Border.all(color: Brand.line)),
                    child: Row(children: [
                      _tab('Connexion', !_register, () => setState(() { _register = false; _error = null; })),
                      _tab('Inscription', _register, () => setState(() { _register = true; _error = null; })),
                    ]),
                  ),
                if (_register) ...[
                  TextField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Nom complet', prefixIcon: Icon(Icons.person_outline)),
                  ),
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _pass,
                  obscureText: _hide,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    labelText: 'Mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_hide ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                      onPressed: () => setState(() => _hide = !_hide),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Brand.danger.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                    child: Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Brand.danger, fontWeight: FontWeight.w600)),
                  ),
                ],
                const SizedBox(height: 22),
                GoldButton(label: _register ? 'Créer mon compte' : 'Se connecter', busy: _busy, onPressed: _submit),
                const SizedBox(height: 26),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  for (final w in ['SAVEUR', 'QUALITÉ', 'FRAÎCHEUR']) ...[
                    Text(w, style: Brand.display(12, color: Brand.gold, spacing: 1.8)),
                    if (w != 'FRAÎCHEUR') const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text('•', style: TextStyle(color: Brand.dim))),
                  ],
                ]),
              ]),
            )),
          ),
        ]),
      ),
    );
  }
}
