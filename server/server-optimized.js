import express from 'express';
import { calculateTotals, createTotalsObject } from 'ccusage/calculate-cost';
import { loadDailyUsageData } from 'ccusage/data-loader';
import { spawn } from 'child_process';

const app = express();
const PORT = 3456;

// Cache for blocks data with 30-second TTL
let blocksCache = null;
let blocksCacheTime = 0;
const BLOCKS_CACHE_TTL = 30000; // 30 seconds

// Cache for daily data with 1-minute TTL
let dailyCache = null;
let dailyCacheTime = 0;
const DAILY_CACHE_TTL = 60000; // 1 minute

app.get('/usage', async (req, res) => {
  try {
    // Check cache first
    if (dailyCache && Date.now() - dailyCacheTime < DAILY_CACHE_TTL) {
      console.log('Serving from daily cache');
      res.json(dailyCache);
      return;
    }

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
      const modelBreakdown = {};
      todayTotals.forEach(item => {
        modelBreakdown[item.modelId] = {
          totalTokens: item.totalTokens,
          cachedTokens: item.cachedTokens,
          totalCost: item.totalCost
        };
      });
      
      todayUsage = {
        date: today,
        totalTokens: todayTotalsObject.totalTokens,
        cachedTokens: todayTotalsObject.cachedTokens,
        totalCost: todayTotalsObject.totalCost,
        modelBreakdown
      };
    }
    
    // Calculate monthly totals
    const monthTotals = calculateTotals(monthData);
    const monthTotalsObject = createTotalsObject(monthTotals);
    
    const response = {
      daily: todayUsage ? [todayUsage] : [],
      totals: {
        totalTokens: monthTotalsObject.totalTokens,
        cachedTokens: monthTotalsObject.cachedTokens,
        totalCost: monthTotalsObject.totalCost
      }
    };

    // Update cache
    dailyCache = response;
    dailyCacheTime = Date.now();

    res.json(response);
  } catch (error) {
    console.error('Error fetching usage data:', error);
    res.status(500).json({ error: error.message });
  }
});

// Get active session block data with caching
app.get('/blocks/active', async (req, res) => {
  try {
    // Check cache first
    if (blocksCache && Date.now() - blocksCacheTime < BLOCKS_CACHE_TTL) {
      console.log('Serving from blocks cache');
      res.json(blocksCache);
      return;
    }

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
        
        // Update cache
        blocksCache = data;
        blocksCacheTime = Date.now();
        
        res.json(data);
      } catch (parseError) {
        res.status(500).json({ error: 'Failed to parse blocks data' });
      }
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    caches: {
      blocks: blocksCache ? 'warm' : 'cold',
      daily: dailyCache ? 'warm' : 'cold'
    }
  });
});

app.listen(PORT, '127.0.0.1', () => {
  console.log(`Claude usage server (optimized) running on http://127.0.0.1:${PORT}`);
});