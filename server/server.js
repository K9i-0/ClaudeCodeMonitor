import express from 'express';
import { calculateTotals, createTotalsObject } from 'ccusage/calculate-cost';
import { loadDailyUsageData } from 'ccusage/data-loader';
import { spawn } from 'child_process';

const app = express();
const PORT = 3456;

app.get('/usage', async (req, res) => {
  try {
    const today = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    
    // Get today's usage data
    const todayData = await loadDailyUsageData({
      since: today,
    });
    
    // Get current month's data
    const currentMonth = today.slice(0, 6);
    const monthData = await loadDailyUsageData({
      since: currentMonth + '01',
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

// Get active session block data
app.get('/blocks/active', async (req, res) => {
  try {
    const npx = spawn('npx', ['ccusage', 'blocks', '--active', '--json']);
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

app.listen(PORT, '127.0.0.1', () => {
  console.log(`Claude usage server running on http://127.0.0.1:${PORT}`);
});