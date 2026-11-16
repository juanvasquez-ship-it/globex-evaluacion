# Ejecución de los bancos de Globex

Este repositorio envía los bancos completos al chatbot Globex y guarda sus respuestas para una evaluación posterior. No ejecuta un LLM juez ni calcula KPI o calificaciones.

El archivo principal es **`02_Ejecutar_Bancos.ipynb`**. Incluye el ejecutor, la exportación y todos los casos, por lo que no necesita buscar módulos ni bancos en otras carpetas.

| Banco | Casos |
| --- | ---: |
| Preguntas frecuentes | 99 |
| Derivación al asesor | 24 |
| Productos no admitidos o con condiciones especiales | 35 |
| Cotizaciones | 40 |
| Chats para recopilación y resumen | 30 |
| **Total** | **228** |

Cada caso crea una sesión independiente en `https://globex-mvp.onrender.com/api/eval/caso`. En los chats de varios turnos se envía la conversación completa en una solicitud, manteniendo su orden y contexto. La API de evaluación no envía mensajes a WhatsApp.

## Antes de comenzar

Necesitas conexión a internet y la **clave de evaluación de Globex**, que proporciona el equipo. La clave del endpoint es suficiente; no se necesita una clave de un proveedor de LLM.

Para la preparación local se utiliza Windows 10 u 11 y una cuenta con permisos para instalar programas para el usuario actual. Si faltan Python o VS Code, el preparador intenta instalarlos mediante `winget`. Si el equipo no permite instalaciones o no dispone de `winget`, puedes usar Google Colab.

El repositorio es privado. El profesor debe iniciar sesión en una cuenta de GitHub con acceso antes de descargarlo.

## Ejecutar en Windows

1. Abre [el repositorio](https://github.com/juanvasquez-ship-it/globex-evaluacion), pulsa **Code → Download ZIP** y descomprime todo el contenido en una carpeta donde vayas a conservarlo. No ejecutes los archivos desde dentro del ZIP.
2. Haz doble clic en **`Preparar_y_Abrir_VSCode.cmd`**. El preparador comprueba Python, crea `.venv`, instala las dependencias fijadas, registra el kernel y prepara las extensiones de VS Code. Este paso se realiza una vez por carpeta y computadora; vuelve a ejecutarlo si necesitas reparar la preparación.
3. Se abrirá **`02_Ejecutar_Bancos.ipynb`** en VS Code. Si aparece el aviso de confianza, revisa la carpeta descargada y autorízala para ejecutar el notebook. Si solicita un kernel, selecciona **Python (Globex)**.
4. Pulsa **Ejecutar todo / Run All** o el botón **▶** de la única celda de código. Introduce la clave en la entrada oculta cuando se solicite. La clave no aparece en pantalla ni se escribe en archivos del repositorio.
5. Espera a que termine la ejecución. El notebook muestra cada ID enviado y el estado HTTP recibido. Al finalizar se abre el ZIP de respuestas y aparece un enlace al archivo.

Después de esta primera preparación puedes abrir el notebook directamente en VS Code y pulsar Run All, sin volver a instalar las dependencias. Si cambias de computadora o mueves la carpeta ya preparada, descarga una copia limpia y ejecuta de nuevo el preparador.

## Ejecutar en Google Colab

Abre [Google Colab](https://colab.research.google.com/), elige **Archivo → Subir notebook** y selecciona `02_Ejecutar_Bancos.ipynb`. Conecta el entorno y pulsa **Entorno de ejecución → Ejecutar todo**. No necesitas ejecutar los scripts de Windows ni instalar bibliotecas adicionales.

Introduce la clave cuando se solicite. También puedes guardar `EVAL_API_KEY` en los secretos de Colab y permitir que el notebook la lea. No se solicita acceso a Google Drive. Al terminar se inicia la descarga del ZIP de respuestas; el navegador puede pedir autorización para descargarlo.

Los archivos de Colab permanecen en el almacenamiento temporal de la sesión. Descarga el ZIP antes de desconectar o cerrar el entorno. Este modo se ha comprobado mediante sus interfaces y un entorno simulado; la entrega no se ha ejecutado en una sesión alojada de Colab.

## Resultados y continuidad

El archivo **`RUN_…_RESPUESTAS.zip`** contiene cinco carpetas, una por banco, con un `Resultados.json` en cada una. Conserva los identificadores, las preguntas o turnos correspondientes, los textos devueltos y las incidencias de captura. El formato es compatible con la entrada estructurada preparada para una evaluación posterior; no incluye prompts ni rúbricas del juez.

Además se conservan, en `resultados_globex`, los JSONL completos y los cuerpos originales de las respuestas HTTP. El ZIP `RUN_…_RESPALDO_TECNICO.zip` reúne ese registro para verificar los resultados; no necesitas adjuntarlo al LLM juez. Los textos del chatbot se copian literalmente, sin corregirlos ni resumirlos.

La ejecución utiliza un máximo de 30 casos por minuto y espera hasta 180 segundos por solicitud. La duración depende del servidor y de los casos de varios turnos. Mantén abierta la sesión hasta obtener el archivo final.

Si interrumpes la celda o se detiene por una incidencia, los resultados recibidos permanecen guardados y el ZIP identifica los casos sin captura. Volver a pulsar Play en la misma sesión y carpeta retoma los casos pendientes sin reenviar las capturas existentes. Una solicitud cuyo resultado no se confirmó por un problema de conexión no se reintenta automáticamente, porque podría haberse ejecutado en el servidor. Tampoco se repiten automáticamente las respuestas HTTP con error.

Una ejecución ya finalizada se vuelve a exportar al pulsar Play. Para iniciar otra ejecución completa puede cambiarse `NUEVA_CORRIDA` a `True` en la celda; para ejecutar por primera vez no hace falta modificar el código.

## Si aparece un problema

| Situación | Qué hacer |
| --- | --- |
| No se puede instalar Python, VS Code o las dependencias | Comprueba internet y los permisos del equipo. Si la política del equipo impide instalar, utiliza Colab. El preparador no desactiva la validación de certificados. |
| VS Code no reconoce el intérprete o el kernel | Ejecuta de nuevo `Preparar_y_Abrir_VSCode.cmd` desde la carpeta descomprimida y selecciona **Python (Globex)**. El preparador registra la ruta válida de esa computadora. |
| HTTP 401 | La clave falta o no es válida. Solicita al equipo una clave vigente; no la pegues dentro del código. |
| HTTP 422 | La API rechazó la solicitud. Conserva el ZIP y comparte con el equipo el ID y la incidencia registrados. |
| HTTP 429 | Se alcanzó un límite del servidor. Espera a que el equipo confirme cuota disponible; la ejecución conserva el avance. |
| HTTP 503 o error de conexión | El servicio puede estar iniciándose o no estar disponible. Render puede tardar en despertar. Conserva el avance y consulta al equipo antes de repetir solicitudes sin confirmación. |
| No se descarga el ZIP en Colab | Revisa el permiso de descargas del navegador o descárgalo desde el panel de archivos de Colab. En Windows el notebook muestra la ruta exacta del archivo. |

El equipo debe mantener el endpoint desplegado, la autenticación y la cuota disponibles. La preparación local no puede garantizar el estado de esos servicios externos.
