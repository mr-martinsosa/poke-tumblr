let closeButton = document.querySelector(".close-button")
let flashPanel = document.querySelector(".flash")

$('.carousel').carousel({
    interval: 6000
});
$('.carousel').carousel('cycle')

closeButton.addEventListener("click", event => {
  event.preventDefault()

  flashPanel.classList.add("hide")
})