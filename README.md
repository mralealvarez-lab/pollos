# Presupuesto de Pollos

App de presupuesto mensual en pareja. Es una sola página HTML que se publica en GitHub Pages y sincroniza los datos con Supabase (plan gratuito).

## Archivos

| Archivo | Para qué sirve |
|---|---|
| `index.html` | La app completa |
| `schema.sql` | Crea la tabla y los permisos en Supabase |
| `manifest.json`, `sw.js`, `icon-*.png` | Permiten instalarla en el teléfono (PWA) |

Sin configurar nada, la app arranca en **modo local**: guarda los datos solo en ese navegador. Sirve para probarla.

## Puesta en marcha (unos 15 minutos)

### 1. Supabase
1. Crea una cuenta en supabase.com y un proyecto nuevo (región Frankfurt).
2. **SQL Editor → New query**. Pega `schema.sql`, cambia los dos correos por los suyos y dale **Run**.
3. **Authentication → Users → Add user → Create new user**. Crea uno para cada uno con correo y contraseña, y marca *Auto Confirm User*.
4. **Authentication → Sign In / Providers**. Desactiva *Allow new users to sign up*.
5. **Project Settings → API**. Copia la *Project URL* y la clave *anon public*.

### 2. Conectar la app
En `index.html`, busca el bloque `CONFIG` y pega los dos valores:

```js
const CONFIG = {
  SUPABASE_URL: 'https://xxxx.supabase.co',
  SUPABASE_ANON_KEY: 'eyJ...',
  PERSONAS: ['Alex', 'Luisa']
};
```

La clave *anon* puede ir en el archivo público sin problema: los permisos del SQL solo dejan leer y escribir a sus dos correos.

### 3. GitHub Pages
Sube todos los archivos a un repositorio nuevo, por ejemplo `pollos`. Luego ve a **Settings → Pages → Deploy from branch → main / root**.

### 4. En el iPhone
Abre el enlace en Safari y toca **Compartir → Añadir a pantalla de inicio**.

## Cómo funciona

- **Tres fondos**: Banco, Efectivo y Ahorro. El fondo común es la suma de los tres y muestra aparte cuánto está disponible y cuánto está ahorrado.
- **Ingreso / Gasto**: quién, monto, medio (banco o efectivo), rubro (solo en gastos), concepto y fecha. El ahorro no admite gastos directos: es dinero que no se toca.
- **Traspaso**: mueve dinero entre dos fondos cualesquiera (banco → ahorro, cajero → efectivo, ahorro → banco…). No cuenta como ingreso ni como gasto.
- **Rubros**: Vivienda, Comida, Transporte, Servicios, Ocio, Viajes, Salud y Otros vienen por defecto. Con "Editar" se renombran, se agregan, se borran y se les pone un tope mensual. Cada rubro muestra cuánto se ha gastado, cuánto queda o en cuánto se excedieron.
- **Por asignar**: ingresos del mes menos lo presupuestado y lo ahorrado.
- **Detalle**: al tocar un fondo o un rubro ves cuánto corresponde a cada persona y su historial.
- **◐**: alterna entre blanco sobre negro y negro sobre blanco.

## Pausa del plan gratuito
Supabase duerme un proyecto gratuito que pasa 7 días sin uso. Con uso diario no pasa. Como seguro, un workflow de n8n puede hacer un GET cada 3 días a:
`https://xxxx.supabase.co/rest/v1/movimientos?select=id&limit=1`
con los headers `apikey: <anon key>`.

## Lista de pruebas en vivo
Háganla los dos, cada uno en su teléfono, con montos pequeños. Al terminar borren los movimientos de prueba con la ×.

1. **Login**: cada uno entra con su correo. El punto de arriba debe decir *En vivo*.
2. **Ingreso**: Alex registra 10 € al banco. En el teléfono de Luisa debe aparecer en segundos, sin recargar.
3. **Efectivo**: Luisa registra un ingreso de 5 € en efectivo. Al tocar *Efectivo* debe verse 5 € a su nombre.
4. **Gasto con rubro**: un gasto de 2 € en Comida. La barra de Comida debe moverse.
5. **Ahorro**: un traspaso de 3 € de Banco → Ahorro. Baja *Disponible*, sube *Ahorro* y el total no cambia.
6. **Tope**: en *Editar*, pongan a Ocio un tope de 1 € y registren un gasto de 2 €. Debe salir *Excedido por 1,00 €*.
7. **Tema**: el botón ◐ cambia los colores, y cada teléfono recuerda su elección.
8. **Instalación**: *Añadir a pantalla de inicio* en Safari. Debe abrir a pantalla completa con el ícono y el nombre *Pollos*.

Si algo falla, lo más común es:
- *Error de conexión*: revisen la URL y la clave en `CONFIG`.
- Entran pero no ven nada o no pueden guardar: el correo no coincide con el de `schema.sql`. Corríjanlo y vuelvan a correr el SQL.
- Los cambios no aparecen al instante en el otro teléfono: no se activó el tiempo real. Vuelvan a correr el SQL.
