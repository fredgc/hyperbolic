---
title: Política de Privacidad
---

*Última actualización: 31 de octubre de 2026*

---

## Cero Datos de Identificación Personal y Privacidad por Diseño

La **Herramienta de Dibujo Hiperbólico** ("la Aplicación") es una aplicación
educativa interactiva diseñada para construir y explorar diagramas geométricos
dentro del modelo del disco de Poincaréde la geometría hiperbólica. Nos
adherimos a una estricta **Privacidad por Diseño**: no recopilamos información
personal, no requerimos registro de cuenta para usar la herramienta, no le
rastreamos a través de sitios web y no vendemos ni monetizamos datos de
usuarios.

Esta aplicación estádiseñada para estudiantes, profesores, investigadores y
entusiastas de la geometría de todas las edades.

---

## Información que NO Recopilamos

Para mantener una arquitectura sin información de identificación personal:

* **Sin Cuentas de Usuario Obligatorias:** Puede construir, editar y descargar
  diagramas de geometría hiperbólica sin registrar una cuenta.

* **Sin Sensores de Dispositivo ni Permisos Invasivos:** La Aplicación no
  accede a la ubicación del dispositivo (GPS), cámara, micrófono, contactos ni
  sensores biométricos.

* **Sin Publicidad ni Rastreo Entre Sitios:** La Aplicación carece totalmente
  de anuncios y no contiene redes publicitarias, rastreadores de marketing ni
  SDKs de análisis comerciales.

---

## Datos Manejados por la Aplicación

### 1. Configuraciones y Preferencias Locales

* Las configuraciones como su modo de tema preferido (claro, oscuro o del
  sistema), tolerancias de ajuste, precisión de coordenadas, opciones de
  herramientas y selecciones de paleta de colores se almacenan exclusivamente
  en su dispositivo mediante `localStorage` del navegador (en la Web) o
  `SharedPreferences` (en Android/Escritorio).

* En la Web, borrar los datos de aplicaciones del navegador elimina estas
  preferencias. En Android, desinstalar la aplicación elimina todas las
  preferencias almacenadas.

### 2. Archivos de Diagramas y Almacenamiento

* **Almacenamiento Local del Dispositivo:** Los archivos de escenas
  hiperbólicas (`.json`) se pueden descargar y abrir directamente en su
  dispositivo local.

* **Integración Opcional con Google Drive:** Si decide conectar su cuenta de
  Google Drive para guardar o abrir diagramas, la Aplicación utiliza la API
  oficial de Google Driveúnicamente para acceder a los archivos creados por o
  abiertos explícitamente con esta Aplicación. Ningún contenido de diagrama,
  credencial o metadato de archivo se transmite ni almacena jamás en los
  servidores de `gchouse.org`.

* **Enlaces Compartidos:** Si comparte una URL de diagrama que contenga datos
  de escena serializados, esos datos se codifican directamente en el fragmento
  de la URL y son procesados localmente por el navegador del destinatario.

---

## Infraestructura de Terceros

La Aplicación se aloja estáticamente utilizando **Google Firebase Hosting**
(Google LLC):

* Los metadatos de conexión técnica estándar (como direcciones IP y
  encabezados de solicitud HTTP) son procesados temporalmente por la
  infraestructura de Google Cloud estrictamente para enrutamiento, seguridad y
  prevención de denegación de servicio.

* Para obtener más información sobre las prácticas de privacidad de Google,
  consulte la
  [Política de Privacidad de Google](https://policies.google.com/privacy) .

---

## Seguro para Niños y Aulas (COPPA y FERPA)

La Aplicación estádiseñada para cumplir plenamente con las normativas de
privacidad educativa:

* **COPPA (Ley de Protección de la Privacidad Infantil en Internet):** La
  Aplicación no recopila información personal de niños menores de 13 años.

* **FERPA (Ley de Derechos Educativos y Privacidad Familiar):** Dado que no se
  recopilan, mantienen ni comparten registros educativos ni identificadores
  personales de estudiantes, la Aplicación se puede utilizar de forma segura
  en entornos escolares y universitarios.

---

## Preguntas y Contacto

La Herramienta de Dibujo Hiperbólico es un proyecto educativo de código
abierto. Si tiene preguntas o comentarios sobre esta Política de Privacidad:

* **Abra un problema en GitHub:** [GitHub Issues][issues]

* **Visite GC House:** [www.gchouse.org][gchouse]

[gchouse]: https://www.gchouse.org [issues]:
https://github.com/fredgc/hyperbolic/issues
