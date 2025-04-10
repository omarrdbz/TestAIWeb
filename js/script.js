// js/script.js

// Función para mostrar la imagen seleccionada y su URL
function display(event) {
  let input_image = document.getElementById("input_image");
  // Crear una URL temporal a partir del archivo seleccionado
  input_image.src = URL.createObjectURL(event.target.files[0]);
  console.log(input_image.src);

  // Actualizar el contenido del párrafo con id "imageUrl" mostrando la URL
  let d = document.getElementById("imageUrl");
  d.textContent = input_image.src;
}

// Función asíncrona para preprocesar la imagen, cargar el modelo y realizar la predicción
async function predict_animal() {
  let input = document.getElementById("input_image");

  // Verificar que se haya cargado una imagen antes de preprocesarla
  if (!input.src) {
      alert("Por favor, sube una imagen primero.");
      return;
  }
  
  // Preprocesamiento: se utiliza TensorFlow.js para redimensionar y normalizar la imagen
  let imageproc = tf.browser.fromPixels(input)
                    .resizeNearestNeighbor([224, 224])
                    .expandDims(0)
                    .div(255.0);
  console.log("Finalización del preprocesamiento de la imagen");

  // Cargar el modelo de TensorFlow.js (asegúrate de que la ruta es correcta)
  const model = await tf.loadLayersModel('./tensorflowjs-model/model.json');
  let pred = model.predict(imageproc);
  pred.print();
  console.log("Finalización de predicción");

  // Declaración del arreglo con las clases de nuestro modelo
  let animals = ["Ardilla", "Luciérnaga", "Mariposa", "Tecolote", "Zorro"];

  // Determinar el índice con el valor más alto (la clase con mayor probabilidad)
  pred.data().then((data) => {
      console.log(data);
      let output = document.getElementById("output_text");
      // Si no existe previamente el div para mostrar el resultado, lo creamos
      if (!output) {
          output = document.createElement("div");
          output.id = "output_text";
          output.className = "alert alert-info mt-4";
          document.querySelector(".container").appendChild(output);
      }
      output.innerHTML = "";
      let max_val = -1;
      let max_val_index = -1;
      for (let i = 0; i < data.length; i++) {
          if (data[i] > max_val) {
              max_val = data[i];
              max_val_index = i;
          }
      }
      let ANIMAL_DETECTADO = animals[max_val_index];
      // Mostrar el resultado con probabilidad formateada
      output.innerHTML = `<p>El animal detectado y su probabilidad corresponden a:</p>
                          <p>Animal detectado: ${ANIMAL_DETECTADO} ( ${(max_val*100).toFixed(2)}% probabilidad )</p>`;
  });
}