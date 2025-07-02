import express from 'express';
import { calculateTotals, createTotalsObject } from 'ccusage/calculate-cost';
import { loadDailyUsageData } from 'ccusage/data-loader';
import { spawn } from 'child_process';

const app = express();
const PORT = process.env.PORT || 3456;

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'ok', port: PORT });
});

app.get('/usage', async (req, res) => {
  try {
    // Use local timezone for date calculation to match ccusage behavior
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    const today = `${year}${month}${day}`;
    
    // Get today's usage data
    const todayData = await loadDailyUsageData({
      since: today,
      until: today,
    });
    
    // Get current month's data with explicit date range
    const currentMonth = today.slice(0, 6);
    const lastDayOfMonth = new Date(year, now.getMonth() + 1, 0).getDate();
    const monthEnd = `${currentMonth}${String(lastDayOfMonth).padStart(2, '0')}`;
    const monthData = await loadDailyUsageData({
      since: currentMonth + '01',
      until: monthEnd,
    });
    
    // Calculate today's totals
    let todayUsage = null;
    if (todayData.length > 0) {
      const todayTotals = calculateTotals(todayData);
      const todayTotalsObject = createTotalsObject(todayTotals);
      
      // Get breakdown by model for today
      const modelBreakdown = [];
      if (Array.isArray(todayTotals)) {
        todayTotals.forEach(item => {
          modelBreakdown.push({
            modelName: item.modelId,
            inputTokens: item.inputTokens || 0,
            outputTokens: item.outputTokens || 0,
            cacheCreationTokens: item.cacheCreationTokens || 0,
            cacheReadTokens: item.cacheReadTokens || 0,
            cost: item.totalCost || 0
          });
        });
      }
      
      todayUsage = {
        date: today.slice(0, 4) + '-' + today.slice(4, 6) + '-' + today.slice(6, 8),
        inputTokens: todayTotalsObject.inputTokens || 0,
        outputTokens: todayTotalsObject.outputTokens || 0,
        cacheCreationTokens: todayTotalsObject.cacheCreationTokens || 0,
        cacheReadTokens: todayTotalsObject.cacheReadTokens || 0,
        totalTokens: todayTotalsObject.totalTokens || 0,
        totalCost: todayTotalsObject.totalCost || 0,
        modelsUsed: modelBreakdown.map(m => m.modelName),
        modelBreakdowns: modelBreakdown
      };
    }
    
    // Calculate monthly totals
    const monthTotals = calculateTotals(monthData);
    const monthTotalsObject = createTotalsObject(monthTotals);
    
    res.json({
      daily: todayUsage ? [todayUsage] : [],
      totals: {
        inputTokens: monthTotalsObject.inputTokens || 0,
        outputTokens: monthTotalsObject.outputTokens || 0,
        cacheCreationTokens: monthTotalsObject.cacheCreationTokens || 0,
        cacheReadTokens: monthTotalsObject.cacheReadTokens || 0,
        totalTokens: monthTotalsObject.totalTokens || 0,
        totalCost: monthTotalsObject.totalCost || 0
      }
    });
  } catch (error) {
    console.error('Error fetching usage data:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get active block data (5-hour sessions)
app.get('/blocks/active', async (req, res) => {
  try {
    const env = process.env.CLAUDE_CONFIG_DIR ? { ...process.env } : process.env;
    const npx = spawn('npx', ['ccusage', 'blocks', '--active', '--json'], { env });
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
        res.status(500).json({ error: error || 'Failed to get blocks data' });
        return;
      }

      try {
        const data = JSON.parse(output);
        res.json(data);
      } catch (parseError) {
        res.status(500).json({ error: 'Failed to parse blocks data' });
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Get session data (conversation sessions)
app.get('/session', async (req, res) => {
  try {
    const env = process.env.CLAUDE_CONFIG_DIR ? { ...process.env } : process.env;
    const npx = spawn('npx', ['ccusage', 'session', '--json'], { env });
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
        res.status(500).json({ error: error || 'Failed to get session data' });
        return;
      }

      try {
        const data = JSON.parse(output);
        res.json(data);
      } catch (parseError) {
        res.status(500).json({ error: 'Failed to parse session data' });
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.listen(PORT, '127.0.0.1', () => {
  console.log(`Claude usage server running on http://127.0.0.1:${PORT}`);
});