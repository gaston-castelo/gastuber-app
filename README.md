# 🚖 GastUber - Aplicación de Transporte (Trabajo Práctico)

Aplicación móvil moderna de transporte bajo demanda construida con **Flutter** y **Firebase**, diseñada para simular el funcionamiento integral de una plataforma estilo Uber / Cabify.

---

## 📋 Requisitos del TP Implementados

| # | Requisito | Estado | Ubicación en Código |
|---|---|:---:|---|
| **1** | **Inicio / Login & Registro** con Firebase Auth (email, password, rol Pasajero/Chofer y datos de auto) | ✅ | [`lib/screens/auth/`](lib/screens/auth/) |
| **2** | **Pantalla Principal Cliente (Mapa)** con Google Maps real, ubicación GPS y choferes disponibles | ✅ | [`lib/screens/client/client_home_screen.dart`](lib/screens/client/client_home_screen.dart) |
| **3** | **Solicitud de Viaje** con cálculo de distancia (Haversine), duración y tarifa estimada en vivo | ✅ | [`lib/screens/client/request_ride_screen.dart`](lib/screens/client/request_ride_screen.dart) |
| **4** | **Pantalla de Conductor** con lista de pedidos, aceptar/rechazar y máquina de estados (*Aceptado* → *En curso* → *Finalizado*) | ✅ | [`lib/screens/driver/`](lib/screens/driver/) |
| **5** | **Historial de Viajes** con resumen de gastos/ganancias, viajes completados, fecha y montos | ✅ | [`lib/screens/history/ride_history_screen.dart`](lib/screens/history/ride_history_screen.dart) |
| **6** | **Diseño Visual Profesional**: Paleta Slate/Emerald, tipografía moderna, badges de estado e iconografía temática | ✅ | [`lib/core/theme/`](lib/core/theme/) |
| **+** | **Sistema de Calificación 5 Estrellas** para Chofer y Pasajero con actualización de promedios en Firestore | ✅ | [`lib/screens/widgets/rating_dialog.dart`](lib/screens/widgets/rating_dialog.dart) |
| **+** | **Notificaciones In-App** cuando un chofer toma el viaje | ✅ | [`lib/screens/client/client_tracking_screen.dart`](lib/screens/client/client_tracking_screen.dart) |

---

## ⚙️ Configuración Rápida

### 1. Claves de Firebase
Edita el archivo [`lib/firebase_options.dart`](lib/firebase_options.dart) y coloca los valores de tu consola de Firebase (`projectId`, `apiKey`, `appId`).
> Recuerda tener activados en Firebase Console:
> - **Authentication** (Proveedor Email/Contraseña habilitado).
> - **Cloud Firestore** (creado en modo de prueba / *test mode*).

### 2. Google Maps API Key
1. **Android**: Coloca tu API Key en [`android/app/src/main/AndroidManifest.xml`](android/app/src/main/AndroidManifest.xml):
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="TU_API_KEY_AQUI" />
   ```
2. **Web (Opcional)**: Coloca tu API Key en [`web/index.html`](web/index.html):
   ```html
   <script src="https://maps.googleapis.com/maps/api/js?key=TU_API_KEY_AQUI"></script>
   ```

---

## 🧪 Cómo Probar el Flujo Completo

1. **Crear usuario Chofer**:
   - Toca en *"Regístrate aquí"*, selecciona el rol **Conductor**, ingresa tus datos y los de tu vehículo (ej: *Toyota Corolla*, *AE 123 CD*, *Gris*).
   - Inicia sesión. Verás el panel con el estado *"En línea"* esperando solicitudes.

2. **Crear usuario Pasajero** (en otra ventana, pestaña web o dispositivo):
   - Regístrate como **Pasajero**.
   - En el mapa verás los choferes cercanos disponibles.
   - Toca *"¿A dónde quieres ir hoy?"*, elige un destino (puedes pulsar un destino sugerido como *Universidad* o *Centro Comercial*).
   - Observa cómo se calcula la distancia en km, el tiempo estimado y el precio total.
   - Presiona **"Solicitar GastUber"**.

3. **Interacción en Tiempo Real**:
   - En la pantalla del Chofer aparecerá la tarjeta de viaje al instante.
   - El Chofer pulsa **"Aceptar Viaje"**.
   - Al Pasajero le saldrá la notificación in-app *"¡Tu chofer ha aceptado el viaje!"* y verá los datos del auto.
   - El Chofer pulsa **"Iniciar Viaje"** (estado pasa a *En curso*).
   - Al llegar a destino, el Chofer pulsa **"Finalizar Viaje"**.
   - A ambos se les abrirá el **Diálogo de Calificación** (1 a 5 estrellas) para evaluar al otro.
   - En la sección **"Historial"**, ambos podrán ver el registro contable y el estado del viaje.
