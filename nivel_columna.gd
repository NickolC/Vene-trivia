extends Control

class ParejaRelacion:
	var id: int
	var texto_izq: String
	var texto_der: String
	
	func _init(_id: int, _izq: String, _der: String):
		self.id = _id
		self.texto_izq = _izq
		self.texto_der = _der

# --- CONFIGURACIÓN DE RECOMPENSAS BASE ---
const RECOMPENSA_BASE_PUNTOS := 100
const MONEDAS_POR_ESTRELLA := 50
const RUTA_ESCENA_SELECCION := "res://Scenes/Minijuegos.tscn"
const RUTA_DATOS_COLUMNAS := "res://Data/minijuegos/columnas.json"

# --- NUEVO DICCIONARIO: TIEMPOS MÁXIMOS POR NIVEL (Máx 8 min = 480s) ---
const TIEMPOS_POR_NIVEL: Dictionary = {
	1: 480.0, 2: 480.0, 3: 480.0, 4: 480.0, 5: 480.0,
	6: 480.0, 7: 480.0, 8: 480.0, 9: 480.0, 10: 480.0,
	11: 480.0, 12: 480.0, 13: 480.0, 14: 480.0, 15: 480.0
}

# --- BANCO DE DATOS MAESTRO: 15 NIVELES CON 3 TEMAS PROPIOS CADA UNO ---
var BANCO_NIVELES_GLOBAL: Dictionary = {
	1: {
		1: {"titulo": "Nivel 1 - Tema 1: Fechas Festivas", "parejas": 
			[ParejaRelacion.new(1,"25 de Dic","Navidad"), ParejaRelacion.new(2,"1 de Ene","Año Nuevo"), 
			ParejaRelacion.new(3,"12 de Oct","Resistencia Indígena"), ParejaRelacion.new(4,"19 de Abr","Independencia"), 
			ParejaRelacion.new(5,"19 de Abr","Independencia"), ParejaRelacion.new(6,"19 de Abr","Independencia"), 
			ParejaRelacion.new(7,"19 de Abr","Independencia"),ParejaRelacion.new(8,"19 de Abr","Independencia")]},
		2: {"titulo": "Nivel 1 - Tema 2: Héroes Patrios", "parejas": [ParejaRelacion.new(9,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(10,"Sucre","Gran Mariscal"), ParejaRelacion.new(11,"Miranda","Precursor"), 
		ParejaRelacion.new(12,"19 de Abr","Independencia"), ParejaRelacion.new(13,"19 de Abr","Independencia"), 
		ParejaRelacion.new(14,"19 de Abr","Independencia"),ParejaRelacion.new(15,"19 de Abr","Independencia"),
		ParejaRelacion.new(16,"19 de Abr","Independencia")]},
		3: {"titulo": "Nivel 1 - Tema 3: Símbolos", "parejas": [ParejaRelacion.new(17,"Amarillo","Riqueza"), 
		ParejaRelacion.new(18,"Azul","El Mar"), ParejaRelacion.new(19,"Rojo","Sangre Héroes"), 
		ParejaRelacion.new(20,"19 de Abr","Independencia"), ParejaRelacion.new(21,"19 de Abr","Independencia"),
		ParejaRelacion.new(22,"19 de Abr","Independencia"),ParejaRelacion.new(23,"19 de Abr","Independencia"),
		ParejaRelacion.new(24,"19 de Abr","Independencia")]}
	},
	2: {
		1: {"titulo": "Nivel 2 - Tema 1: Batallas", "parejas": [ParejaRelacion.new(25,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(26,"Sucre","Gran Mariscal"), ParejaRelacion.new(27,"Miranda","Precursor"), 
		ParejaRelacion.new(28,"19 de Abr","Independencia"), ParejaRelacion.new(29,"19 de Abr","Independencia"), 
		ParejaRelacion.new(30,"19 de Abr","Independencia"),ParejaRelacion.new(31,"19 de Abr","Independencia"),
		ParejaRelacion.new(32,"19 de Abr","Independencia")]},
		2: {"titulo": "Nivel 2 - Tema 2: Cultura", "parejas": [ParejaRelacion.new(33,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(34,"Sucre","Gran Mariscal"), ParejaRelacion.new(35,"Miranda","Precursor"), 
		ParejaRelacion.new(36,"19 de Abr","Independencia"), ParejaRelacion.new(37,"19 de Abr","Independencia"), 
		ParejaRelacion.new(38,"19 de Abr","Independencia"),ParejaRelacion.new(39,"19 de Abr","Independencia"),
		ParejaRelacion.new(40,"19 de Abr","Independencia")]},
		3: {"titulo": "Nivel 2 - Tema 3: Geografía", "parejas": [ParejaRelacion.new(41,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(42,"Sucre","Gran Mariscal"), ParejaRelacion.new(43,"Miranda","Precursor"), 
		ParejaRelacion.new(44,"19 de Abr","Independencia"), ParejaRelacion.new(45,"19 de Abr","Independencia"), 
		ParejaRelacion.new(46,"19 de Abr","Independencia"),ParejaRelacion.new(47,"19 de Abr","Independencia"),
		ParejaRelacion.new(48,"19 de Abr","Independencia")]}
	},
	3: {
		1: {"titulo": "Nivel 3 - Tema 1: Batallas", "parejas": [ParejaRelacion.new(49,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(50,"Sucre","Gran Mariscal"), ParejaRelacion.new(51,"Miranda","Precursor"), 
		ParejaRelacion.new(52,"19 de Abr","Independencia"), ParejaRelacion.new(53,"19 de Abr","Independencia"), 
		ParejaRelacion.new(54,"19 de Abr","Independencia"),ParejaRelacion.new(55,"19 de Abr","Independencia"),
		ParejaRelacion.new(56,"19 de Abr","Independencia")]},
		2: {"titulo": "Nivel 3 - Tema 2: Cultura", "parejas": [ParejaRelacion.new(57,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(58,"Sucre","Gran Mariscal"), ParejaRelacion.new(59,"Miranda","Precursor"), 
		ParejaRelacion.new(60,"19 de Abr","Independencia"), ParejaRelacion.new(61,"19 de Abr","Independencia"), 
		ParejaRelacion.new(62,"19 de Abr","Independencia"),ParejaRelacion.new(63,"19 de Abr","Independencia"),
		ParejaRelacion.new(64,"19 de Abr","Independencia")]},
		3: {"titulo": "Nivel 3 - Tema 3: Geografía", "parejas": [ParejaRelacion.new(65,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(66,"Sucre","Gran Mariscal"), ParejaRelacion.new(67,"Miranda","Precursor"), 
		ParejaRelacion.new(68,"19 de Abr","Independencia"), ParejaRelacion.new(69,"19 de Abr","Independencia"), 
		ParejaRelacion.new(70,"19 de Abr","Independencia"),ParejaRelacion.new(71,"19 de Abr","Independencia"),
		ParejaRelacion.new(72,"19 de Abr","Independencia")]}
	},
	4: {
		1: {"titulo": "Nivel 4 - Tema 1: Batallas", "parejas": [ParejaRelacion.new(73,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(74,"Sucre","Gran Mariscal"), ParejaRelacion.new(75,"Miranda","Precursor"), 
		ParejaRelacion.new(76,"19 de Abr","Independencia"), ParejaRelacion.new(77,"19 de Abr","Independencia"), 
		ParejaRelacion.new(78,"19 de Abr","Independencia"),ParejaRelacion.new(79,"19 de Abr","Independencia"),
		ParejaRelacion.new(80,"19 de Abr","Independencia")]},
		2: {"titulo": "Nivel 4 - Tema 2: Cultura", "parejas": [ParejaRelacion.new(81,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(82,"Sucre","Gran Mariscal"), ParejaRelacion.new(83,"Miranda","Precursor"), 
		ParejaRelacion.new(84,"19 de Abr","Independencia"), ParejaRelacion.new(85,"19 de Abr","Independencia"), 
		ParejaRelacion.new(86,"19 de Abr","Independencia"),ParejaRelacion.new(87,"19 de Abr","Independencia"),
		ParejaRelacion.new(88,"19 de Abr","Independencia")]},
		3: {"titulo": "Nivel 4 - Tema 3: Geografía", "parejas": [ParejaRelacion.new(89,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(90,"Sucre","Gran Mariscal"), ParejaRelacion.new(91,"Miranda","Precursor"), 
		ParejaRelacion.new(92,"19 de Abr","Independencia"), ParejaRelacion.new(93,"19 de Abr","Independencia"), 
		ParejaRelacion.new(94,"19 de Abr","Independencia"),ParejaRelacion.new(95,"19 de Abr","Independencia"),
		ParejaRelacion.new(96,"19 de Abr","Independencia")]}
	},
	5: {
		1: {"titulo": "Nivel 5 - Tema 1: Batallas", "parejas": [ParejaRelacion.new(97,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(98,"Sucre","Gran Mariscal"), ParejaRelacion.new(99,"Miranda","Precursor"), 
		ParejaRelacion.new(100,"19 de Abr","Independencia"), ParejaRelacion.new(101,"19 de Abr","Independencia"), 
		ParejaRelacion.new(102,"19 de Abr","Independencia"),ParejaRelacion.new(103,"19 de Abr","Independencia"),
		ParejaRelacion.new(104,"19 de Abr","Independencia")]},
		2: {"titulo": "Nivel 5 - Tema 2: Cultura", "parejas": [ParejaRelacion.new(105,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(106,"Sucre","Gran Mariscal"), ParejaRelacion.new(107,"Miranda","Precursor"), 
		ParejaRelacion.new(108,"19 de Abr","Independencia"), ParejaRelacion.new(109,"19 de Abr","Independencia"), 
		ParejaRelacion.new(110,"19 de Abr","Independencia"),ParejaRelacion.new(111,"19 de Abr","Independencia"),
		ParejaRelacion.new(112,"19 de Abr","Independencia")]},
		3: {"titulo": "Nivel 5 - Tema 3: Geografía", "parejas": [ParejaRelacion.new(113,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(114,"Sucre","Gran Mariscal"), ParejaRelacion.new(115,"Miranda","Precursor"), 
		ParejaRelacion.new(116,"19 de Abr","Independencia"), ParejaRelacion.new(117,"19 de Abr","Independencia"), 
		ParejaRelacion.new(118,"19 de Abr","Independencia"),ParejaRelacion.new(119,"19 de Abr","Independencia"),
		ParejaRelacion.new(120,"19 de Abr","Independencia")]}
	},
	6: {
		1: {"titulo": "Nivel 6 - Tema 1: Batallas", "parejas": [ParejaRelacion.new(121,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(122,"Sucre","Gran Mariscal"), ParejaRelacion.new(123,"Miranda","Precursor"), 
		ParejaRelacion.new(124,"19 de Abr","Independencia"), ParejaRelacion.new(125,"19 de Abr","Independencia"), 
		ParejaRelacion.new(126,"19 de Abr","Independencia"),ParejaRelacion.new(127,"19 de Abr","Independencia"),
		ParejaRelacion.new(128,"19 de Abr","Independencia")]},
		2: {"titulo": "Nivel 6 - Tema 2: Cultura", "parejas": [ParejaRelacion.new(129,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(130,"Sucre","Gran Mariscal"), ParejaRelacion.new(131,"Miranda","Precursor"), 
		ParejaRelacion.new(132,"19 de Abr","Independencia"), ParejaRelacion.new(133,"19 de Abr","Independencia"), 
		ParejaRelacion.new(134,"19 de Abr","Independencia"),ParejaRelacion.new(135,"19 de Abr","Independencia"),
		ParejaRelacion.new(136,"19 de Abr","Independencia")]},
		3: {"titulo": "Nivel 6 - Tema 3: Geografía", "parejas": [ParejaRelacion.new(137,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(138,"Sucre","Gran Mariscal"), ParejaRelacion.new(139,"Miranda","Precursor"), 
		ParejaRelacion.new(140,"19 de Abr","Independencia"), ParejaRelacion.new(141,"19 de Abr","Independencia"), 
		ParejaRelacion.new(142,"19 de Abr","Independencia"),ParejaRelacion.new(143,"19 de Abr","Independencia"),
		ParejaRelacion.new(144,"19 de Abr","Independencia")]}
	},
	7: {
		1: {"titulo": "Nivel 7 - Tema 1: Batallas", "parejas": [ParejaRelacion.new(145,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(146,"Sucre","Gran Mariscal"), ParejaRelacion.new(147,"Miranda","Precursor"), 
		ParejaRelacion.new(148,"19 de Abr","Independencia"), ParejaRelacion.new(149,"19 de Abr","Independencia"), 
		ParejaRelacion.new(150,"19 de Abr","Independencia"),ParejaRelacion.new(151,"19 de Abr","Independencia"),
		ParejaRelacion.new(152,"19 de Abr","Independencia")]},
		2: {"titulo": "Nivel 7 - Tema 2: Cultura", "parejas": [ParejaRelacion.new(153,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(154,"Sucre","Gran Mariscal"), ParejaRelacion.new(155,"Miranda","Precursor"), 
		ParejaRelacion.new(156,"19 de Abr","Independencia"), ParejaRelacion.new(157,"19 de Abr","Independencia"), 
		ParejaRelacion.new(158,"19 de Abr","Independencia"),ParejaRelacion.new(159,"19 de Abr","Independencia"),
		ParejaRelacion.new(160,"19 de Abr","Independencia")]},
		3: {"titulo": "Nivel 7 - Tema 3: Geografía", "parejas": [ParejaRelacion.new(161,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(162,"Sucre","Gran Mariscal"), ParejaRelacion.new(163,"Miranda","Precursor"), 
		ParejaRelacion.new(164,"19 de Abr","Independencia"), ParejaRelacion.new(165,"19 de Abr","Independencia"), 
		ParejaRelacion.new(166,"19 de Abr","Independencia"),ParejaRelacion.new(167,"19 de Abr","Independencia"),
		ParejaRelacion.new(168,"19 de Abr","Independencia")]}
	},
	8: {
		1: {"titulo": "Nivel 8 - Tema 1: Batallas", "parejas": [ParejaRelacion.new(169,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(170,"Sucre","Gran Mariscal"), ParejaRelacion.new(171,"Miranda","Precursor"), 
		ParejaRelacion.new(172,"19 de Abr","Independencia"), ParejaRelacion.new(173,"19 de Abr","Independencia"), 
		ParejaRelacion.new(174,"19 de Abr","Independencia"),ParejaRelacion.new(175,"19 de Abr","Independencia"),
		ParejaRelacion.new(176,"19 de Abr","Independencia")]},
		2: {"titulo": "Nivel 8 - Tema 2: Cultura", "parejas": [ParejaRelacion.new(177,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(178,"Sucre","Gran Mariscal"), ParejaRelacion.new(179,"Miranda","Precursor"), 
		ParejaRelacion.new(180,"19 de Abr","Independencia"), ParejaRelacion.new(181,"19 de Abr","Independencia"), 
		ParejaRelacion.new(182,"19 de Abr","Independencia"),ParejaRelacion.new(183,"19 de Abr","Independencia"),
		ParejaRelacion.new(184,"19 de Abr","Independencia")]},
		3: {"titulo": "Nivel 8 - Tema 3: Geografía", "parejas": [ParejaRelacion.new(185,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(186,"Sucre","Gran Mariscal"), ParejaRelacion.new(187,"Miranda","Precursor"), 
		ParejaRelacion.new(188,"19 de Abr","Independencia"), ParejaRelacion.new(189,"19 de Abr","Independencia"), 
		ParejaRelacion.new(190,"19 de Abr","Independencia"),ParejaRelacion.new(191,"19 de Abr","Independencia"),
		ParejaRelacion.new(192,"19 de Abr","Independencia")]}
	},
	9: {
		1: {"titulo": "Nivel 9 - Tema 1: Batallas", "parejas": [ParejaRelacion.new(193,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(194,"Sucre","Gran Mariscal"), ParejaRelacion.new(195,"Miranda","Precursor"), 
		ParejaRelacion.new(196,"19 de Abr","Independencia"), ParejaRelacion.new(197,"19 de Abr","Independencia"), 
		ParejaRelacion.new(198,"19 de Abr","Independencia"),ParejaRelacion.new(199,"19 de Abr","Independencia"),
		ParejaRelacion.new(200,"19 de Abr","Independencia")]},
		2: {"titulo": "Nivel 9 - Tema 2: Cultura", "parejas": [ParejaRelacion.new(201,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(202,"Sucre","Gran Mariscal"), ParejaRelacion.new(203,"Miranda","Precursor"), 
		ParejaRelacion.new(204,"19 de Abr","Independencia"), ParejaRelacion.new(205,"19 de Abr","Independencia"), 
		ParejaRelacion.new(206,"19 de Abr","Independencia"),ParejaRelacion.new(207,"19 de Abr","Independencia"),
		ParejaRelacion.new(208,"19 de Abr","Independencia")]},
		3: {"titulo": "Nivel 9 - Tema 3: Geografía", "parejas": [ParejaRelacion.new(209,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(210,"Sucre","Gran Mariscal"), ParejaRelacion.new(211,"Miranda","Precursor"), 
		ParejaRelacion.new(212,"19 de Abr","Independencia"), ParejaRelacion.new(213,"19 de Abr","Independencia"), 
		ParejaRelacion.new(214,"19 de Abr","Independencia"),ParejaRelacion.new(215,"19 de Abr","Independencia"),
		ParejaRelacion.new(216,"19 de Abr","Independencia")]}
	},
	10: {
		1: {"titulo": "Nivel 10 - Tema 1: Batallas", "parejas": [ParejaRelacion.new(217,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(218,"Sucre","Gran Mariscal"), ParejaRelacion.new(219,"Miranda","Precursor"), 
		ParejaRelacion.new(220,"19 de Abr","Independencia"), ParejaRelacion.new(221,"19 de Abr","Independencia"), 
		ParejaRelacion.new(222,"19 de Abr","Independencia"),ParejaRelacion.new(223,"19 de Abr","Independencia"),
		ParejaRelacion.new(224,"19 de Abr","Independencia")]},
		2: {"titulo": "Nivel 10 - Tema 2: Cultura", "parejas": [ParejaRelacion.new(225,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(226,"Sucre","Gran Mariscal"), ParejaRelacion.new(227,"Miranda","Precursor"), 
		ParejaRelacion.new(228,"19 de Abr","Independencia"), ParejaRelacion.new(229,"19 de Abr","Independencia"), 
		ParejaRelacion.new(230,"19 de Abr","Independencia"),ParejaRelacion.new(231,"19 de Abr","Independencia"),
		ParejaRelacion.new(232,"19 de Abr","Independencia")]},
		3: {"titulo": "Nivel 10 - Tema 3: Geografía", "parejas": [ParejaRelacion.new(233,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(234,"Sucre","Gran Mariscal"), ParejaRelacion.new(235,"Miranda","Precursor"), 
		ParejaRelacion.new(236,"19 de Abr","Independencia"), ParejaRelacion.new(237,"19 de Abr","Independencia"), 
		ParejaRelacion.new(238,"19 de Abr","Independencia"),ParejaRelacion.new(239,"19 de Abr","Independencia"),
		ParejaRelacion.new(240,"19 de Abr","Independencia")]}
	},
	11: { # Nivel comprado en tienda
		1: {"titulo": "Nivel 11 - Tema 1: Avanzado I", "parejas": [ParejaRelacion.new(241,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(242,"Sucre","Gran Mariscal"), ParejaRelacion.new(243,"Miranda","Precursor"), 
		ParejaRelacion.new(244,"19 de Abr","Independencia"), ParejaRelacion.new(245,"19 de Abr","Independencia"), 
		ParejaRelacion.new(246,"19 de Abr","Independencia"),ParejaRelacion.new(247,"19 de Abr","Independencia"),
		ParejaRelacion.new(248,"19 de Abr","Independencia")]},
		2: {"titulo": "Nivel 11 - Tema 2: Avanzado II", "parejas": [ParejaRelacion.new(249,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(250,"Sucre","Gran Mariscal"), ParejaRelacion.new(251,"Miranda","Precursor"), 
		ParejaRelacion.new(252,"19 de Abr","Independencia"), ParejaRelacion.new(253,"19 de Abr","Independencia"), 
		ParejaRelacion.new(254,"19 de Abr","Independencia"),ParejaRelacion.new(255,"19 de Abr","Independencia"),
		ParejaRelacion.new(256,"19 de Abr","Independencia")]},
		3: {"titulo": "Nivel 11 - Tema 3: Avanzado III", "parejas": [ParejaRelacion.new(257,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(258,"Sucre","Gran Mariscal"), ParejaRelacion.new(259,"Miranda","Precursor"), 
		ParejaRelacion.new(260,"19 de Abr","Independencia"), ParejaRelacion.new(261,"19 de Abr","Independencia"), 
		ParejaRelacion.new(262,"19 de Abr","Independencia"),ParejaRelacion.new(263,"19 de Abr","Independencia"),
		ParejaRelacion.new(264,"19 de Abr","Independencia")]}
	},
	12: { # Nivel comprado en tienda
		1: {"titulo": "Nivel 12 - Tema 1: Avanzado I", "parejas": [ParejaRelacion.new(265,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(266,"Sucre","Gran Mariscal"), ParejaRelacion.new(267,"Miranda","Precursor"), 
		ParejaRelacion.new(268,"19 de Abr","Independencia"), ParejaRelacion.new(269,"19 de Abr","Independencia"), 
		ParejaRelacion.new(270,"19 de Abr","Independencia"),ParejaRelacion.new(271,"19 de Abr","Independencia"),
		ParejaRelacion.new(272,"19 de Abr","Independencia")]},
		2: {"titulo": "Nivel 12 - Tema 2: Avanzado II", "parejas": [ParejaRelacion.new(273,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(274,"Sucre","Gran Mariscal"), ParejaRelacion.new(275,"Miranda","Precursor"), 
		ParejaRelacion.new(276,"19 de Abr","Independencia"), ParejaRelacion.new(277,"19 de Abr","Independencia"), 
		ParejaRelacion.new(278,"19 de Abr","Independencia"),ParejaRelacion.new(279,"19 de Abr","Independencia"),
		ParejaRelacion.new(280,"19 de Abr","Independencia")]},
		3: {"titulo": "Nivel 12 - Tema 3: Avanzado III", "parejas": [ParejaRelacion.new(281,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(282,"Sucre","Gran Mariscal"), ParejaRelacion.new(283,"Miranda","Precursor"), 
		ParejaRelacion.new(284,"19 de Abr","Independencia"), ParejaRelacion.new(285,"19 de Abr","Independencia"), 
		ParejaRelacion.new(286,"19 de Abr","Independencia"),ParejaRelacion.new(287,"19 de Abr","Independencia"),
		ParejaRelacion.new(288,"19 de Abr","Independencia")]}
	},
	13: { # Nivel comprado en tienda
		1: {"titulo": "Nivel 13 - Tema 1: Avanzado I", "parejas": [ParejaRelacion.new(289,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(290,"Sucre","Gran Mariscal"), ParejaRelacion.new(291,"Miranda","Precursor"), 
		ParejaRelacion.new(292,"19 de Abr","Independencia"), ParejaRelacion.new(293,"19 de Abr","Independencia"), 
		ParejaRelacion.new(294,"19 de Abr","Independencia"),ParejaRelacion.new(295,"19 de Abr","Independencia"),
		ParejaRelacion.new(296,"19 de Abr","Independencia")]},
		2: {"titulo": "Nivel 13 - Tema 2: Avanzado II", "parejas": [ParejaRelacion.new(297,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(298,"Sucre","Gran Mariscal"), ParejaRelacion.new(299,"Miranda","Precursor"), 
		ParejaRelacion.new(300,"19 de Abr","Independencia"), ParejaRelacion.new(301,"19 de Abr","Independencia"), 
		ParejaRelacion.new(302,"19 de Abr","Independencia"),ParejaRelacion.new(303,"19 de Abr","Independencia"),
		ParejaRelacion.new(304,"19 de Abr","Independencia")]},
		3: {"titulo": "Nivel 13 - Tema 3: Avanzado III", "parejas": [ParejaRelacion.new(305,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(306,"Sucre","Gran Mariscal"), ParejaRelacion.new(307,"Miranda","Precursor"), 
		ParejaRelacion.new(308,"19 de Abr","Independencia"), ParejaRelacion.new(309,"19 de Abr","Independencia"), 
		ParejaRelacion.new(310,"19 de Abr","Independencia"),ParejaRelacion.new(311,"19 de Abr","Independencia"),
		ParejaRelacion.new(312,"19 de Abr","Independencia")]}
	},
	14: { # Nivel comprado en tienda
		1: {"titulo": "Nivel 14 - Tema 1: Avanzado I", "parejas": [ParejaRelacion.new(313,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(314,"Sucre","Gran Mariscal"), ParejaRelacion.new(315,"Miranda","Precursor"), 
		ParejaRelacion.new(316,"19 de Abr","Independencia"), ParejaRelacion.new(317,"19 de Abr","Independencia"), 
		ParejaRelacion.new(318,"19 de Abr","Independencia"),ParejaRelacion.new(319,"19 de Abr","Independencia"),
		ParejaRelacion.new(320,"19 de Abr","Independencia")]},
		2: {"titulo": "Nivel 14 - Tema 2: Avanzado II", "parejas": [ParejaRelacion.new(321,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(322,"Sucre","Gran Mariscal"), ParejaRelacion.new(323,"Miranda","Precursor"), 
		ParejaRelacion.new(324,"19 de Abr","Independencia"), ParejaRelacion.new(325,"19 de Abr","Independencia"), 
		ParejaRelacion.new(326,"19 de Abr","Independencia"),ParejaRelacion.new(327,"19 de Abr","Independencia"),
		ParejaRelacion.new(328,"19 de Abr","Independencia")]},
		3: {"titulo": "Nivel 14 - Tema 3: Avanzado III", "parejas": [ParejaRelacion.new(329,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(330,"Sucre","Gran Mariscal"), ParejaRelacion.new(331,"Miranda","Precursor"), 
		ParejaRelacion.new(332,"19 de Abr","Independencia"), ParejaRelacion.new(333,"19 de Abr","Independencia"), 
		ParejaRelacion.new(334,"19 de Abr","Independencia"),ParejaRelacion.new(335,"19 de Abr","Independencia"),
		ParejaRelacion.new(336,"19 de Abr","Independencia")]}
	},
	15: { # Nivel comprado en tienda
		1: {"titulo": "Nivel 15 - Tema 1: Avanzado I", "parejas": [ParejaRelacion.new(337,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(338,"Sucre","Gran Mariscal"), ParejaRelacion.new(339,"Miranda","Precursor"), 
		ParejaRelacion.new(340,"19 de Abr","Independencia"), ParejaRelacion.new(341,"19 de Abr","Independencia"), 
		ParejaRelacion.new(342,"19 de Abr","Independencia"),ParejaRelacion.new(343,"19 de Abr","Independencia"),
		ParejaRelacion.new(344,"19 de Abr","Independencia")]},
		2: {"titulo": "Nivel 15 - Tema 2: Avanzado II", "parejas": [ParejaRelacion.new(345,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(346,"Sucre","Gran Mariscal"), ParejaRelacion.new(347,"Miranda","Precursor"), 
		ParejaRelacion.new(348,"19 de Abr","Independencia"), ParejaRelacion.new(349,"19 de Abr","Independencia"), 
		ParejaRelacion.new(350,"19 de Abr","Independencia"),ParejaRelacion.new(351,"19 de Abr","Independencia"),
		ParejaRelacion.new(352,"19 de Abr","Independencia")]},
		3: {"titulo": "Nivel 15 - Tema 3: Avanzado III", "parejas": [ParejaRelacion.new(353,"Simón Bolívar","El Libertador"), 
		ParejaRelacion.new(354,"Sucre","Gran Mariscal"), ParejaRelacion.new(355,"Miranda","Precursor"), 
		ParejaRelacion.new(356,"19 de Abr","Independencia"), ParejaRelacion.new(357,"19 de Abr","Independencia"), 
		ParejaRelacion.new(358,"19 de Abr","Independencia"),ParejaRelacion.new(359,"19 de Abr","Independencia"),
		ParejaRelacion.new(360,"19 de Abr","Independencia")]}
	}
	}

# --- CONTROL DE NODOS DE INTERFAZ ---
@onready var label_tematica: Label = $Control/Label
@onready var col_izquierda: VBoxContainer = $Control/Panel/HBoxContainer/VBoxContainer
@onready var col_derecha: VBoxContainer = $Control/Panel/HBoxContainer/VBoxContainer2
@onready var nodo_lineas: Node2D = $Node2D
@onready var menu_pausa = $Menupausa
@onready var capa_confirmacion = $confrimar
@onready var label_timer = get_node_or_null("Label2")

# Personaje Presentador
@onready var sprite_personaje = $capapersonaje/SpritePersonaje
@onready var panel_dialogo = $capapersonaje/PanelContainer
@onready var label_dialogo = $capapersonaje/PanelContainer/MarginContainer/Label

# Pantalla de Resultados
@onready var pantalla_resultados = $PantallaResultados
@onready var label_titulo_resultados = $PantallaResultados/Panel/Label
@onready var label_puntaje_total = $PantallaResultados/Panel/Label2
@onready var contenedor_estrellas = $PantallaResultados/Panel/HBoxContainer
@onready var btn_siguiente = $PantallaResultados/Panel/HBoxContainer2/Button     
@onready var btn_repetir = $PantallaResultados/Panel/HBoxContainer2/Button3    
@onready var btn_selector = $PantallaResultados/Panel/HBoxContainer2/Button4  
@onready var btn_menu_alumno = $PantallaResultados/Panel/HBoxContainer2/Button2

# Recursos Visuales 
var pose_normal = preload("res://GFX/normal.png")
var pose_feliz = preload("res://GFX/Feliz.png")
var pose_preocupado = preload("res://GFX/preocupado.png")
var pose_pensativo = preload("res://GFX/pensativo.png")
var img_estrella_llena = preload("res://GFX/estrella completada.png")
var img_estrella_vacia = preload("res://GFX/estrella vacia.png")

# Variables del Motor de Juego
var SQLiteHelper = load("res://Scripts/sqlite_helper.gd")
var db: SQLite
var numero_de_nivel: int = 1
var tema_actual_id: int = 1
var conexiones_correctas_fase: int = 0
var total_parejas_fase: int = 0
var total_conexiones_acertadas_nivel: int = 0
var total_conexiones_requeridas_nivel: int = 0

# Variables del Cronómetro
var tiempo_maximo_nivel: float = 480.0
var tiempo_restante: float = 480.0
var juego_activo: bool = false

# Arrastre de Línea
var boton_seleccionado_izq: Button = null
var mouse_posicion_actual: Vector2 = Vector2.ZERO
var arrastrando_linea: bool = false
var conexiones_establecidas: Dictionary = {}

func _ready() -> void:
	if menu_pausa: 
		menu_pausa.process_mode = Node.PROCESS_MODE_ALWAYS
		if capa_confirmacion:
			capa_confirmacion.process_mode = Node.PROCESS_MODE_ALWAYS
	
	db = SQLiteHelper.open_db_connection()
	_cargar_banco_columnas_desde_archivo()
	_cargar_usuario_actual()
	numero_de_nivel = maxi(1, int(GlobalUsuario.nivel_seleccionado))
	
	 # --- VALIDACIÓN DE BLOQUEO DE TIENDA (NIVELES 11-15) ---
	if numero_de_nivel >= 11:
		if not _verificar_nivel_desbloqueado_en_tienda(numero_de_nivel):
			_bloquear_por_no_comprado()
			return
			
	_inicializar_entorno()

func _cargar_banco_columnas_desde_archivo() -> void:
	if not FileAccess.file_exists(RUTA_DATOS_COLUMNAS):
		return
	var archivo := FileAccess.open(RUTA_DATOS_COLUMNAS, FileAccess.READ)
	if archivo == null:
		return
	var parsed: Variant = JSON.parse_string(archivo.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return

	var banco_convertido: Dictionary = {}
	for nivel_key in parsed.keys():
		var nivel := int(str(nivel_key))
		if nivel <= 0:
			continue
		var temas_raw: Variant = parsed[nivel_key]
		if typeof(temas_raw) != TYPE_DICTIONARY:
			continue
		var temas_dict: Dictionary = temas_raw

		var temas_convertidos: Dictionary = {}
		for tema_key in temas_dict.keys():
			var tema := int(str(tema_key))
			if tema <= 0:
				continue
			var data_tema_raw: Variant = temas_dict[tema_key]
			if typeof(data_tema_raw) != TYPE_DICTIONARY:
				continue
			var data_tema: Dictionary = data_tema_raw

			var titulo := str(data_tema.get("titulo", "Nivel %d - Tema %d" % [nivel, tema]))
			var filas: Array = data_tema.get("parejas", [])
			if typeof(filas) != TYPE_ARRAY:
				continue

			var parejas: Array[ParejaRelacion] = []
			var id_base := (nivel * 100) + (tema * 10)
			var index := 0
			for fila in filas:
				if typeof(fila) != TYPE_DICTIONARY:
					continue
				var texto_izq := str(fila.get("izq", "")).strip_edges()
				var texto_der := str(fila.get("der", "")).strip_edges()
				if texto_izq.is_empty() or texto_der.is_empty():
					continue
				parejas.append(ParejaRelacion.new(id_base + index, texto_izq, texto_der))
				index += 1

			if not parejas.is_empty():
				temas_convertidos[tema] = {"titulo": titulo, "parejas": parejas}

		if not temas_convertidos.is_empty():
			banco_convertido[nivel] = temas_convertidos

	if not banco_convertido.is_empty():
		BANCO_NIVELES_GLOBAL = banco_convertido

func _inicializar_entorno() -> void:
	tiempo_maximo_nivel = TIEMPOS_POR_NIVEL.get(numero_de_nivel, 480.0)
	tiempo_restante = tiempo_maximo_nivel
	tema_actual_id = 1
	total_conexiones_acertadas_nivel = 0
	
	# Calcular la cantidad total de aciertos requeridos sumando los 3 temas
	total_conexiones_requeridas_nivel = 0
	var sub_banco = BANCO_NIVELES_GLOBAL.get(numero_de_nivel, {})
	for f in [1, 2, 3]:
		if sub_banco.has(f):
			total_conexiones_requeridas_nivel += sub_banco[f]["parejas"].size()
			
	if pantalla_resultados: pantalla_resultados.hide()
	if menu_pausa: menu_pausa.hide()
	_conectar_botones_seguros()
	_ocultar_ui_juego()
	
	# Asegurar que el cuadro de diálogo y sus componentes internos estén listos
	if panel_dialogo:
		panel_dialogo.show()
	if label_dialogo and label_dialogo.get_parent():
		label_dialogo.get_parent().show()
	
	# Presentación del Personaje
	cambiar_pose(pose_normal)
	await decir_mensaje("¡Bienvenido al Nivel %d de Relacionar Columnas!" % numero_de_nivel, 2.5)
	
	cambiar_pose(pose_pensativo)
	var min_texto := int(tiempo_maximo_nivel) / 60
	await decir_mensaje("Tienes un límite de %d minutos para completar las 3 categorías. ¡Éxito!" % min_texto, 3.0)
	
	# 🌟 CORRECCIÓN: Ocultamos el panel de diálogo completo de forma segura
	if panel_dialogo: 
		panel_dialogo.hide()
		
	# Activación del entorno de juego
	_mostrar_ui_juego()
	cargar_fase_del_tema(tema_actual_id)
	juego_activo = true

func _process(delta: float) -> void:
	if juego_activo:
		tiempo_restante -= delta
		_actualizar_cronometro_visual()
		if tiempo_restante <= 0:
			tiempo_restante = 0
			finalizar_nivel(false)
			
	if arrastrando_linea:
		mouse_posicion_actual = get_global_mouse_position()
		if nodo_lineas: nodo_lineas.queue_redraw()

func cargar_fase_del_tema(id_tema: int) -> void:
	conexiones_correctas_fase = 0
	conexiones_establecidas.clear()
	boton_seleccionado_izq = null
	arrastrando_linea = false
	
	var sub_banco = BANCO_NIVELES_GLOBAL.get(numero_de_nivel, {})
	if not sub_banco.has(id_tema):
		finalizar_nivel(true)
		return
		
	var datos_tema: Dictionary = sub_banco[id_tema]
	label_tematica.text = datos_tema["titulo"]
	total_parejas_fase = datos_tema["parejas"].size()
	
	for hijo in col_izquierda.get_children(): hijo.queue_free()
	for hijo in col_derecha.get_children(): hijo.queue_free()
	
	var lista_izq = datos_tema["parejas"].duplicate()
	var lista_der = datos_tema["parejas"].duplicate()
	lista_izq.shuffle()
	lista_der.shuffle()
	
	for pareja in lista_izq:
		var btn = Button.new()
		btn.text = pareja.texto_izq
		btn.custom_minimum_size = Vector2(240, 50)
		btn.set_meta("id_relacion", pareja.id)
		btn.set_meta("columna", "IZQ")
		btn.pressed.connect(_on_boton_columna_pressed.bind(btn))
		col_izquierda.add_child(btn)
		
	for pareja in lista_der:
		var btn = Button.new()
		btn.text = pareja.texto_der
		btn.custom_minimum_size = Vector2(240, 50)
		btn.set_meta("id_relacion", pareja.id)
		btn.set_meta("columna", "DER")
		btn.pressed.connect(_on_boton_columna_pressed.bind(btn))
		col_derecha.add_child(btn)
	
	if nodo_lineas: nodo_lineas.queue_redraw()

func _on_boton_columna_pressed(btn: Button) -> void:
	if not juego_activo: return
	var columna = btn.get_meta("columna")
	
	if columna == "IZQ":
		if btn.disabled: return
		if boton_seleccionado_izq: boton_seleccionado_izq.modulate = Color.WHITE
		boton_seleccionado_izq = btn
		boton_seleccionado_izq.modulate = Color.ORANGE
		arrastrando_linea = true
	
	elif columna == "DER" and arrastrando_linea:
		if btn.disabled: return
		var id_izq = boton_seleccionado_izq.get_meta("id_relacion")
		var id_der = btn.get_meta("id_relacion")
		
		if id_izq == id_der:
			# --- CONEXIÓN EXCELENTE ---
			boton_seleccionado_izq.modulate = Color.GREEN
			btn.modulate = Color.GREEN
			boton_seleccionado_izq.disabled = true
			btn.disabled = true
			
			conexiones_establecidas[boton_seleccionado_izq] = btn
			conexiones_correctas_fase += 1
			total_conexiones_acertadas_nivel += 1
			
			arrastrando_linea = false
			boton_seleccionado_izq = null
			if nodo_lineas: nodo_lineas.queue_redraw()
			
			# Reacción interactiva hablada
			cambiar_pose(pose_feliz)
			var frases = ["¡Excelente emparejamiento!", "¡Muy bien analizado!", "¡Correcto! Sabía que podías."]
			
			# 🌟 SOLUCIÓN: Agregamos 'await' para que el juego espere a que termine el mensaje
			await decir_mensaje(frases.pick_random(), 1.5)
			if conexiones_correctas_fase == total_parejas_fase:
				ir_al_siguiente_tema()
		else:
					 # --- ERROR ---
				arrastrando_linea = false 
				if nodo_lineas: nodo_lineas.queue_redraw()
				
				boton_seleccionado_izq.modulate = Color.RED
				btn.modulate = Color.RED
				cambiar_pose(pose_preocupado)
				
				var copia_izq = boton_seleccionado_izq
				var copia_der = btn
				boton_seleccionado_izq = null
				
				# 🌟 SOLUCIÓN: Agregamos 'await' aquí también para pausar el flujo del error
				await decir_mensaje("Mmm... esa relación no es correcta.", 1.5)
				if is_instance_valid(copia_izq) and not copia_izq.disabled: copia_izq.modulate = Color.WHITE
				if is_instance_valid(copia_der) and not copia_der.disabled: copia_der.modulate = Color.WHITE

func ir_al_siguiente_tema() -> void:
	await get_tree().create_timer(1.2).timeout
	tema_actual_id += 1
	cargar_fase_del_tema(tema_actual_id)

# --- ADAPTACIÓN DE LA REGLA DE ESTRELLAS SOLICITADA ---
func finalizar_nivel(completado_exitosamente: bool) -> void:
	juego_activo = false
	_ocultar_ui_juego()
	
	var tiempo_empleado = tiempo_maximo_nivel - tiempo_restante
	var estrellas_obtenidas := 0
	var mensaje_final := ""
	
	if completado_exitosamente:
		# Escala temporal solicitada:
		if tiempo_empleado < 180.0: # Menos de 3 min
			estrellas_obtenidas = 3
			cambiar_pose(pose_feliz)
			mensaje_final = "¡Impresionante velocidad! Lograste las 3 estrellas perfectas."
		elif tiempo_empleado <= 330.0: # Menos de 5:30 min
			estrellas_obtenidas = 2
			cambiar_pose(pose_normal)
			mensaje_final = "¡Muy buen trabajo! Conseguiste 2 estrellas."
		else: # Después de 5:30 y antes de 8 min
			estrellas_obtenidas = 1
			cambiar_pose(pose_pensativo)
			mensaje_final = "¡Completado! Te otorgamos 1 estrella. ¡Intenta ser más rápido la próxima!"
	else:
		estrellas_obtenidas = 0
		cambiar_pose(pose_preocupado)
		mensaje_final = "¡El tiempo expiró! Debes repetir el nivel para ganar estrellas."
		
	await decir_mensaje(mensaje_final, 3.5)
	
	var puntos_totales = total_conexiones_acertadas_nivel * RECOMPENSA_BASE_PUNTOS
	var monedas_ganadas = estrellas_obtenidas * MONEDAS_POR_ESTRELLA
	
	_guardar_progreso_db(puntos_totales, estrellas_obtenidas)
	_mostrar_pantalla_resultados_visual(puntos_totales, monedas_ganadas, estrellas_obtenidas)

func _mostrar_pantalla_resultados_visual(pts: int, mon: int, estrellas: int) -> void:
	if not pantalla_resultados: return
	label_titulo_resultados.text = "NIVEL %d" % numero_de_nivel
	label_puntaje_total.text = "Puntaje: %d | Monedas: +%d" % [pts, mon]
	
	var astros = contenedor_estrellas.get_children()
	for i in range(astros.size()):
		astros[i].texture = img_estrella_llena if i < estrellas else img_estrella_vacia
		
	if estrellas == 0:
		if btn_siguiente: btn_siguiente.hide() # Repetición forzada obligatoria
	else:
		if btn_siguiente:
			btn_siguiente.visible = BANCO_NIVELES_GLOBAL.has(numero_de_nivel + 1)
			
	pantalla_resultados.show()

# --- VALIDACIONES COMPLEMENTARIAS ---
func _verificar_nivel_desbloqueado_en_tienda(lvl: int) -> bool:
	return SQLiteHelper.nivel_comprado(db, GlobalUsuario.usuario_actual_id, "columnas", lvl)

func _bloquear_por_no_comprado() -> void:
	juego_activo = false
	_ocultar_ui_juego()
	cambiar_pose(pose_preocupado)
	await decir_mensaje("Este nivel pertenece a los desafíos especiales. ¡Debes adquirirlo en la Tienda!", 4.0)
	_on_btn_selector_pressed()

func _actualizar_cronometro_visual() -> void:
	if label_timer:
		var mins := int(tiempo_restante) / 60
		var segs := int(tiempo_restante) % 60
		label_timer.text = "%02d:%02d" % [mins, segs]

func decir_mensaje(texto: String, tiempo: float) -> void:
	if not label_dialogo: return
	
	label_dialogo.text = texto
	
	# Aseguramos que el contenedor interno (MarginContainer) esté visible
	if label_dialogo.get_parent() and label_dialogo.get_parent() is Control:
		label_dialogo.get_parent().show()
		
	if panel_dialogo:
		panel_dialogo.show()
		panel_dialogo.modulate.a = 1.0
	
	# Creamos un temporizador seguro usando el árbol de escenas actual
	var timer = get_tree().create_timer(tiempo)
	await timer.timeout
	
	# Ocultamos el panel al finalizar el tiempo asignado
	if panel_dialogo: 
		panel_dialogo.hide()

func cambiar_pose(textura: Texture2D) -> void:
	if sprite_personaje: sprite_personaje.texture = textura

func _ocultar_ui_juego() -> void:
	$Control/Panel.hide()
	$Control/Panel/HBoxContainer.hide()
	label_tematica.hide()
	if label_timer: label_timer.hide()

func _mostrar_ui_juego() -> void:
	$Control/Panel.show()
	$Control/Panel/HBoxContainer.show()
	label_tematica.show()
	if label_timer: label_timer.show()

func _conectar_botones_seguros() -> void:
	if btn_siguiente and not btn_siguiente.pressed.is_connected(_on_btn_siguiente_pressed): btn_siguiente.pressed.connect(_on_btn_siguiente_pressed)
	if btn_repetir and not btn_repetir.pressed.is_connected(_on_btn_repetir_pressed): btn_repetir.pressed.connect(_on_btn_repetir_pressed)
	if btn_selector and not btn_selector.pressed.is_connected(_on_btn_selector_pressed): btn_selector.pressed.connect(_on_btn_selector_pressed)
	if btn_menu_alumno and not btn_menu_alumno.pressed.is_connected(_on_btn_menu_pressed): btn_menu_alumno.pressed.connect(_on_btn_menu_pressed)
	
	var boton_pausa_visual = get_node_or_null("Buttonpausa") 
	if boton_pausa_visual and boton_pausa_visual is Button:
		if not boton_pausa_visual.pressed.is_connected(_on_boton_pausa_visual_pressed):
			boton_pausa_visual.pressed.connect(_on_boton_pausa_visual_pressed)

func _guardar_progreso_db(pts: int, estrellas: int) -> void:
	if estrellas == 0 or db == null: return
	var id_user = GlobalUsuario.usuario_actual_id
	var usr_name = SQLiteHelper.escape(GlobalUsuario.nombre_alumno)
	var time_str = Time.get_datetime_string_from_system().replace("T", " ")
	
	var completado_col := 1 if estrellas == 3 else 0
	db.query("INSERT INTO columnas_intentos (NU_USU, NM_ALUMNO, NU_NIVEL, NU_PUNTOS, NU_ESTRELLAS, SW_COM, FE_INTENTO) VALUES (%d, '%s', %d, %d, %d, %d, '%s');" % [id_user, usr_name, numero_de_nivel, pts, estrellas, completado_col, time_str])
	
	db.query("SELECT NU_ESTRELLAS FROM columnas_niveles WHERE NU_USU = %d AND NU_NIVEL = %d;" % [id_user, numero_de_nivel])
	if db.query_result.is_empty():
		db.query("INSERT INTO columnas_niveles (NU_NIVEL, NU_USU, NM_ALUMNO, NU_PUNTOS, NU_ESTRELLAS, SW_COM) VALUES (%d, %d, '%s', %d, %d, %d);" % [numero_de_nivel, id_user, usr_name, pts, estrellas, completado_col])
	else:
		var previas := int(db.query_result[0].get("NU_ESTRELLAS", 0))
		if estrellas > previas:
			db.query("UPDATE columnas_niveles SET NU_PUNTOS = %d, NU_ESTRELLAS = %d, SW_COM = %d WHERE NU_NIVEL = %d AND NU_USU = %d;" % [pts, estrellas, completado_col, numero_de_nivel, id_user])
			
	var prox := numero_de_nivel + 1
	db.query("UPDATE Alumnos SET NU_NIVEL_MAX_COLUMNAS = %d WHERE NU_USU = %d AND NU_NIVEL_MAX_COLUMNAS < %d;" % [prox, id_user, prox])

	SQLiteHelper.mirror_minijuegos_resultados(db, id_user, GlobalUsuario.nombre_alumno, "columnas", pts, estrellas)

	db.query("SELECT NU_DINERO FROM Alumnos WHERE NU_USU = %d;" % id_user)
	var dinero_total := 0
	if not db.query_result.is_empty():
		dinero_total = int(db.query_result[0].get("NU_DINERO", 0))
	Logros.evaluar_post_nivel(estrellas, pts, dinero_total)

func _cargar_usuario_actual() -> void:
	if GlobalUsuario.usuario_actual_id > 0:
		db.query("SELECT NU_USU, NM_ALUMNO FROM Alumnos WHERE NU_USU = %d;" % GlobalUsuario.usuario_actual_id)
		if not db.query_result.is_empty():
			GlobalUsuario.nombre_alumno = str(db.query_result[0].get("NM_ALUMNO"))

func _on_btn_siguiente_pressed() -> void:
	GlobalUsuario.nivel_seleccionado = numero_de_nivel + 1
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_btn_repetir_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_btn_selector_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(RUTA_ESCENA_SELECCION)

func _on_btn_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scenes/menu-alumno.tscn")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if arrastrando_linea:
			arrastrando_linea = false
			if boton_seleccionado_izq: boton_seleccionado_izq.modulate = Color.WHITE
			boton_seleccionado_izq = null
			if nodo_lineas: nodo_lineas.queue_redraw()
		
	if event.is_action_pressed("ui_cancel") and not capa_confirmacion.visible:
		gestionar_pausa()

func _exit_tree() -> void:
	if db: SQLiteHelper.close_db_connection(db)

func _on_boton_pausa_visual_pressed():
	# El botón visual hace lo mismo que la tecla ESC
	gestionar_pausa()

func gestionar_pausa():
	var nuevo_estado_pausa = !get_tree().paused # Invierte el estado actual del motor
	get_tree().paused = nuevo_estado_pausa
	
	if menu_pausa:
		menu_pausa.visible = nuevo_estado_pausa
		
	# Si quitamos la pausa (regresamos al juego), nos aseguramos de limpiar las ventanas emergentes
	if not nuevo_estado_pausa:
		if capa_confirmacion:
			capa_confirmacion.hide()

# --- BOTONES DEL MENÚ ---

func _on_continuar_pressed():
	gestionar_pausa()
	get_tree().paused = false

const ESCENA_OPCIONES = preload("res://Opcionesnivel.tscn")

func _on_opciones_pressed():
	# 1. Ocultamos momentáneamente los botones del menú de pausa principal
	$Menupausa/CenterContainer.visible = false
	# 2. Creamos una instancia de la escena de opciones
	var opciones_instancia = ESCENA_OPCIONES.instantiate()
	# 3. Le asignamos un nombre único
	opciones_instancia.name = "MenuOpcionesDinamico"
	
	# ¡IMPORTANTE!: Forzar a la nueva ventana de opciones a procesar en pausa
	opciones_instancia.process_mode = Node.PROCESS_MODE_ALWAYS
	# 4. La añadimos como hija del CanvasLayer de pausa
	$Menupausa.add_child(opciones_instancia)


func _on_salir_pressed():
	# Mostrar el cuadro de confirmación antes de salir
	capa_confirmacion.show()
	
func _on_confirmar_no_quedarme_pressed():
	capa_confirmacion.hide()

# --- LÓGICA DEL MENÚ DE PAUSA ---

func _on_boton_salir_pressed():
	# Al darle a "Salir" en el primer menú, ocultamos la pausa y mostramos confirmación
	menu_pausa.hide()
	capa_confirmacion.show()

# --- LÓGICA DE LA CAPA DE CONFIRMACIÓN ---

func _on_boton_si_confirmar_salir_pressed():
	get_tree().paused = false
	GlobalUsuario.nivel_seleccionado = numero_de_nivel
	get_tree().change_scene_to_file("res://Scenes/Minijuegos.tscn")

func _on_boton_no_cancelar_pressed():
	# Si se arrepiente, cerramos la confirmación y VOLVEMOS al menú de pausa
	capa_confirmacion.hide()
	menu_pausa.show()
