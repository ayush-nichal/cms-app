const axios = require('axios');

/**
 * GET /api/version
 * Public endpoint — no auth required.
 * Proxies the GitHub Releases API to return the latest app version info.
 */
const getLatestVersion = async (req, res) => {
  const { GITHUB_TOKEN, GITHUB_OWNER, GITHUB_REPO } = process.env;

  if (!GITHUB_OWNER || !GITHUB_REPO) {
    return res.status(500).json({ error: 'GitHub owner/repo not configured on server.' });
  }

  try {
    const headers = {
      Accept: 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
    };
    if (GITHUB_TOKEN) {
      headers['Authorization'] = `Bearer ${GITHUB_TOKEN}`;
    }

    const { data } = await axios.get(
      `https://api.github.com/repos/${GITHUB_OWNER}/${GITHUB_REPO}/releases/latest`,
      { headers, timeout: 10000 }
    );

    // Strip leading "v" from tag name (e.g. "v1.0.2" → "1.0.2")
    const version = data.tag_name ? data.tag_name.replace(/^v/, '') : null;

    // Find the first .apk asset in the release
    const apkAsset = (data.assets || []).find((a) =>
      a.name.toLowerCase().endsWith('.apk')
    );

    return res.json({
      version: version || '0.0.0',
      release_notes: data.body || 'No release notes provided.',
      apk_url: apkAsset ? apkAsset.browser_download_url : null,
      force_update: false,
    });
  } catch (err) {
    console.error('Version check failed:', err.message);
    // Return a non-error response so the app doesn't crash if GitHub is down
    return res.status(200).json({
      version: '0.0.0',
      release_notes: '',
      apk_url: null,
      force_update: false,
    });
  }
};

module.exports = { getLatestVersion };
