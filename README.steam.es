[h1]Eris Food Expiry (fork TooltipLib)[/h1]

[b]Fork no oficial · Build 42.21 · Un jugador y multijugador[/b]

¿Cuánto falta para que esta leche se eche a perder? Pasa el ratón sobre cualquier alimento: el tooltip muestra su frescura y el tiempo exacto hasta que se pone rancio y se pudre. Despliega una pila en el inventario para ver una fina barra de frescura bajo cada objeto.

[img]https://raw.githubusercontent.com/cyberbobjr/ErisFoodExpiry/main/docs/steam/05-tooltip-fridge.png[/img]

[h2]Dos mods originales, un fork[/h2]

Este mod continúa el trabajo de dos objetos del Workshop. Gracias a sus autores.
[list]
[*][url=https://steamcommunity.com/sharedfiles/filedetails/?id=3392259028][B42] eris food expiry[/url]: port a Build 42 del mod de eris, con la opción Nutricionista.
[*][url=https://steamcommunity.com/sharedfiles/filedetails/?id=3629527156][B42.13] eris food expiry[/url]: actualización para 42.13 en un jugador, tiempos exactos sin el rasgo.
[/list]
Ambos usan el ID de mod [i]eris_food_expiry[/i]: este fork está marcado como incompatible con él. Activa solo uno.

[h2]Lo que ves[/h2]

[list]
[*]Barra de [b]Frescura[/b]: llena cuando el alimento es nuevo, vacía cuando está podrido.
[*][b]Rancio en[/b] y [b]Podrido en[/b]: tiempo restante, primero las unidades mayores (años, meses, semanas, días, horas, minutos).
[*]Comida congelada: «Congelado: no se estropea» en un congelador en marcha; en otro sitio, [b]Descongelado en[/b] y luego los tiempos una vez descongelada. Conservas y comida seca: «No caduca nunca».
[*]Comida podrida: [b]Desaparece en[/b], cuando la opción sandbox [i]Eliminación de comida podrida[/i] está activa (un compostador la conserva).
[*]Opción (Opciones > Mods): exigir el rasgo Nutricionista para los tiempos exactos. Un envase legible siempre los muestra, como la información nutricional del juego. Si no, un estado aproximado: muy fresco, fresco, parece bien, empieza a pudrirse, casi podrido, podrido.
[/list]

[img]https://raw.githubusercontent.com/cyberbobjr/ErisFoodExpiry/main/docs/steam/02-fridge.jpg[/img]

[h2]Tiempos que siguen al juego[/h2]

El tiempo restante se calcula igual que el juego envejece la comida:
[list]
[*]opciones sandbox [i]Deterioro de la comida[/i] y [i]Eficacia de la refrigeración[/i];
[*]una nevera o un congelador frena el deterioro mientras tiene corriente: un generador, o la red hasta el día del corte, después la comida vuelve a estropearse a velocidad normal;
[*]la comida congelada no se estropea hasta descongelarse;
[*]las edades de deterioro propias de cada objeto (la comida cocinada difiere de la cruda).
[/list]

[img]https://raw.githubusercontent.com/cyberbobjr/ErisFoodExpiry/main/docs/steam/03-frozen.jpg[/img]

[img]https://raw.githubusercontent.com/cyberbobjr/ErisFoodExpiry/main/docs/steam/06-tooltip-thawing.png[/img]

[h2]Cambios respecto a los originales[/h2]

[list]
[*]Líneas del tooltip mediante [url=https://steamcommunity.com/sharedfiles/filedetails/?id=3694097672]TooltipLib[/url]: sin recuadro dibujado bajo el tooltip, sin tooltip que salta, compatible con otros mods de tooltip.
[*]Nevera sin corriente, comida congelada y cocinada dan tiempos correctos.
[*]Unidades siempre en orden: los originales podían mostrar «5m 2d 1w» u omitir los años.
[*]El estado «Podrido» vuelve a mostrarse; los textos de la opción y las traducciones cargan en 42.21 (JSON).
[*]La barra del inventario ya no se superpone a la línea de nutrición o de cocción.
[/list]

[img]https://raw.githubusercontent.com/cyberbobjr/ErisFoodExpiry/main/docs/steam/04-read-the-label.jpg[/img]

[h2]Multijugador[/h2]

Solo visual: no se envía nada al servidor ni se guarda nada. Instálalo en el servidor para que los clientes lo descarguen; cada jugador ajusta la opción para sí mismo. Se puede añadir o quitar sin riesgo en un mundo existente.

[h2]Requisitos[/h2]

[list]
[*]Build 42.21 o posterior.
[*][url=https://steamcommunity.com/sharedfiles/filedetails/?id=3694097672]TooltipLib[/url].
[/list]

[h2]Idiomas[/h2]

Inglés, francés, alemán, español, italiano, polaco, portugués, portugués de Brasil, ruso, chino simplificado.

[h2]Apoya el proyecto[/h2]

¿Te gusta el mod? Un café ayuda a financiar nuevas funciones y traducciones.
[url=https://ko-fi.com/Z8Z8QJV31][img]https://storage.ko-fi.com/cdn/kofi6.png?v=6[/img][/url]

[h2]Créditos[/h2]

Idea y mod original: eris. Ports a Build 42: los autores de los dos objetos de arriba. Fork de batman, código reescrito. Sin relación con los autores originales. Código fuente (MIT) en [url=https://github.com/cyberbobjr/ErisFoodExpiry]GitHub[/url].
