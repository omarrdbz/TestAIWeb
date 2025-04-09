// js/script.js

// Elementos del DOM
const imageInput = document.getElementById('imageInput');
const preview = document.getElementById('preview');
const imageUrlText = document.getElementById('imageUrl');
const predictBtn = document.getElementById('predictBtn');

// Manejar la carga de imagen
imageInput.addEventListener('change', function(event) {
  const file = event.target.files[0];
  if (file && file.type === "image/jpeg") {
    const reader = new FileReader();
    reader.onload = function(e) {
      // Mostrar la imagen en la página
      preview.src = e.target.result;
      // Mostrar la URL (data URL) de la imagen
      imageUrlText.textContent = "URL de la imagen: " + e.target.result;
    };
    reader.readAsDataURL(file);
  } else {
    alert("Por favor selecciona una imagen en formato JPG.");
  }
});

// Botón de predicción que imprime "Hola mundo!"
predictBtn.addEventListener('click', function() {
  console.log("Hola mundo!");
  alert("Hola mundo!");
});
