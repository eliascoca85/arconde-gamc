# 📘 Documentación Oficial del Sistema SOS-24 GAMC
> **Sistema Integral de Gestión y Monitoreo de Emergencias Ciudadanas 24/7 con Inteligencia Artificial**

---

## 🔑 1. Credenciales de Acceso para Pruebas

### 🖥️ Dashboard Central GAMC e Institucional
**URL de Acceso:** `/login`

| Rol / Cargo | Correo Electrónico | Contraseña | Permisos y Alcance |
| :--- | :--- | :--- | :--- |
| **Administrador Central GAMC** | `admin@gamc.bo` | `Admin1234` | Control total, administración de usuarios, instituciones, privilegios, tipos y reportes globales. |
| **Operador Central GAMC** | `operador@gamc.bo` | `Oper12345` | Monitoreo en tiempo real, registro de emergencias manuales, salas de crisis. |
| **Despachador Central GAMC** | `despacho@gamc.bo` | `Despacho123` | Asignación y despacho de emergencias a instituciones y unidades operativas. |
| **Admin Bomberos** | `admin@bomberos.bo` | `Inst12345` | Gestión de la institución de Bomberos, sus unidades (`B-01`), asignaciones y reportes. |
| **Admin Policía Departamental** | `admin@policia.bo` | `Inst12345` | Gestión de la Policía, subinstituciones (EPI 6, EPI 3) y patrulleros (`PAT-301`, `PAT-602`). |
| **Admin Servicio Médico (SME)** | `admin@sme.bo` | `Inst12345` | Gestión de ambulancias UTI (`AMB-03`), traslados médicos y salas de atención. |

---

### 📱 Módulo Ciudadano PWA (App Móvil)
**URL de Acceso:** `/citizen/login`

| Ciudadano | Teléfono de Contacto | Contraseña | Cédula (CI) | Ciudad |
| :--- | :--- | :--- | :--- | :--- |
| **Pedro Gómez Vargas** | `70000010` | `Ciudadano123` | `7891234` | Cochabamba |
| **Andrea Ríos Morales** | `70000020` | `Ciudadano123` | `6543210` | Cochabamba |

---

## 🌐 2. Catálogo Completo de APIs del Sistema

---

### 🚨 MÓDULO 1: Emergencias (Central GAMC e Instituciones)

#### `GET /api/dashboard/emergencies`
- **Descripción:** Lista todas las emergencias principales con paginación y filtros avanzados.
- **Query Params:** `?status=REPORTADA,EN_ATENCION`, `?priority=CRITICA`, `?FK_emergencyType=1`, `?search=SOS-`, `?active=true`, `?page=1`, `?pageSize=20`.

#### `POST /api/dashboard/emergencies`
- **Descripción:** Registro manual de emergencia por un operador central. Crea automáticamente el caso único, ubicación, sala de crisis, reporte inicial y notificaciones.
- **Body:**
```json
{
  "description": "Colisión vehicular con heridos",
  "priority": "CRITICA",
  "FK_emergencyType": 1,
  "latitude": -17.3882,
  "longitude": -66.1954,
  "address": "Av. Blanco Galindo km 4",
  "affectedPersons": 2,
  "trappedPersons": 0
}
```

#### `GET /api/dashboard/emergencies/[PK_emergency]`
- **Descripción:** Obtiene el expediente completo de una emergencia con reportes, asignaciones, evidencias y sala vinculada.

#### `PUT /api/dashboard/emergencies/[PK_emergency]`
- **Descripción:** Actualiza datos del caso (prioridad, descripción, personas afectadas).

#### `DELETE /api/dashboard/emergencies/[PK_emergency]`
- **Descripción:** Cancela o marca como falsa alarma la emergencia.

#### `GET /api/dashboard/emergencies/map`
- **Descripción:** Devuelve todas las emergencias activas con coordenadas geográficas para renderizado en Google Maps.

---

### 🚑 MÓDULO 2: Despacho, Asignaciones y Rastreo GPS

#### `GET /api/dashboard/dispatch`
- **Descripción:** Lista todas las solicitudes de despacho y asignaciones a instituciones/unidades.
- **Query Params:** `?status=SOLICITADA,ACEPTADA,EN_CAMINO,EN_SITIO`, `?emergencyCode=SOS-260829-0001`.

#### `GET /api/dashboard/dispatch/[PK_assignment]`
- **Descripción:** Detalle de una asignación específica, unidad responsable y estado.

#### `POST /api/dashboard/dispatch/[PK_assignment]/accept`
- **Descripción:** La institución/unidad acepta la asignación de emergencia.

#### `POST /api/dashboard/dispatch/[PK_assignment]/depart`
- **Descripción:** Registra que la unidad ha salido hacia el lugar del incidente (`EN_CAMINO`).

#### `POST /api/dashboard/dispatch/[PK_assignment]/arrive`
- **Descripción:** Registra que la unidad llegó al lugar del incidente (`EN_SITIO`).

#### `POST /api/dashboard/dispatch/[PK_assignment]/complete`
- **Descripción:** Finaliza con éxito la atención de la unidad en el incidente.

#### `POST /api/dashboard/dispatch/[PK_assignment]/cancel`
- **Descripción:** Cancela o rechaza la asignación de emergencia.

#### `GET /api/dashboard/dispatch/[PK_assignment]/tracking`
- **Descripción:** Obtiene el historial de coordenadas GPS recorridas por la unidad y la última posición conocida.

#### `POST /api/dashboard/dispatch/[PK_assignment]/tracking`
- **Descripción:** Envío de ping GPS en tiempo real desde el dispositivo móvil de la unidad en camino.
- **Body:**
```json
{
  "latitude": -17.3940,
  "longitude": -66.1750,
  "speed": 48.5,
  "heading": 285.0
}
```

---

### 💬 MÓDULO 3: Sala de Crisis y Mensajería Centralizada

#### `GET /api/dashboard/emergencies/[PK_emergency]/room`
- **Descripción:** Información de la sala de crisis activa, código de sala y lista de miembros integrados.

#### `GET /api/dashboard/emergencies/[PK_emergency]/messages`
- **Descripción:** Historial de mensajes enviados dentro de la sala de crisis.

#### `POST /api/dashboard/emergencies/[PK_emergency]/messages`
- **Descripción:** Envía un mensaje a la sala (texto, alerta, audio, evento).
- **Body:**
```json
{
  "message": "Unidad médica en el punto realizando primeros auxilios.",
  "messageType": "TEXT"
}
```

#### `GET /api/dashboard/emergencies/[PK_emergency]/evidences`
- **Descripción:** Lista todas las fotos, videos y audios asociados a la emergencia.

#### `GET /api/dashboard/emergencies/[PK_emergency]/progress-reports`
- **Descripción:** Bitácora de reportes de evolución emitidos por los equipos en campo.

---

### 📱 MÓDULO 4: Ciudadano (PWA Móvil)

#### `GET /api/citizen/profile` | `PUT /api/citizen/profile`
- **Descripción:** Obtiene y actualiza los datos del perfil del ciudadano autenticado.

#### `POST /api/citizen/emergency/report`
- **Descripción:** Botón SOS del ciudadano. Crea un reporte inmediato con geolocalización.
- **Body:**
```json
{
  "description": "Fuego en pastizales cerca a viviendas",
  "latitude": -17.3750,
  "longitude": -66.1680,
  "address": "Av. Circunvalación norte"
}
```

#### `GET /api/citizen/emergencies`
- **Descripción:** Historial de emergencias reportadas por el ciudadano.

#### `GET /api/citizen/emergencies/[PK_emergency]`
- **Descripción:** Seguimiento en vivo del estado de la emergencia del ciudadano.

#### `GET /api/citizen/emergencies/[PK_emergency]/messages`
- **Descripción:** Mensajes del chat directo entre el ciudadano, la IA y la Central GAMC.

#### `POST /api/citizen/emergencies/[PK_emergency]/messages`
- **Descripción:** Envío de mensaje o aclaración por parte del ciudadano.

#### `POST /api/citizen/emergencies/[PK_emergency]/evidence`
- **Descripción:** Subida de fotografías o videos de la emergencia desde el teléfono.

#### `GET /api/citizen/emergency-numbers`
- **Descripción:** Directorio de números de emergencia institucional de Cochabamba (110, 119, 168, 111, etc.).

#### `GET /api/citizen/notifications` | `PUT /api/citizen/notifications`
- **Descripción:** Bandeja de notificaciones push y confirmación de lectura.

---

### 🏢 MÓDULO 5: Instituciones, Unidades y Recursos

| Endpoint | Métodos | Descripción |
| :--- | :--- | :--- |
| `/api/dashboard/institutions` | `GET`, `POST` | Listar y crear instituciones (Policía, Bomberos, SME, SAR). |
| `/api/dashboard/institutions/[PK_institution]` | `GET`, `PUT`, `DELETE` | Consulta, edición y baja lógica de una institución. |
| `/api/dashboard/subinstitutions` | `GET`, `POST` | Dependencias, bases y estaciones (EPIs, Estaciones de bomberos). |
| `/api/dashboard/subinstitutions/[PK_subinstitution]` | `GET`, `PUT`, `DELETE` | Consulta y gestión de subinstitución. |
| `/api/dashboard/units` | `GET`, `POST` | Listar y registrar unidades vehiculares y patrullas. |
| `/api/dashboard/units/[PK_unit]` | `GET`, `PUT`, `DELETE` | Detalle, actualización de estado y baja de unidad. |
| `/api/dashboard/units/positions` | `GET` | Última posición GPS de todas las unidades en servicio. |

---

### 👥 MÓDULO 6: Usuarios, Privilegios y Ciudadanos

| Endpoint | Métodos | Descripción |
| :--- | :--- | :--- |
| `/api/dashboard/users` | `GET`, `POST` | Administración de usuarios institucionales y operadores GAMC. |
| `/api/dashboard/users/[PK_user]` | `GET`, `PUT`, `DELETE` | Detalle, cambio de rol/institución o desactivación de usuario. |
| `/api/dashboard/privileges` | `GET`, `POST` | Catálogo de roles y privilegios del sistema. |
| `/api/dashboard/privileges/[PK_privilege]` | `GET`, `PUT`, `DELETE` | Gestión de permisos específicos. |
| `/api/citizens` | `GET`, `POST` | Búsqueda y administración de ciudadanos registrados. |
| `/api/citizens/[PK_citizen]` | `GET`, `PUT`, `DELETE` | Expediente y gestión de cuenta del ciudadano. |

---

### 🤖 MÓDULO 7: Inteligencia Artificial, Streaming y Reportes

#### `GET /api/dashboard/ai/sessions`
- **Descripción:** Registro y auditoría de sesiones de interacción con la IA, intención detectada y confianza de vinculación.

#### `POST /api/realtime-token`
- **Descripción:** Generación de token temporal de autenticación para la sesión de voz en tiempo real con WebRTC / AI Gateway.

#### `GET /api/dashboard/realtime`
- **Descripción:** Canal de streaming Server-Sent Events (SSE) para emitir eventos de nuevas emergencias, cambios de estado y chats.

#### `GET /api/dashboard/stats`
- **Descripción:** Métricas del panel de control: emergencias activas, tiempos promedio de respuesta, unidades disponibles y desglose por gravedad.

#### `GET /api/dashboard/reports/overview`
- **Descripción:** Datos agregados para generación de reportes y estadísticas operativas.
