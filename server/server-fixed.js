import express from 'express';
import { spawn } from 'child_process';

const app = express();
const PORT = 3456;

// Helper function to run npx ccusage command
function runCcusage(args) {
  return new Promise((resolve, reject) => {
    const npx = spawn('npx', ['ccusage@latest', ...args]);
    let output = '';
    let error = '';

    npx.stdout.on('data', (data) => {
      output += data.toString();
    });

    npx.stderr.on('data', (data) => {
      error += data.toString();
    });

    npx.on('close', (code) => {
      if (code !== 0) {
        reject(new Error(error || 'Command failed'));
      } else {
        try {
          const data = JSON.parse(output);
          resolve(data);
        } catch (e) {
          reject(new Error('Failed to parse output'));
        }
      }
    });
  });
}

app.get('/usage', async (req, res) => {
  try {
    // Run npx ccusage@latest --json to get the full data
    const data = await runCcusage(['--json']);
    
    console.log('Daily count:', data.daily.length);
    if (data.daily.length > 0) {
      console.log('First daily entry:', data.daily[0]);
    }
    console.log('Monthly total cost:', data.totals.totalCost);
    
    res.json(data);
  } catch (error) {
    console.error('Error fetching usage data:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get active session block data
app.get('/blocks/active', async (req, res) => {
  try {
    const data = await runCcusage(['blocks', '--active', '--json']);
    res.json(data);
  } catch (error) {
    console.error('Error fetching blocks data:', error);
    res.status(500).json({ error: error.message });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.listen(PORT, '127.0.0.1', () => {
  console.log(`Claude usage server (fixed) running on http://127.0.0.1:${PORT}`);
});