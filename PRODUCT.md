# Product

## Register

product

## Users

Ciudadanos de Cochabamba, Bolivia (datos mock centrados en Zona Norte/Centro) que reportan y consultan incidentes de seguridad ciudadana: robos, accidentes, personas sospechosas, incendios, emergencias médicas, vandalismo. Contexto de uso: en la calle, con el teléfono a una mano, a menudo bajo estrés o con prisa; también consultas rápidas para conocer el estado de su zona.

## Product Purpose

Arconte es una plataforma de reporte de seguridad ciudadana ("Tu comunidad, tu seguridad"). Permite reportar incidentes con ubicación y evidencia, ver incidentes cercanos en un mapa en vivo, hacer seguimiento del estado de los reportes (recibido → en revisión → atendido) y recibir notificaciones. El éxito es que un ciudadano pueda reportar en segundos y entender la situación de su zona de un vistazo.

## Brand Personality

Confiable, serena, cívica. La interfaz debe transmitir autoridad tranquila (es una app de seguridad, no de entretenimiento): tema oscuro sobrio, estados semánticos claramente codificados por color (urgente/moderado/resuelto), nada de decoración gratuita. Personalidad en 3 palabras: vigilante, clara, cercana.

## Anti-references

- No parecer un juguete ni un dashboard SaaS genérico de admin.
- No gamificación ni colores festivos; la urgencia se comunica con el rojo semántico, no con ruido visual.
- No imitar literalmente a Google Maps/Apple Maps en su paleta clara: el mapa es oscuro y propio, pero sus affordances (controles de zoom, ubicación, bottom sheet) sí siguen convenciones conocidas.
- Evitar glassmorphism decorativo y gradientes de texto.

## Design Principles

1. El mapa es el protagonista: todo overlay flota sobre él con el mínimo cromado posible.
2. El color es información: rojo/ámbar/verde solo para estados de incidente; azul primario solo para acciones y ubicación propia.
3. Affordances estándar de mapa: controles de zoom, botón de mi ubicación, bottom sheet arrastrable. Nada de gestos inventados.
4. Denso pero respirable: la información crítica (estado, tipo, tiempo) visible sin abrir el detalle.
5. Movimiento que comunica: pulso solo en incidentes urgentes; transiciones de 150–250 ms en controles.

## Accessibility & Inclusion

- Contraste de texto ≥ 4.5:1 sobre el tema oscuro (grises del rampa actual ya lo cumplen; verificar placeholders).
- Los estados no se comunican solo con color: cada marcador/badge lleva icono de tipo y las tarjetas llevan etiqueta de texto del estado.
- Soportar reduced-motion: los pulsos de marcadores urgentes deben poder desactivarse.
