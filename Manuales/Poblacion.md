# Simulador Fiscal CIEP v5.3: Población y proyecciones

Versión: 21 de febrero de 2025


<hr style="border: none; height: 2px; background-color: #ff7020;">


## Poblacion.ado

**Descripción:** *Ado-file* que automatiza la extracción de datos de las Proyecciones de la Población de México del CONAPO. 


<details>
  <summary>**Conoce la lista de indicadores de interés generados**</summary>
  
  * **Población:** Muestra los datos de población históricos y su proyección hasta 2070.
</details>


<h3 style="color: #ff7020;">1. Input:</h3>

En este programa se integran tres bases de datos del CONAPO:[^1]

1. Población: Contiene la estimación del número de habitantes a mitad de cada año entre 1950 y 2070.
2. Defunciones: Contiene la estimación de las defunciones anuales entre 1950 y 2070. 
3. Migración Internacional: Contiene la estimación del número de inmigrantes y emigrantes internacionales entre 1950 y 2069.

<details>
  <summary>Mostrar código fuente</summary>
  ![paso1](images/Poblacion/CodigoFuente1A.png)
  ![paso1](images/Poblacion/CodigoFuente1B.png)
  ![paso1](images/Poblacion/CodigoFuente1C.png)
  ![paso1](images/Poblacion/CodigoFuente1D.png)

</details>


<h3 style="color: #ff7020;">2. Sintaxis:</h3>

Para extraer datos, ingresa el prompt en la consola llamando al programa y selecciona los filtros y opciones deseados. El prompt sigue esta sintaxis:

`Poblacion [if] [, ANIOinicial(int) ANIOFINAL(int) NOGraphs UPDATE]`

Para crear comandos de manera automática y evitar errores de sintaxis, utiliza nuestra calculadora de prompts.

<div style="text-align: center;">
    <h4 style="border-bottom: 2px solid black; display: inline-block;">Calculadora de Prompts</h4>
</div>

**A. Filtros disponibles:**

<!-- Filtros disponibles para incluir en el comando -->

<!-- Filtro: Entidad -->
<label for="estado">Entidad:</strong></label>
<select id="estado" onchange="actualizarComando()">
  <option value="" selected disabled>Selecciona un estado</option>
  <option value="Nacional">Nacional</option>
  <option value="Aguascalientes">Aguascalientes</option>
  <option value="Baja California">Baja California</option>
  <option value="Baja California Sur">Baja California Sur</option>
  <option value="Campeche">Campeche</option>
  <option value="Chiapas">Chiapas</option>
  <option value="Chihuahua">Chihuahua</option>
  <option value="Ciudad de México">Ciudad de México</option>
  <option value="Coahuila">Coahuila</option>
  <option value="Colima">Colima</option>
  <option value="Durango">Durango</option>
  <option value="Estado de México">Estado de México</option>
  <option value="Guanajuato">Guanajuato</option>
  <option value="Guerrero">Guerrero</option>
  <option value="Hidalgo">Hidalgo</option>
  <option value="Jalisco">Jalisco</option>
  <option value="Michoacán">Michoacán</option>
  <option value="Morelos">Morelos</option>
  <option value="Nayarit">Nayarit</option>
  <option value="Nuevo León">Nuevo León</option>
  <option value="Oaxaca">Oaxaca</option>
  <option value="Puebla">Puebla</option>
  <option value="Querétaro">Querétaro</option>
  <option value="Quintana Roo">Quintana Roo</option>
  <option value="San Luis Potosí">San Luis Potosí</option>
  <option value="Sinaloa">Sinaloa</option>
  <option value="Sonora">Sonora</option>
  <option value="Tabasco">Tabasco</option>
  <option value="Tamaulipas">Tamaulipas</option>
  <option value="Tlaxcala">Tlaxcala</option>
  <option value="Veracruz">Veracruz</option>
  <option value="Yucatán">Yucatán</option>
  <option value="Zacatecas">Zacatecas</option>
</select>

<!-- Filtro: Sexo -->
<label for="sexo">Sexo:</strong></label>
<select id="sexo" onchange="actualizarComando()">
  <option value="" selected disabled>Selecciona un sexo</option>
  <!-- Se asigna "1" para Hombres y "2" para Mujeres -->
  <option value="1">Hombres</option>
  <option value="2">Mujeres</option>
  <option value=>Ambos</option>
</select>


**B. Opciones disponibles:**

<!-- Filtro: Año inicial y final -->
<label for="anioInicial">Año Inicial:</strong></label>
<input type="number" id="anioInicial" placeholder="Escribe el año base" oninput="actualizarComando()">

<label for="anioFinal">Año Final:</strong></label>
<input type="number" id="anioFinal" placeholder="Escribe el año final" oninput="actualizarComando()">

<!-- Opciones: NOGraphs y UPDATE -->
<label for="noGraphs">Sin gráficos:</label>
<input type="checkbox" id="noGraphs" onchange="actualizarComando()">

<label for="update">Actualizar base:</label>
<input type="checkbox" id="update" onchange="actualizarComando()">

**Copia y pega este comando en la consola:**
<pre id="codigoComando">Poblacion</pre>

<script>
  function actualizarComando() {
    // Obtiene valores de cada filtro
    var estado = document.getElementById("estado").value;
    var sexo = document.getElementById("sexo").value;
    var anioInicial = document.getElementById("anioInicial").value;
    var anioFinal = document.getElementById("anioFinal").value;
    var noGraphs = document.getElementById("noGraphs").checked;
    var update = document.getElementById("update").checked;

    // Comando base
    var comando = "Poblacion";
    
    // Construye las condiciones sólo si se seleccionó alguna opción
    var condiciones = [];
    if (estado) {
       condiciones.push('entidad == "' + estado + '"');
    }
    if (sexo) {
       condiciones.push('sexo == ' + sexo);
    }
    
    if (condiciones.length > 0) {
       comando += " if " + condiciones.join(" & ");
    }
    
    // Prepara opciones adicionales (después de la coma)
    var opciones = "";
    if (anioInicial) {
       opciones += ' anioinicial(' + anioInicial + ')';
    }
    if (anioFinal) {
       opciones += ' aniofinal(' + anioFinal + ')';
    }
    if (noGraphs) {
       opciones += ' nographs';
    }
    if (update) {
       opciones += ' update';
    }
    
    // Si se definió alguna opción, la agrega tras la coma
    if (opciones.trim() !== "") {
       comando += ',' + opciones;
    }
    
    document.getElementById("codigoComando").textContent = comando;
  }
</script>



<details>
  <summary>Mostrar código fuente</summary>
  ![paso1](images/Poblacion/Paso 1.png)

</details>




<h3 style="color: #ff7020;">3. Output:</h3>

Tras ingresar el prompt, el código devolverá tres elementos: ventana de resultados, dos gráficas y la base de datos. Podrás modificar el ado.file para obtener una base a tus necesidades.

**1. Ventana de Resultados:** Muestra un resumen del análisis realizado. 

  ![resultados](images/Poblacion/Ventana de Resultados.png) 
  
  <details>
  <summary>Mostrar código fuente</summary>
  ![CodigoFuente2A](images/Poblacion/CodigoFuente2A.png)
  </details>

**2. Gráficas:** Representación visual de los indicadores calculados.

![Piramides](images/Poblacion/Piramides Demograficas.png) 

![Transición](images/Poblacion/Transicion Demografica y Tasa de Dependencia.png) 

**3. Base de Datos:** Permite al usuario obtener una base recortada y limpia para hacer sus propios análisis.

![paso2](images/Poblacion/Base de Datos.png)

<details>
  <summary>Mostrar código fuente</summary>
  ![CodigoFuente2A](images/Poblacion/CodigoFuente2C.png)
 </details>



[^1]: **Link:** [Bases de Datos CONAPO](https://www.gob.mx/conapo/articulos/reconstruccion-y-proyecciones-de-la-poblacion-de-los-municipios-de-mexico)
