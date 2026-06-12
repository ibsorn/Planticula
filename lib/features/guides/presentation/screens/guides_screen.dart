import 'package:flutter/material.dart';
import 'package:planticula/core/theme/app_colors.dart';

class GuidesScreen extends StatefulWidget {
  const GuidesScreen({super.key});

  @override
  State<GuidesScreen> createState() => _GuidesScreenState();
}

class _GuidesScreenState extends State<GuidesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Guías de cuidado 📖'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar guias...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colorScheme.surface,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildRiegoCategory(colorScheme),
                _buildLuzCategory(colorScheme),
                _buildTemperaturaCategory(colorScheme),
                _buildPlagasCategory(colorScheme),
                _buildSueloCategory(colorScheme),
                _buildPodaCategory(colorScheme),
                _buildCannabisCategory(colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiegoCategory(ColorScheme colorScheme) {
    final tips = [
      const _GuideTip(
        icon: Icons.water_drop,
        title: 'Frecuencia de riego',
        description: 'La mayoria de las plantas de interior necesitan riego cuando los primeros 2-3 cm de sustrato estan secos. Verifica insertando el dedo en la tierra.',
      ),
      const _GuideTip(
        icon: Icons.warning,
        title: 'Signos de exceso de riego',
        description: 'Hojas amarillas, tallos blandos, raices marrones y olor a humedad. Deja secar el sustrato antes de regar nuevamente.',
      ),
      const _GuideTip(
        icon: Icons.priority_high,
        title: 'Signos de falta de riego',
        description: 'Hojas marchitas, bordes secos y marrones, sustrato retraido de las paredes de la maceta. Riega abundantemente hasta que drene.',
      ),
      const _GuideTip(
        icon: Icons.schedule,
        title: 'Mejor hora para regar',
        description: 'Riega temprano en la manana o al atardecer para evitar evaporacion rapida y quemaduras por el sol.',
      ),
    ];

    final filteredTips = _filterTips(tips);
    if (_searchQuery.isNotEmpty && filteredTips.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildExpansionCategory(
      colorScheme: colorScheme,
      icon: Icons.water_drop,
      title: 'Riego',
      subtitle: 'Consejos sobre frecuencia y tecnicas de riego',
      tips: filteredTips,
      emoji: '💧',
      accent: AppColors.water,
      deep: AppColors.waterDeep,
      soft: AppColors.waterSoft,
    );
  }

  Widget _buildLuzCategory(ColorScheme colorScheme) {
    final tips = [
      const _GuideTip(
        icon: Icons.wb_sunny,
        title: 'Entendiendo las necesidades de luz',
        description: 'Luz directa: sol sin filtrar. Luz indirecta brillante: cerca de ventana sin sol directo. Sombra: lejos de ventanas o con cortinas.',
      ),
      const _GuideTip(
        icon: Icons.home,
        title: 'Interior vs Exterior',
        description: 'Las plantas de interior generalmente necesitan luz indirecta. Las de exterior soportan mas variedad, desde sombra hasta sol pleno.',
      ),
      const _GuideTip(
        icon: Icons.brightness_high,
        title: 'Demasiada luz',
        description: 'Hojas quemadas con manchas marrones, colores apagados, tallos debilitados. Mueve la planta a un lugar con menos luz directa.',
      ),
      const _GuideTip(
        icon: Icons.brightness_low,
        title: 'Poca luz',
        description: 'Crecimiento lento o ausente, hojas pequenas, planta se estira buscando luz. Considera lamparas de crecimiento LED.',
      ),
    ];

    final filteredTips = _filterTips(tips);
    if (_searchQuery.isNotEmpty && filteredTips.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildExpansionCategory(
      colorScheme: colorScheme,
      icon: Icons.wb_sunny,
      title: 'Luz y Sol',
      subtitle: 'Comprende las necesidades luminicas de tus plantas',
      tips: filteredTips,
      emoji: '☀️',
      accent: AppColors.sun,
      deep: AppColors.sunDeep,
      soft: AppColors.sunSoft,
    );
  }

  Widget _buildTemperaturaCategory(ColorScheme colorScheme) {
    final tips = [
      const _GuideTip(
        icon: Icons.thermostat,
        title: 'Rangos de temperatura ideales',
        description: 'Plantas tropicales: 18-27 C. Plantas templadas: 10-21 C. Evita cambios bruscos de temperatura y corrientes de aire.',
      ),
      const _GuideTip(
        icon: Icons.water,
        title: 'Consejos de humedad',
        description: 'La mayoria de plantas de interior prefieren 40-60% de humedad. Usa humidificadores, platos con guijarros o agrupa plantas.',
      ),
      const _GuideTip(
        icon: Icons.calendar_today,
        title: 'Ajustes estacionales',
        description: 'Reduce riego en invierno. Protege de heladas. Aumenta humedad cuando la calefaccion esta encendida.',
      ),
      const _GuideTip(
        icon: Icons.ac_unit,
        title: 'Senales de temperatura extrema',
        description: 'Manchas oscuras por frio, hojas caidas por calor excesivo. Manten las plantas lejos de radiadores y aire acondicionado.',
      ),
    ];

    final filteredTips = _filterTips(tips);
    if (_searchQuery.isNotEmpty && filteredTips.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildExpansionCategory(
      colorScheme: colorScheme,
      icon: Icons.thermostat,
      title: 'Temperatura y Humedad',
      subtitle: 'Controla el ambiente para un crecimiento optimo',
      tips: filteredTips,
      emoji: '🌡️',
      accent: AppColors.soil,
      deep: AppColors.soilDeep,
      soft: AppColors.soilSoft,
    );
  }

  Widget _buildPlagasCategory(ColorScheme colorScheme) {
    final tips = [
      const _GuideTip(
        icon: Icons.bug_report,
        title: 'Plagas comunes',
        description: 'Pulgon: insectos pequenos verdes o negros en brotes nuevos. Cochinilla: puntos algodonosos en hojas. Acaro: telaranas y puntos amarillos.',
      ),
      const _GuideTip(
        icon: Icons.shield,
        title: 'Prevencion',
        description: 'Inspecciona plantas nuevas antes de introducirlas. Limpia hojas regularmente. Manten buena ventilacion y evita encharcamiento.',
      ),
      const _GuideTip(
        icon: Icons.healing,
        title: 'Tratamientos',
        description: 'Jabon insecticida para pulgones. Alcohol isopropilico para cochinillas. Neem oil para multiples plagas. Repite cada 7 dias.',
      ),
      const _GuideTip(
        icon: Icons.sanitizer,
        title: 'Enfermedades fungicas',
        description: 'Oidio: polvo blanco en hojas. Botrytis: moho gris. Fusarium: marchitamiento. Mejora ventilacion y reduce humedad excesiva.',
      ),
    ];

    final filteredTips = _filterTips(tips);
    if (_searchQuery.isNotEmpty && filteredTips.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildExpansionCategory(
      colorScheme: colorScheme,
      icon: Icons.bug_report,
      title: 'Plagas y Enfermedades',
      subtitle: 'Identifica, previene y trata problemas comunes',
      tips: filteredTips,
      emoji: '🐛',
      accent: AppColors.pest,
      deep: AppColors.pestDeep,
      soft: AppColors.pestSoft,
    );
  }

  Widget _buildSueloCategory(ColorScheme colorScheme) {
    final tips = [
      const _GuideTip(
        icon: Icons.grass,
        title: 'Tipos de sustrato',
        description: 'Universal: equilibrado para la mayoria. Cactus: bien drenado con arena. Orquideas: corteza de pino. Acidofilas: pH bajo para helechos y gardenias.',
      ),
      const _GuideTip(
        icon: Icons.event,
        title: 'Cuando fertilizar',
        description: 'Durante crecimiento activo (primavera-verano). Reduce en otono. Suspender en invierno. Sigue instrucciones del fabricante.',
      ),
      const _GuideTip(
        icon: Icons.eco,
        title: 'Organico vs Quimico',
        description: 'Organico: liberacion lenta, mejora sustrato a largo plazo. Quimico: efecto inmediato, riesgo de sobrefertilizacion. Alterna ambos.',
      ),
      const _GuideTip(
        icon: Icons.science,
        title: 'Deficiencias visibles',
        description: 'Nitrogeno: hojas amarillas en base. Fosforo: crecimiento lento, bordes purpuras. Potasio: bordes marrones. Hierro: hojas jovenes amarillas.',
      ),
    ];

    final filteredTips = _filterTips(tips);
    if (_searchQuery.isNotEmpty && filteredTips.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildExpansionCategory(
      colorScheme: colorScheme,
      icon: Icons.grass,
      title: 'Suelo y Abono',
      subtitle: 'Nutricion y salud del sustrato',
      tips: filteredTips,
      emoji: '🪨',
    );
  }

  Widget _buildPodaCategory(ColorScheme colorScheme) {
    final tips = [
      const _GuideTip(
        icon: Icons.content_cut,
        title: 'Cuando podar',
        description: 'Elimina ramas muertas o danadas en cualquier momento. Poda de forma despues de floracion. Mantenimiento en primavera para la mayoria.',
      ),
      const _GuideTip(
        icon: Icons.swap_horiz,
        title: 'Senales para trasplantar',
        description: 'Raices salen por drenaje, sustrato se seca muy rapido, planta se ve desproporcionada, crecimiento se ha estancado.',
      ),
      const _GuideTip(
        icon: Icons.straighten,
        title: 'Guia de tamanos de maceta',
        description: 'Elige 2-5 cm mas grande en diametro. No uses maceta excesivamente grande. Asegura buenos agujeros de drenaje.',
      ),
      const _GuideTip(
        icon: Icons.restore,
        title: 'Cuidados post-trasplante',
        description: 'Riega bien despues de trasplantar. Evita sol directo por una semana. No fertilices durante 2-4 semanas.',
      ),
    ];

    final filteredTips = _filterTips(tips);
    if (_searchQuery.isNotEmpty && filteredTips.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildExpansionCategory(
      colorScheme: colorScheme,
      icon: Icons.content_cut,
      title: 'Poda y Trasplante',
      subtitle: 'Mantenimiento estructural de las plantas',
      tips: filteredTips,
      emoji: '✂️',
      accent: AppColors.market,
      deep: AppColors.marketDeep,
      soft: AppColors.marketSoft,
    );
  }

  Widget _buildCannabisCategory(ColorScheme colorScheme) {
    final tips = [
      const _GuideTip(
        icon: Icons.local_florist,
        title: 'Fase vegetativa',
        description: 'Crecimiento de tallos y hojas. Luz 18-24 horas. Alta necesidad de nitrogeno (N). Duracion: 2-8 semanas segun variedad.',
      ),
      const _GuideTip(
        icon: Icons.filter_vintage,
        title: 'Fase de floracion',
        description: 'Desarrollo de cogollos. Cambia a ciclo 12/12 (12h luz / 12h oscuridad total). Aumenta fosforo (P) y potasio (K).',
      ),
      const _GuideTip(
        icon: Icons.lightbulb,
        title: 'Ciclos de luz',
        description: 'Vegetativo: 18/6 o 24/0 (luz/oscuridad). Floracion: 12/12 obligatorio. La oscuridad total es crucial en floracion.',
      ),
      const _GuideTip(
        icon: Icons.water_drop,
        title: 'Niveles de pH',
        description: 'Suelo: 6.0-7.0. Hidroponia: 5.5-6.5. Controla el pH para absorcion optima de nutrientes. Usa medidor de pH.',
      ),
      const _GuideTip(
        icon: Icons.science,
        title: 'Nutrientes N-P-K',
        description: 'Vegetativa: alto N, medio P, medio K. Floracion: bajo N, alto P, alto K. Los micronutrientes (Ca, Mg, Fe) son esenciales.',
      ),
      const _GuideTip(
        icon: Icons.calendar_month,
        title: 'Tiempo de cosecha',
        description: 'Observa tricomas con lupa: transparentes = inmaduro, lechosos = pico THC, ambar = mas relajante. Cosecha cuando 70-80% esten lechosos.',
      ),
    ];

    final filteredTips = _filterTips(tips);
    if (_searchQuery.isNotEmpty && filteredTips.isEmpty) {
      return const SizedBox.shrink();
    }

    return _buildExpansionCategory(
      colorScheme: colorScheme,
      icon: Icons.local_florist,
      title: 'Cannabis',
      subtitle: 'Guias especificas para cultivo de cannabis',
      tips: filteredTips,
    );
  }

  List<_GuideTip> _filterTips(List<_GuideTip> tips) {
    if (_searchQuery.isEmpty) return tips;
    return tips.where((tip) {
      return tip.title.toLowerCase().contains(_searchQuery) ||
          tip.description.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  Widget _buildExpansionCategory({
    required ColorScheme colorScheme,
    required IconData icon,
    required String title,
    required String subtitle,
    required List<_GuideTip> tips,
    String emoji = '🌿',
    Color accent = AppColors.primary,
    Color deep = AppColors.primaryDeep,
    Color soft = AppColors.primarySoft,
  }) {
    if (tips.isEmpty) {
      return const SizedBox.shrink();
    }

    final bg = AppColors.softOf(context, accent, soft);
    final fg = AppColors.onSoftOf(context, deep, accent);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Text(emoji, style: const TextStyle(fontSize: 26)),
          iconColor: fg,
          collapsedIconColor: fg,
          title: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: fg.withValues(alpha: 0.8),
            ),
          ),
          children:
              tips.map((tip) => _buildTipCard(tip, colorScheme, accent)).toList(),
        ),
      ),
    );
  }

  Widget _buildTipCard(_GuideTip tip, ColorScheme colorScheme, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        elevation: 0,
        color: colorScheme.surface,
        child: ListTile(
          leading: Icon(
            tip.icon,
            color: accent,
          ),
          title: Text(
            tip.title,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: colorScheme.onSurface,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              tip.description,
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurface.withAlpha(179),
                height: 1.4,
              ),
            ),
          ),
          isThreeLine: true,
        ),
      ),
    );
  }
}

class _GuideTip {
  final IconData icon;
  final String title;
  final String description;

  const _GuideTip({
    required this.icon,
    required this.title,
    required this.description,
  });
}
