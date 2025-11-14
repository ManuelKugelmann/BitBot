#!/usr/bin/env node
/**
 * BitBot AI Helper - Zero-setup AI assistance for absolute beginners
 *
 * Uses free APIs that require NO authentication:
 * - HuggingFace Inference API (free tier, rate-limited but functional)
 * - Fallback to helpful error messages if rate-limited
 *
 * Usage from bash:
 *   ai-helper.js "context" "question"
 *   ai-helper.js "Docker error" "How to install Docker on Windows?"
 */

const https = require('https');

// Free HuggingFace models that work without auth (rate-limited)
const FREE_MODELS = [
  'meta-llama/Llama-3.2-3B-Instruct',
  'mistralai/Mistral-7B-Instruct-v0.3',
  'microsoft/Phi-3-mini-4k-instruct'
];

/**
 * Query HuggingFace Inference API (free tier, no auth)
 * Rate limited but works for basic help
 */
async function queryHuggingFace(prompt, modelIndex = 0) {
  const model = FREE_MODELS[modelIndex];
  const data = JSON.stringify({
    inputs: prompt,
    parameters: {
      max_new_tokens: 300,
      temperature: 0.7,
      return_full_text: false
    }
  });

  const options = {
    hostname: 'api-inference.huggingface.co',
    path: `/models/${model}`,
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': data.length
    }
  };

  return new Promise((resolve, reject) => {
    const req = https.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => body += chunk);
      res.on('end', () => {
        try {
          const response = JSON.parse(body);

          // Check for rate limit
          if (response.error) {
            if (response.error.includes('rate limit') || response.error.includes('loading')) {
              // Try next model
              if (modelIndex < FREE_MODELS.length - 1) {
                resolve(queryHuggingFace(prompt, modelIndex + 1));
              } else {
                reject(new Error('RATE_LIMIT'));
              }
            } else {
              reject(new Error(response.error));
            }
          } else if (Array.isArray(response) && response[0]?.generated_text) {
            resolve(response[0].generated_text.trim());
          } else {
            reject(new Error('Unexpected response format'));
          }
        } catch (e) {
          reject(e);
        }
      });
    });

    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

/**
 * Fallback helpful messages when AI is unavailable
 */
function getFallbackHelp(context, question) {
  const fallbacks = {
    'docker': `Docker Help:

    Windows/WSL:
    1. Download Docker Desktop: https://docker.com/products/docker-desktop
    2. Install and enable WSL integration
    3. Restart and verify: docker --version

    Linux:
    1. Install: curl -fsSL https://get.docker.com | sh
    2. Add user: sudo usermod -aG docker $USER
    3. Restart and verify: docker --version`,

    'wsl': `WSL Help:

    1. Open PowerShell as Administrator
    2. Run: wsl --install
    3. Restart your computer
    4. Set up Ubuntu username/password
    5. Verify: wsl --list --verbose`,

    'git': `Git Help:

    Windows:
    1. Download: https://git-scm.com/download/win
    2. Install with default options
    3. Verify: git --version

    Linux:
    sudo apt update && sudo apt install git`,

    'devcontainer': `DevContainer Help:

    1. Install Docker (see docker help)
    2. Install VS Code: https://code.visualstudio.com
    3. Install "Dev Containers" extension in VS Code
    4. Open folder in VS Code
    5. Press F1 → "Dev Containers: Reopen in Container"`
  };

  // Find matching fallback
  const contextLower = context.toLowerCase();
  for (const [key, help] of Object.entries(fallbacks)) {
    if (contextLower.includes(key)) {
      return help;
    }
  }

  return `For help with: ${context}

Common resources:
• Docker: https://docs.docker.com/get-started/
• WSL: https://learn.microsoft.com/en-us/windows/wsl/
• Git: https://git-scm.com/doc
• BitBot: Check README.md in your BitBot installation

Tip: Run 'bitbot help' for more options`;
}

/**
 * Main function
 */
async function main() {
  const args = process.argv.slice(2);

  if (args.length < 2) {
    console.error('Usage: ai-helper.js "context" "question"');
    console.error('Example: ai-helper.js "Docker error" "How to install Docker?"');
    process.exit(1);
  }

  const [context, question] = args;
  const prompt = `Context: ${context}\n\nQuestion: ${question}\n\nProvide a clear, concise answer for a beginner (2-3 sentences):`;

  try {
    // Try AI first
    const answer = await queryHuggingFace(prompt);
    console.log(answer);
  } catch (error) {
    // Fallback to helpful static messages
    if (error.message === 'RATE_LIMIT') {
      console.log(getFallbackHelp(context, question));
    } else {
      console.log(getFallbackHelp(context, question));
    }
  }
}

// Only run if called directly (not required as module)
if (require.main === module) {
  main().catch(err => {
    console.error('AI helper error:', err.message);
    process.exit(1);
  });
}

module.exports = { queryHuggingFace, getFallbackHelp };
