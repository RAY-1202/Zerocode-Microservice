<template>
  <footer class="site-footer">
    <div class="footer-shell">
      <div>
        <span class="footer-wordmark">Zerocode</span>
        <p>从一句需求到一个可访问的网站。</p>
      </div>
      <div class="footer-meta">
        <a href="https://github.com/RAY-1202/Zerocode-Microservice" target="_blank" rel="noopener noreferrer">GitHub</a>
        <span>Built by Ray</span>
      </div>
    </div>
  </footer>
</template>

<style scoped>
.site-footer {
  padding: 0 20px 28px;
  background: var(--ink);
}

.footer-shell {
  width: min(1180px, 100%);
  margin: 0 auto;
  padding: 30px 0 10px;
  border-top: 1px solid var(--line);
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: 24px;
}

.footer-wordmark {
  font-size: clamp(2rem, 5vw, 4.5rem);
  font-weight: 800;
  letter-spacing: -0.07em;
}

p,
.footer-meta {
  color: var(--muted);
  font-size: 14px;
}

p {
  margin: 8px 0 0;
}

.footer-meta {
  display: flex;
  gap: 24px;
}

.footer-meta a {
  color: var(--paper);
}

@media (max-width: 620px) {
  .footer-shell,
  .footer-meta {
    align-items: flex-start;
    flex-direction: column;
  }
}
</style>
