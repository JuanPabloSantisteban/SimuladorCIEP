# Simulador Fiscal CIEP v5.3: PIB, deflactor y proyecciónes

Versión: 14 de Febrero de 2023


---

## PIBDeflactor.ado
**Descripción**: *Ado-file* (`.ado`) diseñado para automatizar el cálculo y predicción de indicadores económicos utilizando datos del Banco de Información Económica (BIE) y el Consejo Nacional de Población (CONAPO). 

En este programa Explicar cómo se va a comportar los indicadores, 1 histórico 2 estimación y 3 proyección

<details>
  <summary>Lista de indicadores generados</summary>

---
**1. Crecimiento Económico y Productividad**  

* **pibY:** PIB nominal en moneda corriente.
* **pibYR:** PIB real ajustado por inflación.
* **var_pibY:** Crecimiento anual del PIB real.
* **var_pibG:** Promedio geométrico del crecimiento del PIB real.
* **PIBPob:** PIB real per cápita.
* **pibPO:** PIB real por población ocupada.
* **OutputPerWorker:** PIB real por población en edad de trabajar.
* **pibYVP:** PIB real descontado a valor presente.

**2. Demografía**  

* **PoblacionENOE:** Población total estimada según la ENOE de INEGI.
* **PoblacionOcupada:** Población ocupada según la ENOE de INEGI.
* **PoblacionDesocupada:** Población desocupada según la ENOE de INEGI.
* **Poblacion:** Estimaciones de población de CONAPO.
* **PoblacionO:** Población ocupada ajustada para cálculos de productividad.
* **WorkingAge:** Población en edad de trabajar (15-65 años) según CONAPO.

**3. Precios e Inflación**  

* **inpc:** Índice Nacional de Precios al Consumidor (INPC).
* **IndiceY:** Índice de precios implícitos del PIB.
* **deflator:** Deflactor del PIB con base en el índice de precios implícitos.
* **deflatorpp:** Poder adquisitivo ajustado por inflación.
* **var_indiceY:** Crecimiento anual del índice de precios implícitos.
* **var_indiceG:** Promedio geométrico del crecimiento del índice de precios.
* **var_inflY:** Inflación anual calculada con el INPC.
* **var_inflG:** Promedio geométrico de la inflación en varios años.

---

</details>



### 1. Input

En este programa se utilizan 2 fuentes de datos:

1. BIE:  Proporciona datos sobre el PIB, el deflactor de precios, la inflación y el empleo. 
2. CONAPO: Contiene la estimación del número de habitantes a mitad de cada año entre 1950 y 2070.


### 2. Sintaxis

Para extraer los datos, es necesario ingresar el prompt en la consola siguiendo esta sintaxis:

`PIBDeflactor [if] [, ANIOvp(int) ANIOMAX(int 2070)  GEOPIB(int) GEODEF(int) DIScount(real) NOGraphs UPDATE]`


Para crear comandos de manera automática y evitar errores de sintaxis, utiliza nuestra calculadora de prompts.

<h4 style="border-bottom: 2px solid black; display: inline-block;">Calculadora de Prompts</h4>


**A. Filtros disponibles:**

**B. Opciones disponibles:**
<!-- Opciones para PIBDeflactor -->

<div>
  <label for="anioVp">Año Base:</label>
  <input 
    type="number" 
    id="anioVp" 
    placeholder="Ej. 2024" 
    oninput="actualizarComando()"
  >
</div>
<div>
  <label for="aniofinal">Año Final:</label>
  <input type="number" id="aniomax" placeholder="Ej. 2070" oninput="actualizarComando()">
</div>
<div>
  <label for="geopib">Promedio Geométrico PIB:</label>
  <input type="number" id="geopib" placeholder="Ej. 1993" oninput="actualizarComando()">
</div>
<div>
  <label for="geodef">Promedio Geométrico Deflactor:</label>
  <input type="number" id="geodef" placeholder="Ej. 1993" oninput="actualizarComando()">
</div>
<div>
  <label for="discount">Tasa de descuento:</label>
  <input type="number" id="discount" step="0.1" placeholder="Ej. 5" oninput="actualizarComando()">
</div>
<div>
  <label for="noGraphs">Sin gráficos:</label>
  <input type="checkbox" id="noGraphs" onchange="actualizarComando()">
</div>
<div>
  <label for="update">Actualizar base:</label>
  <input type="checkbox" id="update" onchange="actualizarComando()">
</div>

<p><strong>Copia y pega este comando en la consola:</strong></p>
<pre id="códigoComando">PIBDeflactor</pre>

<script>
  function actualizarComando() {
    // Obtiene los valores de cada opción
    var anioVp   = document.getElementById("anioVp").value;
    var geopib   = document.getElementById("geopib").value;
    var geodef   = document.getElementById("geodef").value;
    var discount = document.getElementById("discount").value;
    var aniomax  = document.getElementById("aniomax").value;
    var noGraphs = document.getElementById("noGraphs").checked;
    var update   = document.getElementById("update").checked;

    // Comando base
    var comando = "PIBDeflactor";
    
    // Construye las opciones adicionales
    var opciones = "";
    if(anioVp)   { opciones += " aniovp(" + anioVp + ")"; }
    if(geopib)   { opciones += " geopib(" + geopib + ")"; }
    if(geodef)   { opciones += " geodef(" + geodef + ")"; }
    if(discount) { opciones += " discount(" + discount + ")"; }
    if(aniomax)  { opciones += " aniomax(" + aniomax + ")"; }
    if(noGraphs) { opciones += " nographs"; }
    if(update)   { opciones += " update"; }
    
    // Agrega las opciones al comando si se definió alguna
    if(opciones.trim() !== "") {
       comando += "," + opciones;
    }
    
    // Actualiza el pre con el comando final
    document.getElementById("códigoComando").textContent = comando;
  }
</script>

**Descripción de opciones**:

- **Año Base (aniovp)**: Cambia el año de referencia para calcular el *valor presente*. Tiene que ser un número entre 1993 (mínimo reportado por el INEGI/BIE) y 2050 (máximo proyectado por el CONAPO, en su base de población). El *año actual* es el valor por default.
- **Año Final (aniomax)**: Año final para las proyecciónes de las gráficas. El último año de la serie (2070) es el valor por default.
- **Promedio Geométrico PIB (geopib)**:  Año base a partir del cual se calcula el crecimiento promedio geométrico del PIB, utilizado para proyectar el crecimiento en años futuros. [^1]
- **Promedio Geométrico Deflactor (geodef)**:  Año base a partir del cual se calcula el crecimiento promedio geométrico del deflactor del PIB, utilizado para estimar la evolución de los precios en el futuro. [^2] 
- **Tasa de Descuento (discount)**: Tasa utilizada para convertir valores futuros del PIB en su equivalente a valor presente.
- **Sin Gráfico (nographs)**: Evita la generación de gráficas.
- **Actualizar Base (update)**: Corre un *do.file* para obtener los datos más recientes del BIE y el CONAPO. 


<details>
  <summary>Mostrar código</summary>
  ![paso1](images/PIBDeflactor/Paso 1.png) 
</details>




### 3. Output

Tras ingresar el prompt, el código regresará tres elementos: ventana de resultados, cuatro gráficas y la base de datos. Podrás modificar el ado.file para obtener una base a tus necesidades.

**1. Ventana de Resultados:** Muestra un resumen del análisis realizado. 

![resultados](images/PIBDeflactor/Ventana de Resultados.png) 


**2. Gráficas:** Representación visual de los indicadores calculados. 

#####A
![Indice](images/PIBDeflactor/Indice de Precios Implicitos.png)

#####B
![PIB](images/PIBDeflactor/Producto Interno Bruto.png)

#####C
![PIBP](images/PIBDeflactor/Producto Interno Bruto por Persona.png)

#####D
![INPC](images/PIBDeflactor/Indice Nacional De Precios al Consumidor.png)


**3. Base de Datos:** Permite al usuario obtener una base recortada y limpia para hacer sus propios análisis.

  Ejemplo:
  ![BASE](images/PIBDeflactor/Base De Datos.png) 



[^1]: El promedio geométrico se calcula desde el año seleccionado hasta el año actual. Este valor se usa para estimar el PIB del siguiente año, aplicando el crecimiento promedio geométrico obtenido. A medida que avanzan los años, la ventana del cálculo se ajusta, incorporando el año más reciente y descartando el más antiguo.


[^2]: El cálculo se realiza desde el año seleccionado hasta el año actual para obtener una tasa de cambio promedio en los precios. Esta tasa se aplica para proyectar la inflación futura y ajustar el deflactor del PIB en los próximos años. La ventana de cálculo se ajusta dinámicamente año tras año, incorporando el dato más reciente y eliminando el más antiguo.