/// Datas, horas, distâncias e preços escritos como no mockup (pt-PT).
library;

const _diasCurtos = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
const _diasLongos = ['Segunda', 'Terça', 'Quarta', 'Quinta', 'Sexta', 'Sábado', 'Domingo'];
const _meses = [
  'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
  'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
];
const _mesesCurtos = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez'];

String _doisDigitos(int n) => n.toString().padLeft(2, '0');

/// 10:00
String hora(DateTime d) => '${_doisDigitos(d.hour)}:${_doisDigitos(d.minute)}';

/// Segunda (dia_semana da BD: 1 = segunda)
String nomeDoDia(int diaSemana) => _diasLongos[diaSemana - 1];

/// Sáb, 3 de outubro
String dataCampo(DateTime d) => '${_diasCurtos[d.weekday - 1]}, ${d.day} de ${_meses[d.month - 1]}';

/// Sáb, 3 de outubro · 10:00
String dataMedia(DateTime d) => '${dataCampo(d)} · ${hora(d)}';

/// Sábado, 3 de outubro às 10:00
String dataLonga(DateTime d) => '${_diasLongos[d.weekday - 1]}, ${d.day} de ${_meses[d.month - 1]} às ${hora(d)}';

/// Sáb, 3 Out · 10:00
String dataCurta(DateTime d) => '${_diasCurtos[d.weekday - 1]}, ${d.day} ${_mesesCurtos[d.month - 1]} · ${hora(d)}';

/// hoje às 19:00 · amanhã às 10:00 · quarta às 18:00
String diaHora(DateTime d) {
  final hoje = DateTime.now();
  final dia = DateTime(d.year, d.month, d.day);
  final diferenca = dia.difference(DateTime(hoje.year, hoje.month, hoje.day)).inDays;
  final quando = switch (diferenca) {
    0 => 'hoje',
    1 => 'amanhã',
    _ => _diasLongos[d.weekday - 1].toLowerCase(),
  };
  return '$quando às ${hora(d)}';
}

/// Há 5 minutos · Há 2 horas · Ontem · Há 3 dias
String tempoRelativo(DateTime d) {
  final passou = DateTime.now().difference(d);
  if (passou.inMinutes < 1) return 'Agora';
  if (passou.inMinutes < 60) return 'Há ${passou.inMinutes} minutos';
  if (passou.inHours < 24) return 'Há ${passou.inHours} horas';
  if (passou.inDays < 2) return 'Ontem';
  return 'Há ${passou.inDays} dias';
}

/// 1,8 km
String km(double valor) => '${valor.toStringAsFixed(1).replaceAll('.', ',')} km';

/// 8 € · 7,50 €
String euros(double valor) => valor == valor.roundToDouble()
    ? '${valor.toInt()} €'
    : '${valor.toStringAsFixed(2).replaceAll('.', ',')} €';

/// "18:00" → "18h" · "13:30" → "13h30"
String horaCurta(String hhmm) {
  final partes = hhmm.split(':');
  return partes[1] == '00' ? '${int.parse(partes[0])}h' : '${int.parse(partes[0])}h${partes[1]}';
}

/// Formato que a API espera: 2026-10-31 10:00:00
String paraApi(DateTime d) =>
    '${d.year}-${_doisDigitos(d.month)}-${_doisDigitos(d.day)} ${hora(d)}:00';

/// Hora a propor num convite: o início da disponibilidade de hoje, ou daqui a 1 hora.
DateTime inicioConvite(String? disponivelHoje) {
  final agora = DateTime.now();
  if (disponivelHoje != null) {
    final partes = disponivelHoje.substring(0, 5).split(':');
    final inicio = DateTime(agora.year, agora.month, agora.day, int.parse(partes[0]), int.parse(partes[1]));
    if (inicio.isAfter(agora)) return inicio;
  }
  return DateTime(agora.year, agora.month, agora.day, agora.hour + 1);
}
