# Arconte

**Plataforma de reportes ciudadanos de seguridad** — Flutter frontend (100% mock, sin backend).

## Arquitectura

```
lib/
├── main.dart                    # Splash → Onboarding → App
├── app/
│   ├── app.dart                 # MaterialApp.router + tema oscuro
│   ├── routes/app_router.dart   # GoRouter (home, map, incident, report, notifications, profile)
│   └── theme/                   # Material 3 dark theme (colores, tipografía, spacing)
├── core/
│   ├── constants/               # Constantes globales
│   ├── extensions/              # Context & Widget extensions
│   ├── utils/formatters.dart    # Formateo fecha/distancia
│   └── animations/              # Utilidades de animación
├── shared/
│   ├── widgets/basic_widgets.dart  # AppCard, AppButton, AppFAB, AppAvatar, etc.
│   ├── components/              # IncidentCard, ReportCard, NotificationCard
│   ├── dialogs/                 # Confirmación, éxito, error, loading
│   └── bottom_sheets/           # DraggableScrollableSheet reutilizable
├── mock/
│   ├── models.dart              # Incident, Report, User, Notification, TimelineEvent
│   └── mock_data.dart           # 8 incidentes, 3 reportes, 7 notificaciones, 1 usuario
└── features/
    ├── home/                    # Mapa + bottom sheet arrastrable
    ├── map/                     # Mapa full-screen con marcadores animados
    ├── incident_detail/         # Detalle + timeline (Recibido → En revisión → Atendido)
    ├── reports/                 # Wizard 4 pasos: Categoría → Ubicación → Evidencia → Revisión
    ├── notifications/           # Lista con swipe-to-dismiss, estados leído/no leído
    └── profile/                 # Avatar, stats, menú ajustes, logout (mock)
```

## Flujo principal

```
Splash (2.5s) → Onboarding (4 páginas) → Home/Mapa
  → Tocar marcador/tarjeta → Detalle incidente
  → FAB "Reportar" → Reporte por voz con IA (Gemini Live) → Confirmación → Ver seguimiento
    → alternativa: "Reportar manualmente" → Wizard 4 pasos → Confirmación → Ver seguimiento
  → Bottom nav: Mis reportes / Notificaciones / Perfil
```

## Características clave

- **Tema oscuro premium** con paleta: `#060A14` (bg), `#4E8CFF` (primary), `#FF5A38` (urgent), `#FFB13C` (moderate), `#33D9AE` (resolved)
- **Marcadores animados** (pulse para urgentes, scale al tocar)
- **Bottom sheet arrastrable** (DraggableScrollableSheet con snap points)
- **Wizard de reporte** con step indicator animado, selección de categoría en grid, mapa preview, picker de imágenes, revisión final
- **Hero transitions** en detalle de incidente y evidencia
- **Animaciones**: fade, slide, scale, elasticOut, stagger
- **100% mock data** — listo para conectar API (FastAPI/Supabase) después

## Ejecutar

```bash
flutter pub get
flutter run
# o
flutter build apk --debug
```

### Reporte por voz (Gemini Live)

El botón "Reportar" abre una conversación de voz en tiempo real con un agente
Gemini que arma el reporte por vos (`AiReportPage`). La API key real de
Gemini vive únicamente en el backend (`sos-24-gamc`, variable de entorno
`GEMINI_API_KEY`) — la app nunca la recibe ni la guarda: antes de conectar,
pide al backend un token efímero de un solo uso (`/api/citizen/gemini/live-token`,
requiere sesión de ciudadano) y se conecta a Gemini Live con ese token.

Si el backend no tiene `GEMINI_API_KEY` configurada, o el ciudadano no tiene
sesión iniciada, la pantalla de voz muestra un aviso de error con un enlace
al wizard manual (`CreateReportPage`), que sigue disponible sin depender de
la voz.

## Dependencias principales

- `go_router` — navegación declarativa
- `flutter_animate` — animaciones declarativas
- `google_maps_flutter` — mapa (mock visual)
- `image_picker` — selección de evidencia
- `intl` — formateo de fechas
- `flutter_sound` — captura/reproducción de audio PCM crudo para el reporte por voz
- `web_socket_channel` — transporte WebSocket hacia la Gemini Live API