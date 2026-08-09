document.querySelectorAll('nav a').forEach(link => {
    link.addEventListener('mouseover', () => {
        link.classList.add('glitch-effect');
    });
    link.addEventListener('mouseleave', () => {
        link.classList.remove('glitch-effect');
    });
});