import express from 'express';
import { calculateTotals, createTotalsObject } from 'ccusage/calculate-cost';
import { loadDailyUsageData } from 'ccusage/data-loader';

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
    
    res.json({
      daily: todayUsage ? [todayUsage] : [],
      totals: {
        totalTokens: monthTotalsObject.totalTokens,
        cachedTokens: monthTotalsObject.cachedTokens,
        totalCost: monthTotalsObject.totalCost
      }
    });
  } catch (error) {
    console.error('Error fetching usage data:', error);
    res.status(500).json({ error: error.message });
  }
});

app.listen(PORT, '127.0.0.1', () => {
  console.log(`Claude usage server running on http://127.0.0.1:${PORT}`);
});