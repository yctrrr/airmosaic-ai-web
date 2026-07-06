const revealTargets = document.querySelectorAll(
  ".content-band, .workflow-band, .metrics-strip"
);

const observer = new IntersectionObserver(
  entries => {
    for (const entry of entries) {
      if (entry.isIntersecting) {
        entry.target.classList.add("is-revealed");
        observer.unobserve(entry.target);
      }
    }
  },
  { threshold: 0.12 }
);

for (const target of revealTargets) {
  observer.observe(target);
}

const navLinks = document.querySelectorAll(".top-nav a");
for (const link of navLinks) {
  link.addEventListener("click", event => {
    const href = link.getAttribute("href");
    if (!href || !href.startsWith("#")) {
      return;
    }
    const target = document.querySelector(href);
    if (!target) {
      return;
    }
    event.preventDefault();
    const top = target.getBoundingClientRect().top + window.scrollY - 72;
    window.scrollTo({ top, behavior: "smooth" });
  });
}
