// Smooth scroll
// Adapted from Claude
document.querySelectorAll('a[href^="#"]').forEach(anchor => {
    anchor.addEventListener('click', function (e) {
        e.preventDefault();
        const target = document.querySelector(this.getAttribute('href'));
        if (target) {
            target.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });
        }
    });
});

// Change the active link
document.addEventListener("DOMContentLoaded", toggleActive())

function toggleActive() {
    const links = document.querySelectorAll('.floating-nav-link');
    for (let i = 0; i < links.length; i++) {
        console.log(links[i]);
        if (document.URL.includes(links[i].getAttribute("href"))) {
            links.forEach(link => {
                link.classList.remove("active");
            })
            links[i].classList.add("active");
        } 
    }
}