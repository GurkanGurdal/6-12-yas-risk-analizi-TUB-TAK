import 'package:flutter/material.dart';

import '../core/theme.dart';

class ResultScreen extends StatelessWidget {
	final Map<String, dynamic> resultData;

	const ResultScreen({super.key, required this.resultData});

	@override
	Widget build(BuildContext context) {
		final genelRisk = _num(resultData['genel_risk_puani']);
		final analizSonucu = _text(resultData['analiz_sonucu'], fallback: 'Sonuc hazir degil');
		final renk = _riskColor(_text(resultData['grafik_rengi']));
		final katmanlar = _map(resultData['katmanlar']);
		final dikkatAlanlari = _toStringList(resultData['dikkat_gerektiren_alanlar']);

		return Scaffold(
			appBar: AppBar(
				title: const Text('Detayli Rapor'),
				backgroundColor: Colors.transparent,
				elevation: 0,
				foregroundColor: AppTheme.textDark,
				centerTitle: true,
			),
			body: SingleChildScrollView(
				padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.stretch,
					children: [
						_RiskHeroCard(
							risk: genelRisk,
							resultText: analizSonucu,
							riskColor: renk,
						),
						const SizedBox(height: 16),
						if (dikkatAlanlari.isNotEmpty)
							_AlertCard(items: dikkatAlanlari),
						const SizedBox(height: 16),
						_LayerCard(
							title: 'Genel Risk ML',
							icon: Icons.analytics_outlined,
							accent: AppTheme.primaryBlue,
							lines: [
								'Ek risk: %${_num(_map(katmanlar['genel_risk_ml'])['ek_risk']).toStringAsFixed(1)}',
								'Mutlak risk: %${_num(_map(katmanlar['genel_risk_ml'])['mutlak_risk']).toStringAsFixed(1)}',
								'Temel risk: %${_num(_map(katmanlar['genel_risk_ml'])['temel_risk']).toStringAsFixed(1)}',
								'Agirlik: ${_text(_map(katmanlar['genel_risk_ml'])['agirlik'], fallback: '-')}',
							],
						),
						const SizedBox(height: 12),
						_LayerCard(
							title: 'Psikolojik Katman',
							icon: Icons.psychology_alt_outlined,
							accent: const Color(0xFF7C3AED),
							lines: [
								'Anksiyete ek risk: %${_num(_map(_map(katmanlar['psikolojik'])['anksiyete'])['ek_risk']).toStringAsFixed(1)}',
								'Depresyon ek risk: %${_num(_map(_map(katmanlar['psikolojik'])['depresyon'])['ek_risk']).toStringAsFixed(1)}',
								'DEHB ek risk: %${_num(_map(_map(katmanlar['psikolojik'])['dehb'])['ek_risk']).toStringAsFixed(1)}',
								'Ortalama ek risk: %${_num(_map(katmanlar['psikolojik'])['ek_risk_ortalama']).toStringAsFixed(1)}',
							],
						),
						const SizedBox(height: 12),
						_LayerCard(
							title: 'Yasam Tarzi Katmani',
							icon: Icons.favorite_outline,
							accent: AppTheme.riskYellow,
							lines: [
								'Risk puani: %${_num(_map(katmanlar['yasam_tarzi'])['risk_puani']).toStringAsFixed(1)}',
								'Ekran riski: %${_num(_map(katmanlar['yasam_tarzi'])['ekran_risk']).toStringAsFixed(1)}',
								'Uyku riski: %${_num(_map(katmanlar['yasam_tarzi'])['uyku_risk']).toStringAsFixed(1)}',
								'Aktivite riski: %${_num(_map(katmanlar['yasam_tarzi'])['aktivite_risk']).toStringAsFixed(1)}',
								..._splitDetails(_text(_map(katmanlar['yasam_tarzi'])['detaylar'])).map((d) => '- $d'),
							],
						),
						const SizedBox(height: 12),
						_LayerCard(
							title: 'Fiziksel Gelisim',
							icon: Icons.accessibility_new,
							accent: AppTheme.riskGreen,
							lines: [
								'Risk puani: %${_num(_map(katmanlar['fiziksel_gelisim'])['risk_puani']).toStringAsFixed(1)}',
								'BMI: ${_num(_map(katmanlar['fiziksel_gelisim'])['hesaplanan_bmi']).toStringAsFixed(2)}',
								'Boy Z-score: ${_num(_map(katmanlar['fiziksel_gelisim'])['boy_zscore']).toStringAsFixed(2)}',
								'Kilo Z-score: ${_num(_map(katmanlar['fiziksel_gelisim'])['kilo_zscore']).toStringAsFixed(2)}',
								'BMI Z-score: ${_num(_map(katmanlar['fiziksel_gelisim'])['bmi_zscore']).toStringAsFixed(2)}',
								..._splitDetails(_text(_map(katmanlar['fiziksel_gelisim'])['detaylar'])).map((d) => '- $d'),
							],
						),
					],
				),
			),
		);
	}
}

class _RiskHeroCard extends StatelessWidget {
	final double risk;
	final String resultText;
	final Color riskColor;

	const _RiskHeroCard({
		required this.risk,
		required this.resultText,
		required this.riskColor,
	});

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.all(20),
			decoration: BoxDecoration(
				gradient: LinearGradient(
					colors: [AppTheme.primaryBlue, AppTheme.secondaryBlue],
					begin: Alignment.topLeft,
					end: Alignment.bottomRight,
				),
				borderRadius: BorderRadius.circular(24),
				boxShadow: [
					BoxShadow(
						color: AppTheme.primaryBlue.withOpacity(0.25),
						blurRadius: 24,
						offset: const Offset(0, 10),
					),
				],
			),
			child: Column(
				children: [
					const Text(
						'Genel Risk Puani',
						style: TextStyle(color: Colors.white70, fontSize: 15, fontWeight: FontWeight.w600),
					),
					const SizedBox(height: 10),
					Container(
						padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
						decoration: BoxDecoration(
							color: Colors.white,
							borderRadius: BorderRadius.circular(999),
						),
						child: Text(
							'%${risk.toStringAsFixed(1)}',
							style: TextStyle(
								color: riskColor,
								fontSize: 34,
								fontWeight: FontWeight.w800,
							),
						),
					),
					const SizedBox(height: 12),
					Text(
						resultText,
						textAlign: TextAlign.center,
						style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
					),
				],
			),
		);
	}
}

class _AlertCard extends StatelessWidget {
	final List<String> items;

	const _AlertCard({required this.items});

	@override
	Widget build(BuildContext context) {
		return Container(
			padding: const EdgeInsets.all(16),
			decoration: BoxDecoration(
				color: const Color(0xFFFFFBEB),
				borderRadius: BorderRadius.circular(20),
				border: Border.all(color: const Color(0xFFFDE68A)),
			),
			child: Column(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					const Row(
						children: [
							Icon(Icons.warning_amber_rounded, color: AppTheme.riskYellow),
							SizedBox(width: 8),
							Text(
								'Dikkat Gerektiren Alanlar',
								style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textDark),
							),
						],
					),
					const SizedBox(height: 10),
					...items.map(
						(e) => Padding(
							padding: const EdgeInsets.only(bottom: 6),
							child: Row(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									const Padding(
										padding: EdgeInsets.only(top: 4),
										child: Icon(Icons.circle, size: 8, color: AppTheme.textGray),
									),
									const SizedBox(width: 8),
									Expanded(child: Text(e, style: const TextStyle(color: AppTheme.textDark))),
								],
							),
						),
					)
				],
			),
		);
	}
}

class _LayerCard extends StatelessWidget {
	final String title;
	final IconData icon;
	final Color accent;
	final List<String> lines;

	const _LayerCard({
		required this.title,
		required this.icon,
		required this.accent,
		required this.lines,
	});

	@override
	Widget build(BuildContext context) {
		return Card(
			child: ExpansionTile(
				tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
				leading: Container(
					width: 36,
					height: 36,
					decoration: BoxDecoration(
						color: accent.withOpacity(0.12),
						borderRadius: BorderRadius.circular(12),
					),
					child: Icon(icon, color: accent),
				),
				title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textDark)),
				childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
				children: [
					...lines.map(
						(line) => Padding(
							padding: const EdgeInsets.only(bottom: 8),
							child: Row(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: [
									const Text('• ', style: TextStyle(color: AppTheme.textGray)),
									Expanded(child: Text(line, style: const TextStyle(color: AppTheme.textDark))),
								],
							),
						),
					),
				],
			),
		);
	}
}

double _num(dynamic v) {
	if (v is num) return v.toDouble();
	if (v is String) return double.tryParse(v) ?? 0;
	return 0;
}

String _text(dynamic v, {String fallback = ''}) {
	if (v == null) return fallback;
	return v.toString();
}

Map<String, dynamic> _map(dynamic v) {
	if (v is Map<String, dynamic>) return v;
	if (v is Map) {
		return v.map((k, val) => MapEntry(k.toString(), val));
	}
	return <String, dynamic>{};
}

List<String> _toStringList(dynamic v) {
	if (v is List) {
		return v.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
	}
	return const [];
}

List<String> _splitDetails(String raw) {
	if (raw.trim().isEmpty) return const [];
	return raw
			.split(';')
			.map((e) => e.trim())
			.where((e) => e.isNotEmpty)
			.toList();
}

Color _riskColor(String renk) {
	final r = renk.toLowerCase();
	if (r.contains('kirmizi') || r.contains('kırmızı') || r.contains('red')) {
		return AppTheme.riskRed;
	}
	if (r.contains('sari') || r.contains('sarı') || r.contains('yellow')) {
		return AppTheme.riskYellow;
	}
	if (r.contains('yesil') || r.contains('yeşil') || r.contains('green')) {
		return AppTheme.riskGreen;
	}
	return AppTheme.primaryBlue;
}
