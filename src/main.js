/**
 * Async VDOT doxy.me Extension
 *
 * This extension embeds the Async VDOT (Video Direct Observation of Therapy)
 * application into the doxy.me provider session using the doxy.me Embed SDK.
 *
 * App URL: https://doxy-record.replit.app/
 * Developer: doxy.me Labs
 */

import { embedDoxyMe } from 'doxy.me';

const VDOT_APP_URL = 'https://doxy-record.replit.app/';

// Track embed instance
let embedInstance = null;

/**
 * Launch the Async VDOT application.
 *
 * Attempts to embed the app as an iframe. If X-Frame-Options blocks it,
 * falls back to opening in a new tab.
 */
window.launchApp = function launchApp() {
  const overlay = document.getElementById('embed-overlay');
  const container = document.getElementById('embed-container');

  // Clear any previous state
  container.innerHTML = '';
  if (embedInstance) {
    try { embedInstance.destroy(); } catch (_) {}
    embedInstance = null;
  }

  overlay.classList.add('active');

  // Try to embed via doxy.me SDK
  try {
    embedInstance = embedDoxyMe(container, {
      url: VDOT_APP_URL,
      width: '100%',
      height: '100%',
      allow: 'camera; microphone; fullscreen',
      style: { border: 'none', flex: '1' },
      trackingParams: {
        utm_source: 'doxyme',
        utm_medium: 'extension',
        utm_campaign: 'async-vdot',
      },
      onLoad: () => {
        console.log('[Async VDOT] App iframe loaded');
      },
      onError: (err) => {
        console.warn('[Async VDOT] Iframe load error — falling back to link', err);
        showFallback(container);
      },
    });

    // If we got an iframe, style it
    if (embedInstance && embedInstance.iframe) {
      embedInstance.iframe.style.flex = '1';
      embedInstance.iframe.style.height = '100%';
      container.style.display = 'flex';
      container.style.flexDirection = 'column';
      container.style.flex = '1';

      // Detect X-Frame-Options blocking
      embedInstance.iframe.addEventListener('load', () => {
        try {
          const doc = embedInstance.iframe.contentDocument;
          if (!doc || doc.body.innerHTML === '') {
            showFallback(container);
          }
        } catch (_) {
          // Cross-origin means it loaded (normal case)
          console.log('[Async VDOT] App loaded in iframe (cross-origin, expected)');
        }
      });
    }
  } catch (err) {
    console.error('[Async VDOT] embedDoxyMe failed:', err);
    showFallback(container);
  }
};

/**
 * Show fallback content if iframe is blocked.
 * Opens in new tab and shows a friendly message.
 */
function showFallback(container) {
  container.innerHTML = `
    <div class="embed-blocked">
      <div class="embed-blocked-icon">🎥</div>
      <h3>Opening Async VDOT</h3>
      <p>
        The Async VDOT application is opening in a new tab.
        Review your patient queue, check adherence rates, and manage recordings.
      </p>
      <a href="${VDOT_APP_URL}" target="_blank" rel="noopener"
         class="btn btn-primary" style="display:inline-flex;gap:7px;align-items:center">
        🚀 Open Async VDOT in New Tab
      </a>
      <p style="font-size:11px;margin-top:8px;">
        <a href="${VDOT_APP_URL}" target="_blank" rel="noopener"
           style="color:var(--vdot-muted);text-decoration:underline">
          ${VDOT_APP_URL}
        </a>
      </p>
    </div>
  `;
  // Auto-open in new tab
  window.open(VDOT_APP_URL, '_blank', 'noopener,noreferrer');
}

/**
 * Close the embed overlay.
 */
window.closeApp = function closeApp() {
  const overlay = document.getElementById('embed-overlay');
  overlay.classList.remove('active');
  if (embedInstance) {
    try { embedInstance.destroy(); } catch (_) {}
    embedInstance = null;
  }
  document.getElementById('embed-container').innerHTML = '';
};

// Handle escape key to close
document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') window.closeApp();
});

console.log('[Async VDOT doxy.me Extension] Loaded · doxy.me SDK v' +
  (typeof __DOXY_SDK_VERSION__ !== 'undefined' ? __DOXY_SDK_VERSION__ : 'unknown'));
