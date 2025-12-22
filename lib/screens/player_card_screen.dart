import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

class PlayerCardScreen extends StatefulWidget {
  final String playerId, playerName, userRole;
  const PlayerCardScreen({
    super.key,
    required this.playerId,
    required this.playerName,
    required this.userRole,
  });

  @override
  State<PlayerCardScreen> createState() => _PlayerCardScreenState();
}

class _PlayerCardScreenState extends State<PlayerCardScreen>
    with SingleTickerProviderStateMixin {
  String? _avatarUrl;
  double _pac = 75, _sho = 75, _pas = 75, _dri = 75, _def = 75, _phy = 75;
  late AnimationController _shine;

  @override
  void initState() {
    super.initState();
    _load();
    _shine = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _shine.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final r = await Supabase.instance.client
        .from('profiles')
        .select('avatar_url')
        .eq('id', widget.playerId)
        .maybeSingle();
    if (mounted && r != null) setState(() => _avatarUrl = r['avatar_url']);
    final rp = await Supabase.instance.client
        .from('quarterly_reports')
        .select()
        .eq('player_id', widget.playerId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    if (rp != null && mounted) {
      setState(() {
        _phy = (rp['physical_score'] * 9).toDouble();
        _sho = (rp['technical_score'] * 9).toDouble();
      });
    }
  }

  Future<void> _save() async {
    if (widget.userRole == 'coach') {
      await Supabase.instance.client.from('quarterly_reports').upsert({
        'player_id': widget.playerId,
        'physical_score': (_phy / 9).toInt(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Guardado"),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isCoach = widget.userRole == 'coach';
    int media = ((_pac + _sho + _pas + _dri + _def + _phy) / 6).toInt();
    return Scaffold(
      appBar: AppBar(title: Text(widget.playerName)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPlayerCard(media),
              const SizedBox(height: 30),
              isCoach ? _buildCoachEditor() : _buildPlayerAnalysis(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerCard(int media) {
    return Container(
      height: 500,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 25,
            color: Colors.black.withAlpha(128),
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withAlpha(77),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: 0.05,
              child: Image.network(
                "https://www.transparenttextures.com/patterns/carbon-fibre.png",
                repeat: ImageRepeat.repeat,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _shine,
            builder: (c, child) => Positioned(
              left: -200 + (_shine.value * 600),
              top: -100,
              bottom: -100,
              width: 50,
              child: Transform.rotate(
                angle: 0.5,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withAlpha(0),
                        Theme.of(context).colorScheme.primary.withAlpha(51),
                        Colors.white.withAlpha(0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Text(
                          "$media",
                          style: TextStyle(
                            fontSize: 50,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        Text(
                          "MCO",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary,
                          width: 3,
                        ),
                        image: _avatarUrl != null
                            ? DecorationImage(
                                image: NetworkImage(_avatarUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                      child: _avatarUrl == null
                          ? Icon(
                              Icons.person,
                              size: 80,
                              color: Theme.of(context).colorScheme.onSurface,
                            )
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  widget.playerName.toUpperCase(),
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                Divider(
                  color: Theme.of(context).colorScheme.primary.withAlpha(128),
                  thickness: 2,
                  indent: 40,
                  endIndent: 40,
                  height: 30,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _stat("PAC", _pac),
                          const SizedBox(height: 10),
                          _stat("TIR", _sho),
                          const SizedBox(height: 10),
                          _stat("PAS", _pas),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _stat("REG", _dri),
                          const SizedBox(height: 10),
                          _stat("DEF", _def),
                          const SizedBox(height: 10),
                          _stat("FIS", _phy),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  "FUTBOL.AI LEGEND",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachEditor() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Editor Técnico",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            _slider("Ritmo", _pac, (v) => _pac = v),
            _slider("Tiro", _sho, (v) => _sho = v),
            _slider("Pase", _pas, (v) => _pas = v),
            _slider("Regate", _dri, (v) => _dri = v),
            _slider("Defensa", _def, (v) => _def = v),
            _slider("Físico", _phy, (v) => _phy = v),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save),
                label: const Text(
                  "GUARDAR CAMBIOS",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerAnalysis() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text("Análisis", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 30),
            AspectRatio(
              aspectRatio: 1.3,
              child: RadarChart(
                RadarChartData(
                  dataSets: [
                    RadarDataSet(
                      fillColor: Theme.of(
                        context,
                      ).colorScheme.primary.withAlpha(102),
                      borderColor: Theme.of(context).colorScheme.primary,
                      entryRadius: 4,
                      borderWidth: 3,
                      dataEntries: [
                        RadarEntry(value: _sho),
                        RadarEntry(value: _pas),
                        RadarEntry(value: _phy),
                        RadarEntry(value: _dri),
                        RadarEntry(value: _def),
                        RadarEntry(value: _pac),
                      ],
                    ),
                  ],
                  radarBackgroundColor: Colors.transparent,
                  borderData: FlBorderData(show: false),
                  radarBorderData: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(51),
                  ),
                  titlePositionPercentageOffset: 0.2,
                  titleTextStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 12,
                  ),
                  getTitle: (i, a) => RadarChartTitle(
                    text: [
                      'Tiro',
                      'Pase',
                      'Físico',
                      'Regate',
                      'Defensa',
                      'Ritmo',
                    ][i % 6],
                    angle: 0,
                  ),
                  tickCount: 5,
                  ticksTextStyle: const TextStyle(
                    color: Colors.transparent,
                    fontSize: 10,
                  ),
                  tickBorderData: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(26),
                  ),
                  gridBorderData: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withAlpha(51),
                    width: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String l, double v) => Row(
    children: [
      Text(
        "${v.toInt()}",
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      const SizedBox(width: 5),
      Text(l, style: Theme.of(context).textTheme.bodySmall),
    ],
  );
  Widget _slider(String l, double v, Function(double) f) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: Theme.of(context).textTheme.bodyLarge),
          Text(
            "${v.toInt()}",
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      Slider(
        value: v,
        min: 0,
        max: 99,
        activeColor: Theme.of(context).colorScheme.primary,
        inactiveColor: Theme.of(context).colorScheme.surface,
        onChanged: (x) => setState(() => f(x)),
      ),
      const SizedBox(height: 10),
    ],
  );
}
